import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

/// Onglet « Campus » — espace dédié à la vie scolaire.
/// Contenu à définir : pour l'instant un écran d'attente soigné.
class SchoolLifeScreen extends StatelessWidget {
  const SchoolLifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: OC.bg,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 18,
            title: const OBWordmark(size: 23),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: OBTopMenu(),
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      color: OC.o50,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: OC.o100, width: 1.5),
                    ),
                    child: const Icon(Icons.school_rounded, size: 40, color: OC.o600),
                  ),
                  const SizedBox(height: 22),
                  Text('Campus', style: display(24, weight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    'Ton espace vie scolaire arrive bientôt : actus de ton établissement, emploi du temps, clubs et entraide entre élèves.',
                    textAlign: TextAlign.center,
                    style: body(14.5, color: OC.ink2).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: OC.o50,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: OC.o100, width: 1.5),
                    ),
                    child: Text('Bientôt disponible',
                        style: body(12.5, weight: FontWeight.w700, color: OC.o700)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
