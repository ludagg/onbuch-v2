import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/course.dart';
import '../../services/cours_packs_service.dart';

const _kOutcomes = <({IconData icon, String title, String sub, int kind})>[
  (icon: Icons.check_circle_rounded, title: 'Acquis', sub: 'Tu sautes les chapitres maîtrisés', kind: 0),
  (icon: Icons.edit_rounded, title: 'À renforcer', sub: 'On reprend là où ça coince', kind: 1),
  (icon: Icons.article_outlined, title: 'À découvrir', sub: 'Les nouveaux chapitres', kind: 2),
];

/// Test de positionnement (à l'ouverture d'un pack) — lance le moteur QCM réel.
class PlacementTestScreen extends StatelessWidget {
  final String? subjectId;
  const PlacementTestScreen({super.key, this.subjectId});

  @override
  Widget build(BuildContext context) {
    final p = CoursPacks.instance.byId(subjectId ?? '');
    final reader = '/cours/lecon?id=${subjectId ?? ''}';
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Test de niveau', style: display(16, weight: FontWeight.w700)),
          Text(p == null ? 'Pack' : 'Pack ${p.name}', style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.my_location_rounded, color: OC.o500, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quelques questions · 5 min', style: display(17, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('On repère ce que tu maîtrises déjà.', style: body(12.5, color: OC.muted, weight: FontWeight.w500)),
              ])),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Aperçu du résultat', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          for (final o in _kOutcomes) _outcome(o),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => context.push(reader),
            child: Container(height: 52, decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                alignment: Alignment.center, child: Text('Passer', style: body(14, weight: FontWeight.w700, color: OC.ink2))),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: () {
              final m = (p != null && p.modules.isNotEmpty) ? p.modules.first : null;
              if (m == null) { context.push(reader); return; }
              context.push('/cours-quiz', extra: {
                'chapter': Chapter(id: m.id, subjectId: p!.id, title: m.title),
                'subject': p.name,
              });
            },
            child: Container(height: 52, decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center, child: Text('Commencer le test', style: body(14, weight: FontWeight.w700, color: Colors.white))),
          )),
        ]),
      ),
    );
  }

  Widget _outcome(({IconData icon, String title, String sub, int kind}) o) {
    final color = switch (o.kind) { 0 => OC.good, 1 => OC.warn, _ => OC.blue };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(o.icon, color: color, size: 19)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(o.title, style: body(13.5, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(o.sub, style: body(12, color: OC.muted, weight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}
