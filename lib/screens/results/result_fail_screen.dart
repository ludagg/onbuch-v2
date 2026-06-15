import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class ResultFailScreen extends StatelessWidget {
  const ResultFailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Ton résultat', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/results'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(color: Color(0xFFFBEFE4), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_border_rounded, size: 30, color: OC.warn),
          ),
          const SizedBox(height: 12),
          Text('Ce n\'est qu\'une étape', style: display(23, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Tu n\'es pas admise cette session — mais tu étais proche. On t\'aide à revenir plus forte.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Result card
          _FailResultCard(),
          const SizedBox(height: 16),

          // Tuteur CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OC.o50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OC.o100, width: 1.5),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Prépare la session 2027', style: body(14.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Un plan de révision sur tes points faibles, avec le Tuteur IA.',
                      style: body(12.5, color: OC.o700, weight: FontWeight.w500)),
                ])),
              ]),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.go('/tutor'),
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Commencer avec le Tuteur', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: OC.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OC.line, width: 1.5),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 20, color: OC.blue),
              const SizedBox(width: 11),
              Expanded(child: Text('Sessions de rattrapage & concours ouverts', style: body(13.5, weight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FailResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OBCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BACCALAURÉAT · SÉRIE D', style: body(11, weight: FontWeight.w800, color: OC.muted)
                  .copyWith(letterSpacing: 0.1 * 11)),
              const SizedBox(height: 3),
              Text('Session 2026', style: display(17, weight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFFBEFE4), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: OC.warn),
                const SizedBox(width: 6),
                Text('NON ADMIS', style: body(12, weight: FontWeight.w800, color: Color(0xFF9A5B3A))),
              ]),
            ),
          ]),
        ),
        const HRule(),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Candidat', style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('NDJAMÉ Aïcha Larissa', style: display(22, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('N° table 10428 · Centre Lycée de Bonabéri, Douala',
                style: body(12.5, color: OC.ink2, weight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Moyenne obtenue', style: body(11, weight: FontWeight.w700, color: OC.muted)),
                  const SizedBox(height: 3),
                  Text('9,40/20', style: display(19, weight: FontWeight.w700)),
                ]),
              )),
              const SizedBox(width: 10),
              Expanded(child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Admissibilité', style: body(11, weight: FontWeight.w700, color: OC.muted)),
                  const SizedBox(height: 3),
                  Text('10,00', style: display(19, weight: FontWeight.w700, color: OC.warn)),
                ]),
              )),
            ]),
          ]),
        ),
        const HRule(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(children: [
            const Icon(Icons.verified_outlined, size: 17, color: OC.o600),
            const SizedBox(width: 8),
            Text('Résultat vérifié OnBuch', style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
            const Spacer(),
            const OBWordmark(size: 14),
          ]),
        ),
      ]),
    );
  }
}
