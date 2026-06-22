import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ── MOCK (valeurs/libellés EXACTS du wireframe — écran 6). Aucune API. ────────
const _kLesson = (title: 'Forme exponentielle', pack: 'Pack Maths Tle D', pos: '3/38');
const _kRetenir = 'À retenir : |z| = module, arg(z) = angle.';
const _kTabs = ['Cours', 'Fiche', 'Exemples', 'Quiz'];

/// Lecteur de leçon (à l'intérieur d'un pack) — écran 6.
class LessonReaderScreen extends StatefulWidget {
  const LessonReaderScreen({super.key});

  @override
  State<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends State<LessonReaderScreen> {
  int _tab = 0; // onglet actif (état visuel local)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_kLesson.title, style: display(16, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${_kLesson.pack} · ${_kLesson.pos}', style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
        actions: [IconButton(icon: Icon(Icons.star_border_rounded, color: OC.ink), onPressed: () {/* TODO nav */})],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          // Zone vidéo
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                Text('Vidéo de la leçon', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          // Onglets
          Row(children: List.generate(_kTabs.length, (i) {
            final active = _tab == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? OC.ink : OC.paper,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: active ? OC.ink : OC.line, width: 1.5),
                  ),
                  child: Text(_kTabs[i], style: body(12.5, weight: FontWeight.w700, color: active ? Colors.white : OC.ink2)),
                ),
              ),
            );
          })),
          const SizedBox(height: 16),
          _tabContent(context),
        ],
      ),
      bottomSheet: _footer(context),
    );
  }

  Widget _tabContent(BuildContext context) {
    switch (_tab) {
      case 1: // Fiche
        return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fiche de révision', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Le résumé condensé « 1 page » de ce chapitre.', style: body(13, color: OC.ink2).copyWith(height: 1.45)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/cours/fiche'),
            child: Container(
              height: 46,
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text('Ouvrir la fiche', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]));
      case 2: // Exemples
        return Column(children: [
          _example('Exemple 1', 'Écris z sous forme exponentielle, puis déduis-en son module et son argument.'),
          _example('Exemple 2', 'Applique la formule de Moivre au calcul d\'une puissance n-ième.'),
        ]);
      case 3: // Quiz
        return _card(Column(children: [
          Icon(Icons.quiz_rounded, size: 36, color: OC.o500),
          const SizedBox(height: 10),
          Text('Quiz de la leçon', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('5 questions pour vérifier que c\'est acquis.', textAlign: TextAlign.center, style: body(12.5, color: OC.muted)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {/* TODO nav */},
            child: Container(
              height: 46, width: double.infinity,
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text('Lancer le quiz', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]));
      default: // Cours
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final _ in [0, 1, 2, 3])
            Container(height: 11, width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(6))),
          Container(height: 11, width: 180, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(6))),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(13), border: Border.all(color: OC.o100, width: 1.5)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.star_rounded, size: 18, color: OC.o500),
              const SizedBox(width: 9),
              Expanded(child: Text(_kRetenir, style: body(13, weight: FontWeight.w700, color: OC.o700))),
            ]),
          ),
        ]);
    }
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: child,
      );

  Widget _example(String tag, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tag, style: body(11, weight: FontWeight.w800, color: OC.o600)),
          const SizedBox(height: 6),
          Text(text, style: body(13, color: OC.ink2).copyWith(height: 1.4)),
        ]),
      );

  Widget _footer(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: Row(children: [
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Leçon disponible hors-ligne ✓', style: body(13, weight: FontWeight.w600, color: Colors.white)),
              backgroundColor: OC.good, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )),
            child: Container(
              height: 50, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: OC.line, width: 1.5)),
              child: Row(children: [
                Icon(Icons.download_rounded, size: 17, color: OC.ink),
                const SizedBox(width: 6),
                Text('Hors-ligne', style: body(12.5, weight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () {/* TODO nav */},
            child: Container(
              height: 50,
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Text('Leçon suivante →', style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ),
          )),
        ]),
      );
}
