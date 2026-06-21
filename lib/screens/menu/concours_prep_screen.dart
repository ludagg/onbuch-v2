import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/concours.dart';

/// Hub de préparation à un concours (section D des wireframes) : compte à
/// rebours, niveau de préparation et plan d'entraînement.
class ConcoursPrepScreen extends StatelessWidget {
  final Concours? concours;
  const ConcoursPrepScreen({super.key, this.concours});

  Concours? get c => concours;

  @override
  Widget build(BuildContext context) {
    final exam = c?.examDate;
    final days = exam == null ? null : exam.difference(DateTime.now()).inDays;
    final sub = days != null && days >= 0 ? 'J-$days avant les écrits' : 'Entraîne-toi à ton rythme';

    final plan = <(IconData, String, String, VoidCallback)>[
      (Icons.description_outlined, 'Annales du concours', '4/6', () => context.go('/annales')),
      (Icons.bolt_rounded, 'Sujets types (IA)', 'Nouv.', () => context.go('/tutor')),
      (Icons.play_circle_outline_rounded, 'Méthodo & pièges', '2/5', () => context.go('/cours')),
      (Icons.insights_rounded, 'Ma progression', '', () => context.push('/concours-progress')),
      (Icons.edit_note_rounded, 'Concours blanc', 'V2.1', () => context.push('/concours-blanc', extra: c)),
    ];

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/concours'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c == null ? 'Préparation' : 'Préparer', style: display(16, weight: FontWeight.w700)),
          Text(sub, style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          // Niveau de préparation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              SizedBox(
                width: 64, height: 64,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 64, height: 64,
                    child: CircularProgressIndicator(
                      value: 0.58, strokeWidth: 6,
                      backgroundColor: OC.line2,
                      valueColor: const AlwaysStoppedAnimation(OC.o500),
                    ),
                  ),
                  Text('58%', style: display(15, weight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Niveau de préparation', style: body(14, weight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('Continue : 6 sujets restants', style: body(12, color: OC.ink2, weight: FontWeight.w500)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          Text('Ton plan', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 12),
          ...plan.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: p.$4,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: OC.line, width: 1.5),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
                        child: Icon(p.$1, size: 20, color: OC.o600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.$2, style: body(13.5, weight: FontWeight.w700))),
                      if (p.$3.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
                          child: Text(p.$3, style: body(10.5, weight: FontWeight.w800, color: OC.o700)),
                        ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
                    ]),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Lancer un sujet type', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => context.go('/tutor'),
            ),
          ),
        ],
      ),
    );
  }

}
