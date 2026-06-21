import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class TutorSimilarScreen extends StatelessWidget {
  const TutorSimilarScreen({super.key});

  static final _exercises = [
    ('x² − 7x + 12 = 0', 'Facile', OC.good, OC.goodBg),
    ('2x² + 3x − 5 = 0', 'Moyen', OC.warn, OC.warnBg),
    ('x² + 4x + 4 = 0 (racine double)', 'Difficile', OC.bad, OC.badBg),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Exercices similaires', style: display(17, weight: FontWeight.w700)),
          Text('Générés pour toi · Maths', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/tutor/correction'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OC.o50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OC.o100, width: 1.5),
            ),
            child: Row(children: [
              Icon(Icons.auto_awesome_rounded, size: 20, color: OC.o600),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '3 exercices sur les équations du 2nd degré, niveau Terminale.',
                style: body(12.5, color: OC.o700, weight: FontWeight.w600),
              )),
            ]),
          ),
          const SizedBox(height: 14),

          // Exercises
          Expanded(
            child: Column(children: _exercises.asMap().entries.map((e) {
              final i = e.key;
              final ex = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: OBCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Exercice ${i + 1}', style: body(12, weight: FontWeight.w800, color: OC.muted)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: ex.$4, borderRadius: BorderRadius.circular(999)),
                        child: Text(ex.$2, style: body(10.5, weight: FontWeight.w800, color: ex.$3)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(ex.$1, style: mono(18, weight: FontWeight.w600)),
                    const SizedBox(height: 13),
                    Row(children: [
                      Expanded(child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: OC.o50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: OC.o100, width: 1.5),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.edit_outlined, size: 16, color: OC.o600),
                          const SizedBox(width: 7),
                          Text('Composer', style: body(13, weight: FontWeight.w700, color: OC.o700)),
                        ]),
                      )),
                      const SizedBox(width: 9),
                      Expanded(child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: OC.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: OC.line2, width: 1.5),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.visibility_outlined, size: 16, color: OC.ink2),
                          const SizedBox(width: 7),
                          Text('Corrigé', style: body(13, weight: FontWeight.w700, color: OC.ink2)),
                        ]),
                      )),
                    ]),
                  ]),
                ),
              );
            }).toList()),
          ),

          // Generate more
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: OC.grad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Générer 3 autres', style: body(14, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
