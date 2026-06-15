import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class TutorCorrectionScreen extends StatelessWidget {
  const TutorCorrectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Correction', style: display(17, weight: FontWeight.w700)),
          Text('Maths · 2nd degré', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/tutor'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, size: 19), color: OC.ink2, onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Column(children: [
              // User bubble (photo)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Container(
                    decoration: BoxDecoration(
                      color: OC.o500,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18), topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18), bottomRight: Radius.circular(5),
                      ),
                      boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.22), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 150, height: 78,
                        decoration: BoxDecoration(
                          color: OC.panel,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                        child: Text('Résous : x² − 5x + 6 = 0',
                            style: body(11.5, weight: FontWeight.w600, color: Colors.white)),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 13),

              // AI bubble
              Align(
                alignment: Alignment.centerLeft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 7),
                    Text('Tuteur OnBuch', style: body(12, weight: FontWeight.w700, color: OC.ink2)),
                  ]),
                  const SizedBox(height: 7),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(18), bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18), topLeft: Radius.circular(5),
                      ),
                      border: Border.all(color: OC.line, width: 1.5),
                      boxShadow: [BoxShadow(color: OC.ink.withValues(alpha:0.04), blurRadius: 6)],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Équation du second degré. On applique le discriminant Δ.',
                          style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
                      const SizedBox(height: 12),
                      // Steps
                      ...[
                        ('1', 'Calcul du discriminant', 'Δ = b² − 4ac = (−5)² − 4·1·6 = 25 − 24 = 1'),
                        ('2', 'Δ > 0 → deux solutions', 'x = (5 ± √1) / 2'),
                        ('3', 'Solutions', 'x₁ = 3   et   x₂ = 2'),
                      ].asMap().entries.map((e) {
                        final i = e.key;
                        final s = e.value;
                        return Padding(
                          padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 26, height: 26,
                              decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle),
                              child: Center(child: Text(s.$1, style: body(13, weight: FontWeight.w800, color: Colors.white))),
                            ),
                            const SizedBox(width: 11),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.$2, style: body(13, weight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                decoration: BoxDecoration(
                                  color: OC.bg,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: OC.line, width: 1.5),
                                ),
                                child: Text(s.$3, style: mono(13, color: OC.ink2)),
                              ),
                            ])),
                          ]),
                        );
                      }),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(11)),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 17, color: OC.good),
                          const SizedBox(width: 8),
                          Text('Réponse : S = { 2 ; 3 }', style: body(12.5, weight: FontWeight.w700, color: OC.waInk)),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 13),

              // Suggestions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _SuggChip('Explique l\'étape 1'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.go('/tutor/similar'),
                    child: _SuggChip('Exercices similaires'),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // Input composer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: OC.paper,
            border: Border(top: BorderSide(color: OC.line, width: 1.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: OC.line, width: 1.5)),
                child: const Icon(Icons.camera_alt_outlined, size: 20, color: OC.ink2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(999)),
                  child: Text('Pose une question…', style: body(13.5, color: OC.muted, weight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _SuggChip extends StatelessWidget {
  final String label;
  const _SuggChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: OC.paper,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: OC.line2, width: 1.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.auto_awesome_rounded, size: 14, color: OC.o600),
      const SizedBox(width: 5),
      Text(label, style: body(13, weight: FontWeight.w700, color: OC.ink2)),
    ]),
  );
}
