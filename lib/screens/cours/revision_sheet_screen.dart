import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ── MOCK (valeurs/libellés EXACTS du wireframe — écran 8). Aucune API. ────────
const _kSheet = (title: 'Nombres complexes', sub: 'Résumé 1 page · Tle D');
const _kEssentiel = <({String label, String f})>[
  (label: 'Module', f: '|z| = √(a² + b²)'),
  (label: 'Argument', f: 'arg(z) = θ'),
  (label: 'Forme expo.', f: 'z = r · e^(iθ)'),
];
const _kErreur = 'Erreur fréquente : oublier le signe de θ selon le quadrant.';

/// Fiche de révision (résumé « 1 page ») — écran 8.
class RevisionSheetScreen extends StatelessWidget {
  const RevisionSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fiche · ${_kSheet.title}', style: display(16, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(_kSheet.sub, style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
        actions: [IconButton(icon: Icon(Icons.star_border_rounded, color: OC.ink), onPressed: () {/* TODO nav */})],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          // L'essentiel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('L\'essentiel', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              for (final e in _kEssentiel) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: const EdgeInsets.only(top: 5), width: 7, height: 7, decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.label, style: body(13, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(e.f, style: mono(14, weight: FontWeight.w600, color: OC.o700)),
                  ])),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Formules à connaître
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Formules à connaître', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              for (final _ in [0, 1, 2])
                Container(height: 10, width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(5))),
            ]),
          ),
          const SizedBox(height: 12),
          // Erreur fréquente
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: OC.warnBg, borderRadius: BorderRadius.circular(13)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.bolt_rounded, size: 18, color: OC.warn),
              const SizedBox(width: 9),
              Expanded(child: Text(_kErreur, style: body(13, weight: FontWeight.w700, color: OC.ink2))),
            ]),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: Row(children: [
          Expanded(child: _foot(Icons.picture_as_pdf_rounded, 'PDF', false)),
          const SizedBox(width: 10),
          Expanded(child: _foot(Icons.style_rounded, 'Flashcards', false)),
          const SizedBox(width: 10),
          Expanded(child: _foot(Icons.quiz_rounded, 'Quiz', true)),
        ]),
      ),
    );
  }

  Widget _foot(IconData icon, String label, bool primary) => GestureDetector(
        onTap: () {/* TODO nav */},
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: primary ? OC.grad : null,
            color: primary ? null : OC.paper,
            borderRadius: BorderRadius.circular(13),
            border: primary ? null : Border.all(color: OC.line, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: primary ? Colors.white : OC.ink),
            const SizedBox(width: 6),
            Text(label, style: body(12.5, weight: FontWeight.w700, color: primary ? Colors.white : OC.ink)),
          ]),
        ),
      );
}
