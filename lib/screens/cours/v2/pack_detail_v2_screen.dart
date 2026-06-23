import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import 'cours_models.dart';
import 'cours_ui.dart';

/// Détail d'un pack : hero, stats, progression, sommaire des chapitres.
class PackDetailV2Screen extends StatefulWidget {
  final String packId;
  const PackDetailV2Screen({super.key, required this.packId});
  @override
  State<PackDetailV2Screen> createState() => _PackDetailV2ScreenState();
}

class _PackDetailV2ScreenState extends State<PackDetailV2Screen> {
  int _tab = 0; // 0 Sommaire · 1 À propos · 2 Ressources
  static const _tabs = ['Sommaire', 'À propos', 'Ressources'];

  void _openChapter(Pack p, Chapitre c) {
    if (!c.accessible) return;
    context.push('/cours/chapitre/${p.id}/${c.id}');
  }

  void _continue(Pack p) {
    final c = p.chapitres.firstWhere((c) => c.statut == ChapStatut.enCours,
        orElse: () => p.chapitres.firstWhere((c) => c.accessible, orElse: () => p.chapitres.first));
    _openChapter(p, c);
  }

  @override
  Widget build(BuildContext context) {
    final p = packById(widget.packId);
    if (p == null) {
      return Scaffold(backgroundColor: OC.bg, appBar: AppBar(backgroundColor: OC.bg), body: Center(child: Text('Pack introuvable.', style: body(14, color: OC.muted))));
    }
    final tint = matiereTint(p.matiere);
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 168,
          backgroundColor: OC.bg,
          surfaceTintColor: Colors.transparent,
          leading: _circleBtn(Icons.arrow_back_ios_new_rounded, () => context.pop()),
          actions: [_circleBtn(Icons.ios_share_rounded, () {}), const SizedBox(width: 10)],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [tint.withValues(alpha: 0.22), tint.withValues(alpha: 0.08)]),
              ),
              alignment: Alignment.center,
              child: Icon(matiereIcon(p.matiere), size: 64, color: tint.withValues(alpha: 0.55)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (p.populaire) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('POPULAIRE', style: body(9, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.4)),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
              Text(p.titre, style: display(22, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${p.serie} · ${p.niveau}', style: body(13, color: OC.muted, weight: FontWeight.w600)),
              const SizedBox(height: 18),

              // 4 stats
              Row(children: [
                _stat(Icons.menu_book_rounded, '${p.nbLecons}', 'Leçons'),
                _stat(Icons.edit_note_rounded, '${p.nbExercices}', 'Exercices'),
                _stat(Icons.description_rounded, '${p.nbFichesOuTP}', 'Fiches'),
                _stat(Icons.assignment_turned_in_rounded, '${p.nbExamensBlancs}', 'Examens'),
              ]),
              const SizedBox(height: 18),

              // Progression
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Progression du pack', style: body(13, weight: FontWeight.w700)),
                    Text('${(p.progressionPct * 100).round()}%', style: body(14, weight: FontWeight.w800, color: OC.o700)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: p.progressionPct, minHeight: 8, backgroundColor: OC.line, valueColor: const AlwaysStoppedAnimation(OC.o500))),
                  const SizedBox(height: 9),
                  Text('Vous avez complété ${p.leconsFaites} leçons sur ${p.nbLecons}', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 14),

              // Continuer
              GestureDetector(
                onTap: () => _continue(p),
                child: Container(
                  height: 52, width: double.infinity,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 7),
                    Text('Continuer', style: body(15, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height: 22),

              // Onglets
              Row(children: List.generate(_tabs.length, (i) => _tabBtn(i))),
              const SizedBox(height: 16),
              if (_tab == 0) _sommaire(p) else if (_tab == 1) _apropos(p) else _ressources(p),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(color: OC.paper.withValues(alpha: 0.9), shape: BoxShape.circle, border: Border.all(color: OC.line, width: 1.2)),
            child: Icon(icon, size: 18, color: OC.ink),
          ),
        ),
      );

  Widget _stat(IconData icon, String n, String label) => Expanded(
        child: Column(children: [
          Icon(icon, size: 20, color: OC.o500),
          const SizedBox(height: 5),
          Text(n, style: display(17, weight: FontWeight.w700)),
          Text(label, style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
      );

  Widget _tabBtn(int i) {
    final on = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: on ? OC.o500 : OC.paper,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: on ? OC.o500 : OC.line, width: 1.5),
          ),
          child: Text(_tabs[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
        ),
      ),
    );
  }

  Widget _sommaire(Pack p) => Column(
        children: [for (final c in p.chapitres) _chapRow(p, c)],
      );

  Widget _chapRow(Pack p, Chapitre c) {
    final (icon, color, bg) = switch (c.statut) {
      ChapStatut.complete => (Icons.check_rounded, OC.good, OC.goodBg),
      ChapStatut.enCours => (Icons.play_arrow_rounded, OC.o600, OC.o50),
      ChapStatut.verrouille => (Icons.lock_outline_rounded, OC.muted, OC.panel),
    };
    final locked = c.statut == ChapStatut.verrouille;
    return GestureDetector(
      onTap: () => _openChapter(p, c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: locked ? OC.panel : OC.o50, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Text('${c.index}', style: body(13.5, weight: FontWeight.w800, color: locked ? OC.muted : OC.o600)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.titre, style: body(14, weight: FontWeight.w700, color: locked ? OC.ink2 : OC.ink)),
            if (locked) ...[
              const SizedBox(height: 2),
              Text('Termine le chapitre précédent pour débloquer', style: body(11, color: OC.muted, weight: FontWeight.w500)),
            ],
          ])),
          const SizedBox(width: 8),
          Container(width: 26, height: 26, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
        ]),
      ),
    );
  }

  Widget _apropos(Pack p) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Text(
          'Ce pack ${p.titre} suit le programme MINESEC (${p.serie}, ${p.niveau}). '
          'Il regroupe ${p.nbLecons} leçons, ${p.nbExercices} exercices corrigés, '
          '${p.nbFichesOuTP} ${p.fichesLabel.toLowerCase()} et ${p.nbExamensBlancs} examens blancs '
          'pour te préparer efficacement. Note moyenne : ${p.note}/5.',
          style: body(13.5, color: OC.ink2).copyWith(height: 1.5),
        ),
      );

  Widget _ressources(Pack p) => Column(children: [
        _resRow(Icons.description_rounded, '${p.nbFichesOuTP} ${p.fichesLabel}', 'À consulter dans chaque chapitre'),
        _resRow(Icons.assignment_turned_in_rounded, '${p.nbExamensBlancs} examens blancs', 'Sujets corrigés type Bac'),
        _resRow(Icons.edit_note_rounded, '${p.nbExercices} exercices', 'Avec correction détaillée'),
      ]);

  Widget _resRow(IconData icon, String title, String sub) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19, color: OC.o600)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
        ]),
      );
}
