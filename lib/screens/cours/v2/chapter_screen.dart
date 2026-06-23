import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/rich_answer.dart';
import 'cours_models.dart';
import 'cours_ui.dart';

/// Chapitre avec onglets internes : Cours · Résumé · Exercices · Fiche PDF.
class ChapterScreen extends StatefulWidget {
  final String packId;
  final String chapterId;
  const ChapterScreen({super.key, required this.packId, required this.chapterId});
  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  int _tab = 0;
  int _exFilter = 1; // 0 Tous · 1 Non faits · 2 Corrigés
  bool _bookmarked = false;
  static const _tabs = ['Cours', 'Résumé', 'Exercices', 'Fiche PDF'];

  @override
  Widget build(BuildContext context) {
    final p = packById(widget.packId);
    final c = p?.chapitres.where((x) => x.id == widget.chapterId).firstOrNull;
    if (p == null || c == null) {
      return Scaffold(backgroundColor: OC.bg, appBar: AppBar(backgroundColor: OC.bg), body: Center(child: Text('Chapitre introuvable.', style: body(14, color: OC.muted))));
    }
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(_bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _bookmarked ? OC.o600 : OC.ink),
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
          ),
        ],
      ),
      body: Column(children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chapitre ${c.index}', style: body(12, weight: FontWeight.w700, color: OC.o600).copyWith(letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(c.titre, style: display(22, weight: FontWeight.w700)),
          ]),
        ),
        // Onglets internes
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [for (var i = 0; i < _tabs.length; i++) _tabBtn(i)],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _body(p, c)),
      ]),
    );
  }

  Widget _tabBtn(int i) {
    final on = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: on ? OC.ink : OC.paper,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: on ? OC.ink : OC.line, width: 1.5),
          ),
          child: Text(_tabs[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
        ),
      ),
    );
  }

  Widget _body(Pack p, Chapitre c) {
    switch (_tab) {
      case 1: return _resume(c);
      case 2: return _exercices(c);
      case 3: return _fiche(c);
      default: return _cours(p, c);
    }
  }

  // ── Cours ──
  Widget _cours(Pack p, Chapitre c) {
    final idx = p.chapitres.indexOf(c);
    final prev = idx > 0 ? p.chapitres[idx - 1] : null;
    final next = idx < p.chapitres.length - 1 ? p.chapitres[idx + 1] : null;
    return Column(children: [
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [RichAnswer(c.cours)],
      )),
      Container(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: Row(children: [
          Expanded(child: _navBtn('‹ Chapitre précédent', prev != null, () {
            if (prev != null && prev.accessible) context.pushReplacement('/cours/chapitre/${p.id}/${prev.id}');
          })),
          const SizedBox(width: 10),
          Expanded(child: _navBtn('Chapitre suivant ›', next != null && next.accessible, () {
            if (next != null && next.accessible) context.pushReplacement('/cours/chapitre/${p.id}/${next.id}');
          }, primary: true)),
        ]),
      ),
    ]);
  }

  Widget _navBtn(String label, bool enabled, VoidCallback onTap, {bool primary = false}) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: primary && enabled ? OC.grad : null,
              color: primary && enabled ? null : OC.paper,
              borderRadius: BorderRadius.circular(13),
              border: primary && enabled ? null : Border.all(color: OC.line, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(label, style: body(12.5, weight: FontWeight.w700, color: primary && enabled ? Colors.white : OC.ink2)),
          ),
        ),
      );

  // ── Résumé ──
  Widget _resume(Chapitre c) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (c.pointsCles.isNotEmpty) ...[
            Text('Points clés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final pt in c.pointsCles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(margin: const EdgeInsets.only(top: 6), width: 7, height: 7, decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle)),
                      const SizedBox(width: 11),
                      Expanded(child: RichAnswer(pt)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
          ],
          if (c.formules.isNotEmpty) ...[
            Text('Formules importantes', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 10),
            for (final f in c.formules) FormulaCard(f),
            const SizedBox(height: 12),
          ],
          if (c.aRetenir.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.o100, width: 1.5)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lightbulb_rounded, size: 18, color: OC.o500),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('À retenir', style: body(12.5, weight: FontWeight.w800, color: OC.o700)),
                  const SizedBox(height: 4),
                  Text(c.aRetenir, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
                ])),
              ]),
            ),
        ],
      );

  // ── Exercices ──
  Widget _exercices(Chapitre c) {
    final filtered = c.exercices.where((e) {
      if (_exFilter == 1) return e.statut == 'non_fait' || e.verrouille;
      if (_exFilter == 2) return e.statut == 'corrige';
      return true;
    }).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _seg('Tous', 0),
            _seg('Non faits', 1),
            _seg('Corrigés', 2),
          ]),
        ),
      ),
      Expanded(child: filtered.isEmpty
          ? Center(child: Text('Aucun exercice ici.', style: body(13, color: OC.muted)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [for (final e in filtered) _exRow(e)],
            )),
    ]);
  }

  Widget _seg(String label, int i) {
    final on = _exFilter == i;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _exFilter = i),
      child: Container(
        height: 34,
        decoration: BoxDecoration(color: on ? OC.paper : Colors.transparent, borderRadius: BorderRadius.circular(9),
            boxShadow: on ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null),
        alignment: Alignment.center,
        child: Text(label, style: body(12.5, weight: FontWeight.w700, color: on ? OC.ink : OC.muted)),
      ),
    ));
  }

  Widget _exRow(Exercice e) {
    if (e.verrouille) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: OC.muted),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.libelle, style: body(13.5, weight: FontWeight.w700, color: OC.ink2)),
            const SizedBox(height: 2),
            Text(e.lockMsg ?? 'Verrouillé', style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
        ]),
      );
    }
    final corrige = e.statut == 'corrige';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.libelle, style: body(11.5, weight: FontWeight.w800, color: OC.o600)),
          const SizedBox(height: 6),
          Row(children: [
            Text('Calculer  ', style: body(13.5, color: OC.ink, weight: FontWeight.w600)),
            Flexible(child: InlineMath(e.enonce, size: 15)),
          ]),
        ])),
        const SizedBox(width: 8),
        if (corrige) Icon(Icons.check_circle_rounded, color: OC.good, size: 20)
        else Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: OC.line2, width: 2))),
      ]),
    );
  }

  // ── Fiche PDF ──
  Widget _fiche(Chapitre c) {
    final hasPdf = (c.fichePdfUrl ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(children: [
        Expanded(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.picture_as_pdf_rounded, size: 44, color: hasPdf ? OC.o500 : OC.faint),
            const SizedBox(height: 10),
            Text(hasPdf ? 'Fiche du chapitre' : 'Fiche bientôt disponible',
                style: body(13.5, weight: FontWeight.w700, color: OC.ink2)),
            const SizedBox(height: 4),
            Text(hasPdf ? 'Aperçu de la fiche PDF' : 'La fiche PDF de ce chapitre sera ajoutée.',
                style: body(12, color: OC.muted), textAlign: TextAlign.center),
          ]),
        )),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: hasPdf ? () => context.push('/annales/pdf', extra: {'url': c.fichePdfUrl, 'title': c.titre, 'subtitle': 'Fiche du chapitre'}) : null,
          child: Opacity(
            opacity: hasPdf ? 1 : 0.45,
            child: Container(
              height: 50, width: double.infinity,
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.download_rounded, color: Colors.white, size: 19),
                const SizedBox(width: 7),
                Text('Télécharger la fiche', style: body(14, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
