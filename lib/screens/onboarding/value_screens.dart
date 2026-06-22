import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';

// ─── Shared value screen template ────────────────────────────────────────────
class _ValueScreen extends StatelessWidget {
  final int idx;
  final Widget vignette;
  final String eyebrow;
  final String title;
  final String titleAccent;
  final String description;
  final String nextRoute;

  const _ValueScreen({
    required this.idx,
    required this.vignette,
    required this.eyebrow,
    required this.title,
    required this.titleAccent,
    required this.description,
    required this.nextRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          // top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              const OBWordmark(size: 19),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/auth/phone'),
                child: Text('Passer', style: body(14, weight: FontWeight.w600, color: OC.muted)),
              ),
            ]),
          ),
          // vignette
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: OC.gradSoft,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: OC.o100, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: vignette,
                ),
              ),
            ),
          ),
          // copy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                eyebrow.toUpperCase(),
                style: body(12.5, weight: FontWeight.w800, color: OC.o500)
                    .copyWith(letterSpacing: 0.08 * 12.5),
              ),
              const SizedBox(height: 9),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: '$title ', style: display(27, weight: FontWeight.w700)),
                  TextSpan(text: titleAccent, style: display(27, weight: FontWeight.w700, color: OC.o500)),
                ]),
              ),
              const SizedBox(height: 10),
              Text(description, style: body(15, color: OC.ink2).copyWith(height: 1.5)),
            ]),
          ),
          // footer
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              ProgressDots(count: 3, active: idx),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go(nextRoute),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFFB347), OC.o500, OC.o600]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(idx == 2 ? 'Commencer' : 'Suivant',
                        style: body(14, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Vignette 1 — Léo + univers OnBuch (accueil engageant) ───────────────────
class _MiniWelcome extends StatelessWidget {
  const _MiniWelcome();

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      // confetti dots
      ...[
        [0.10, 0.12, OC.o500, 9.0],
        [0.85, 0.08, OC.blue, 7.0],
        [0.15, 0.80, OC.wa, 8.0],
        [0.89, 0.70, OC.o200, 10.0],
        [0.74, 0.90, OC.o500, 7.0],
        [0.06, 0.46, OC.o200, 6.0],
      ].map((p) => Positioned(
        left: (p[0] as double) * 300,
        top: (p[1] as double) * 210,
        child: Container(
          width: p[3] as double, height: p[3] as double,
          decoration: BoxDecoration(color: p[2] as Color, shape: BoxShape.circle),
        ),
      )),
      // Léo en héros + raccourcis vers l'univers OnBuch
      Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        LeoMascot(size: 118, mood: LeoMood.celebrate),
        const SizedBox(height: 20),
        Wrap(alignment: WrapAlignment.center, spacing: 9, runSpacing: 9, children: const [
          _FeaturePill(Icons.auto_awesome, 'Tuteur IA'),
          _FeaturePill(Icons.menu_book_rounded, 'Cours'),
          _FeaturePill(Icons.description_rounded, 'Annales'),
          _FeaturePill(Icons.emoji_events_rounded, 'Concours'),
        ]),
      ]),
    ]);
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OC.line, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: OC.o600),
        const SizedBox(width: 6),
        Text(label, style: body(12, weight: FontWeight.w700, color: OC.ink2)),
      ]),
    );
  }
}

// ─── Vignette 2 — Mini tutor chat ─────────────────────────────────────────────
class _MiniTutor extends StatelessWidget {
  const _MiniTutor();

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // user photo bubble
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: OC.o500,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
            ),
            boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.22), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(8),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Colors.white, Color(0xFFFFE9DC)]),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.camera_alt_outlined, color: OC.o600, size: 20),
              const SizedBox(width: 7),
              Text('Mon exercice', style: body(12, weight: FontWeight.w700, color: OC.o700)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // AI bubble
      Align(
        alignment: Alignment.centerLeft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 7),
            Text('Tuteur OnBuch', style: body(11.5, weight: FontWeight.w700, color: OC.ink2)),
          ]),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 230),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18), bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18), topLeft: Radius.circular(4),
              ),
              border: Border.all(color: OC.line, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 12)],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Étape 1 — Factoriser', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
              const SizedBox(height: 8),
              ...['100%', '88%', '64%'].map((w) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FractionallySizedBox(
                  widthFactor: double.parse(w.replaceAll('%', '')) / 100,
                  child: Container(height: 6.5, decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(4))),
                ),
              )),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Vignette 3 — Mini share ──────────────────────────────────────────────────
class _MiniShare extends StatelessWidget {
  const _MiniShare();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // stacked cards
      ...List.generate(3, (k) {
        final rev = 2 - k;
        return Positioned(
          left: 40 + rev * 20.0,
          top: 16 + rev * 14.0,
          child: Transform.rotate(
            angle: (rev - 1) * 0.07,
            child: Container(
              width: 155, height: 118,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OC.line, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(14),
              child: rev == 0 ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
                  child: Text('Annale · Bac D', style: body(10, weight: FontWeight.w800, color: OC.o600)),
                ),
                const SizedBox(height: 10),
                ...['100%', '92%', '70%'].map((w) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FractionallySizedBox(
                    widthFactor: double.parse(w.replaceAll('%', '')) / 100,
                    child: Container(height: 6, decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(3))),
                  ),
                )),
              ]) : null,
            ),
          ),
        );
      }),
      // WhatsApp tag
      Positioned(
        right: 8, bottom: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: OC.wa,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: OC.wa.withValues(alpha:0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.chat, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Partagé !', style: body(12.5, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Public screens ───────────────────────────────────────────────────────────
class Value1Screen extends StatelessWidget {
  const Value1Screen({super.key});

  @override
  Widget build(BuildContext context) => _ValueScreen(
    idx: 0,
    vignette: const _MiniWelcome(),
    eyebrow: 'Bienvenue 👋',
    title: 'Réussis ton année,',
    titleAccent: 'avec Léo 🦁',
    description: 'Cours, tuteur IA, annales et concours réunis dans une appli pensée pour toi. Pose une question, révise, progresse — Léo t\'accompagne à chaque étape, du collège à la fac.',
    nextRoute: '/onboarding/2',
  );
}

class Value2Screen extends StatelessWidget {
  const Value2Screen({super.key});

  @override
  Widget build(BuildContext context) => _ValueScreen(
    idx: 1,
    vignette: const _MiniTutor(),
    eyebrow: 'Ton moat de révision',
    title: 'Un tuteur IA',
    titleAccent: 'qui corrige et explique',
    description: 'Prends ton exercice en photo. Correction pas-à-pas en français, sur le programme MINESEC — et des exercices similaires pour t\'entraîner.',
    nextRoute: '/onboarding/3',
  );
}

class Value3Screen extends StatelessWidget {
  const Value3Screen({super.key});

  @override
  Widget build(BuildContext context) => _ValueScreen(
    idx: 2,
    vignette: const _MiniShare(),
    eyebrow: 'Toujours prêt·e',
    title: 'Annales, corrigés',
    titleAccent: '& partage en un tap',
    description: 'Des années d\'annales par examen et matière, des corrigés clairs, et le partage WhatsApp qui fait grandir ta classe avec toi.',
    nextRoute: '/auth/phone',
  );
}
