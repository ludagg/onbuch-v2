import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

/// Progression de préparation par matière (section D · écran 19).
/// Données illustratives tant que le moteur de suivi n'est pas branché.
class ConcoursProgressScreen extends StatelessWidget {
  const ConcoursProgressScreen({super.key});

  static const _subjects = [
    ('Mathématiques', 72),
    ('Physique', 54),
    ('Chimie', 38),
    ('Logique / Culture', 80),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Ma progression'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          ..._subjects.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(s.$1, style: body(13.5, weight: FontWeight.w700))),
                    Text('${s.$2}%', style: mono(12.5, weight: FontWeight.w700, color: OC.o600)),
                  ]),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: s.$2 / 100,
                      minHeight: 9,
                      backgroundColor: OC.panel,
                      valueColor: const AlwaysStoppedAnimation(OC.o500),
                    ),
                  ),
                ]),
              )),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(14)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 18, color: OC.o600),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Point faible détecté : Chimie. Le Tuteur peut te proposer 3 exercices ciblés.',
                style: body(12.5, color: OC.o700, weight: FontWeight.w600).copyWith(height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
