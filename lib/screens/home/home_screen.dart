import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/appwrite_client.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/article.dart';
import '../../models/exam.dart';
import '../../models/affiche.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            actions: obTopActions(context),
          ),
          SliverToBoxAdapter(
            child: Column(children: [
              // Greeting
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Center(child: _Greeting()),
              ),
              const SizedBox(height: 16),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: OC.ink.withValues(alpha:0.05), blurRadius: 5, offset: const Offset(0, 2)),
                      BoxShadow(color: OC.ink.withValues(alpha:0.06), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(children: [
                    const SizedBox(width: 20),
                    const Icon(Icons.search_rounded, size: 21, color: OC.muted),
                    const SizedBox(width: 13),
                    Expanded(child: Text('Rechercher…', style: body(15, color: OC.muted, weight: FontWeight.w500))),
                    Container(
                      width: 42, height: 42, margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: OC.grad,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.34), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 22),

              // Hero — carrousel d'examens (compte à rebours résultats)
              _HeroCarousel(),
              const SizedBox(height: 18),

              // Tuteur CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TuteurCard(),
              ),
              const SizedBox(height: 22),

              // Raccourcis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _Shortcuts(),
              ),
              const SizedBox(height: 26),

              // Épreuves sauvegardées
              const _SavedSection(),
              const SizedBox(height: 26),

              // Actualités
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _NewsSection(),
              ),
              const SizedBox(height: 26),

              // À l'affiche
              _AfficheSection(),
              const SizedBox(height: 26),

              // Communautés
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CommunitySection(),
              ),
              const SizedBox(height: 24),

              // Appwrite ping
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await client.ping();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Appwrite connecté ✓', style: body(13, weight: FontWeight.w600, color: Colors.white)),
                            backgroundColor: OC.good,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e', style: body(13, weight: FontWeight.w600, color: Colors.white)),
                            backgroundColor: OC.bad,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.line2, width: 1.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.wifi_tethering_rounded, size: 18, color: OC.o500),
                      const SizedBox(width: 8),
                      Text('Send a ping', style: body(14, weight: FontWeight.w700, color: OC.ink)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Greeting (prénom de l'utilisateur connecté) ──────────────────────────────
class _Greeting extends StatefulWidget {
  const _Greeting();

  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting> {
  // Valeur initiale lue **de façon synchrone** dans le cache : si le prénom est
  // déjà connu (navigation, redémarrage à chaud), il s'affiche sans clignoter.
  String? _first = AuthService.cachedFirstName;

  @override
  void initState() {
    super.initState();
    if (_first == null) _load();
  }

  Future<void> _load() async {
    final user = await AuthService().getCurrentUser();
    final name = user?.name.trim() ?? '';
    final first = name.isEmpty
        ? null
        : DatabaseService.splitFullName(name)['firstName'] as String?;
    if (mounted && first != null && first != _first) {
      setState(() => _first = first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = _first;
    final text = (first == null || first.isEmpty) ? 'Bonjour 👋' : 'Bonjour, $first 👋';
    return Text(text, style: display(24, weight: FontWeight.w600));
  }
}

// ─── Hero carousel (examens — états & compteurs) ──────────────────────────────
class _HeroCarousel extends StatefulWidget {
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _ctrl = PageController();
  int _page = 0;
  late final Future<List<Exam>> _future = DatabaseService().getExams();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rafraîchit les compteurs chaque seconde.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Repli affiché tant qu'aucun examen n'est configuré côté backend
  /// (couvre les trois états pour rester démonstratif).
  static List<Exam> _sample() {
    final now = DateTime.now();
    return [
      Exam(id: 's1', label: 'Baccalauréat 2026', examDate: now.add(const Duration(days: 6, hours: 3))),
      Exam(id: 's2', label: 'Probatoire 2026',
          examDate: now.subtract(const Duration(days: 7)), resultsDate: now.add(const Duration(days: 22))),
      Exam(id: 's3', label: 'BEPC 2026', examDate: now.subtract(const Duration(days: 20)), status: 'published'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Exam>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _HeroSkeleton();
        }
        var exams = snap.data ?? const <Exam>[];
        if (exams.isEmpty) exams = _sample();
        return Column(children: [
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: exams.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _HeroCard(exams[i]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProgressDots(count: exams.length, active: _page.clamp(0, exams.length - 1).toInt()),
        ]);
      },
    );
  }
}

// Squelette de chargement du hero.
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 210,
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}

// ─── Hero card (dark editorial — état + compteur) ─────────────────────────────
class _HeroCard extends StatelessWidget {
  final Exam exam;
  const _HeroCard(this.exam);

  @override
  Widget build(BuildContext context) {
    final state = exam.state;

    late final Color dotColor;
    late final String title;
    late final String ctaLabel;
    switch (state) {
      case ExamState.upcoming:
        dotColor = OC.o500;
        title = 'Les épreuves approchent';
        ctaLabel = 'Réviser';
        break;
      case ExamState.awaiting:
        dotColor = const Color(0xFFFFB489);
        title = 'Résultats bientôt disponibles';
        ctaLabel = 'Vérifier';
        break;
      case ExamState.resultsAvailable:
        dotColor = const Color(0xFF54D38A);
        title = 'Résultats disponibles';
        ctaLabel = 'Voir mes résultats';
        break;
    }
    final ctaRoute = state == ExamState.upcoming ? '/annales' : '/results';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 1],
          colors: [OC.darkHero, OC.darkHero2],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(children: [
        // halo coloré selon l'état
        Positioned(
          top: -80, right: -60,
          child: Container(
            width: 170, height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [dotColor.withValues(alpha: 0.45), dotColor.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 2)],
            )),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                exam.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(10.5, weight: FontWeight.w800, color: const Color(0xFFFFB489))
                    .copyWith(letterSpacing: 0.12 * 10.5),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: display(19, weight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          _HeroMiddle(exam),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
            margin: const EdgeInsets.symmetric(vertical: 11),
          ),
          _HeroFooter(state: state, ctaLabel: ctaLabel, ctaRoute: ctaRoute),
        ]),
      ]),
    );
  }
}

// Zone centrale : compteur, message d'attente ou message de sortie.
class _HeroMiddle extends StatelessWidget {
  final Exam exam;
  const _HeroMiddle(this.exam);

  @override
  Widget build(BuildContext context) {
    final state = exam.state;
    final target = exam.countdownTarget;

    if (state == ExamState.resultsAvailable) {
      return Row(children: [
        const Icon(Icons.celebration_rounded, size: 20, color: Color(0xFF54D38A)),
        const SizedBox(width: 9),
        Expanded(
          child: Text('C\'est tombé ! Consulte ton résultat maintenant.',
              style: body(13, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
        ),
      ]);
    }

    if (target == null) {
      return Row(children: [
        const Icon(Icons.hourglass_bottom_rounded, size: 19, color: Color(0xFFFFB489)),
        const SizedBox(width: 9),
        Expanded(
          child: Text('Publication imminente — active l\'alerte pour être prévenu·e.',
              style: body(13, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
        ),
      ]);
    }

    final diff = target.difference(DateTime.now());
    final neg = diff.isNegative;
    String two(int x) => (neg ? 0 : x).toString().padLeft(2, '0');
    return Row(children: [
      _CountUnit(two(diff.inDays), 'jours'),
      _ColonSep(),
      _CountUnit(two(diff.inHours % 24), 'heures'),
      _ColonSep(),
      _CountUnit(two(diff.inMinutes % 60), 'min'),
      _ColonSep(),
      _CountUnit(two(diff.inSeconds % 60), 'sec'),
    ]);
  }
}

// Pied de carte : alerte + bouton d'action contextuel.
class _HeroFooter extends StatelessWidget {
  final ExamState state;
  final String ctaLabel;
  final String ctaRoute;
  const _HeroFooter({required this.state, required this.ctaLabel, required this.ctaRoute});

  @override
  Widget build(BuildContext context) {
    // Résultats sortis : bouton pleine largeur, plus engageant.
    if (state == ExamState.resultsAvailable) {
      return GestureDetector(
        onTap: () => context.go(ctaRoute),
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(ctaLabel, style: body(13, weight: FontWeight.w700, color: OC.ink)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 16, color: OC.ink),
          ]),
        ),
      );
    }

    return Row(children: [
      const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFFFFB489)),
      const SizedBox(width: 7),
      Text('Alerte activée',
          style: body(12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.86))),
      const Spacer(),
      GestureDetector(
        onTap: () => context.go(ctaRoute),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(ctaLabel, style: body(12.5, weight: FontWeight.w700, color: OC.ink)),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_forward_rounded, size: 15, color: OC.ink),
          ]),
        ),
      ),
    ]);
  }
}

class _ColonSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(':',
            style: display(20, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.22))),
      );
}

class _CountUnit extends StatelessWidget {
  final String value, unit;
  const _CountUnit(this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(children: [
        Text(value, style: mono(24, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text(unit, style: body(9.5, color: Colors.white.withValues(alpha: 0.5), weight: FontWeight.w600)
            .copyWith(letterSpacing: 0.03 * 9.5)),
      ]),
    );
  }
}

// ─── Tuteur CTA card ──────────────────────────────────────────────────────────
class _TuteurCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.o50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tuteur IA', style: display(17, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Photographie un exercice, reçois la correction', style: body(12.5, color: OC.o700, weight: FontWeight.w500)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.66,
                minHeight: 7,
                backgroundColor: OC.o100,
                valueColor: const AlwaysStoppedAnimation(OC.o500),
              ),
            ),
            const SizedBox(height: 6),
            Text('2 / 3 corrections gratuites aujourd\'hui', style: body(11, color: OC.o700, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/tutor/camera'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: OC.o500,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.28), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 7),
                Text('Scanner', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Raccourcis ───────────────────────────────────────────────────────────────
class _Shortcuts extends StatelessWidget {
  // [icône, libellé, accent, fond pastille, route (ou null si à venir)]
  static const _items = [
    [Icons.description_outlined, 'Résultats', OC.o600, OC.o50, '/results'],
    [Icons.menu_book_rounded, 'Annales', OC.waInk, OC.goodBg, '/annales'],
    [Icons.track_changes_rounded, 'Concours', OC.blue, OC.blueBg, null],
    [Icons.paid_outlined, 'Crédits', OC.warn, OC.warnBg, null],
  ];

  void _onTap(BuildContext context, String label, String? route) {
    if (route != null) {
      context.go(route);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — bientôt disponible',
            style: body(13, weight: FontWeight.w600, color: Colors.white)),
        backgroundColor: OC.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_items.length, (i) {
        final it = _items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 11 : 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onTap(context, it[1] as String, it[4] as String?),
              child: Column(children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: OC.line, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: it[3] as Color,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(it[0] as IconData, size: 23, color: it[2] as Color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(it[1] as String, style: body(12, weight: FontWeight.w700, color: OC.ink2)),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Saved papers ─────────────────────────────────────────────────────────────
class _SavedSection extends StatelessWidget {
  const _SavedSection();

  static const _papers = [
    ['Mathématiques', 'Bac D · 2023'],
    ['Philosophie', 'Probatoire A · 2024'],
    ['Physique-Chimie', 'Bac D · 2022'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SecHead(eyebrow: 'Hors-ligne', title: 'Tes épreuves', action: 'Gérer'),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _papers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 13),
          itemBuilder: (_, i) {
            final p = _papers[i];
            return Container(
              width: 156,
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  Container(
                    height: 92,
                    decoration: BoxDecoration(
                      color: OC.panel,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    ),
                    child: const Center(child: Icon(Icons.description_outlined, color: OC.faint, size: 36)),
                  ),
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.72), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('Hors-ligne', style: body(10, weight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p[0], style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.15)),
                    const SizedBox(height: 4),
                    Text(p[1], style: body(11.5, weight: FontWeight.w600, color: OC.muted)),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Actualités ───────────────────────────────────────────────────────────────
class _NewsSection extends StatefulWidget {
  @override
  State<_NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<_NewsSection> {
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService().getArticles(limit: 6);
  }

  /// Contenu de repli affiché tant qu'aucun article n'est publié côté backend.
  static List<Article> _sample() {
    final now = DateTime.now();
    return [
      Article(
        id: 's1',
        category: 'Examens',
        title: 'Calendrier officiel du Bac 2026 publié par l\'OBC',
        source: 'OnBuch',
        featured: true,
        publishedAt: now.subtract(const Duration(hours: 2)),
      ),
      Article(
        id: 's2',
        category: 'Bourses',
        title: 'Bourses d\'excellence MINESUP : candidatures ouvertes',
        source: 'OnBuch',
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      Article(
        id: 's3',
        category: 'Conseil',
        title: '5 réflexes pour réviser le jour J avec le Tuteur IA',
        source: 'OnBuch',
        publishedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/actualites'),
        child: SecHead(eyebrow: 'Le fil OnBuch', title: 'Actualités'),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _NewsSkeleton();
          }
          // En cas d'absence d'articles (collection vide ou erreur réseau),
          // on retombe sur un contenu exemple pour ne pas laisser un vide.
          var articles = snap.data ?? const <Article>[];
          if (articles.isEmpty) articles = _sample();

          final featured = articles.firstWhere(
            (a) => a.featured,
            orElse: () => articles.first,
          );
          final rest = articles.where((a) => a.id != featured.id).take(3).toList();

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _FeaturedArticle(featured),
            if (rest.isNotEmpty) const SizedBox(height: 16),
            ...rest.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ArticleRow(a),
                )),
          ]);
        },
      ),
    ]);
  }
}

Widget _articleImage(String? url, double iconSize) {
  if (url == null || url.isEmpty) {
    return Center(child: Icon(Icons.image_outlined, color: OC.faint, size: iconSize));
  }
  return Image.network(
    url,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) =>
        Center(child: Icon(Icons.image_outlined, color: OC.faint, size: iconSize)),
    loadingBuilder: (_, child, progress) =>
        progress == null ? child : Container(color: OC.panel),
  );
}

// ─── Article — carte vedette ──────────────────────────────────────────────────
class _FeaturedArticle extends StatelessWidget {
  final Article article;
  const _FeaturedArticle(this.article);

  @override
  Widget build(BuildContext context) {
    final cat = categoryStyle(article.category);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/article', extra: article),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OC.line, width: 1.5),
          color: OC.panel,
        ),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: SizedBox.expand(child: _articleImage(article.imageUrl, 48)),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF0F0A07).withValues(alpha: 0.86)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: cat.accent, borderRadius: BorderRadius.circular(8)),
                  child: Text(article.category.toUpperCase(),
                      style: body(10, weight: FontWeight.w800, color: Colors.white)
                          .copyWith(letterSpacing: 0.04 * 10)),
                ),
                const SizedBox(height: 9),
                Text(article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: display(18, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text('${article.source} · ${timeAgo(article.publishedAt)}',
                    style: body(11.5, color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w500)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Article — ligne de liste ─────────────────────────────────────────────────
class _ArticleRow extends StatelessWidget {
  final Article article;
  const _ArticleRow(this.article);

  @override
  Widget build(BuildContext context) {
    final cat = categoryStyle(article.category);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/article', extra: article),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 66, height: 66,
            color: cat.tint,
            child: article.imageUrl == null
                ? Center(child: Icon(Icons.article_outlined, color: cat.accent, size: 28))
                : _articleImage(article.imageUrl, 24),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: cat.tint, borderRadius: BorderRadius.circular(7)),
            child: Text(article.category.toUpperCase(),
                style: body(9.5, weight: FontWeight.w800, color: cat.accent)),
          ),
          const SizedBox(height: 6),
          Text(article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.25)),
          const SizedBox(height: 4),
          Text('${article.source} · ${timeAgo(article.publishedAt)}',
              style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ])),
      ]),
    );
  }
}

// ─── Article — squelette de chargement ────────────────────────────────────────
class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  Widget _bar(double w, double h) => Container(
        width: w, height: h,
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(6)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 220,
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(20)),
      ),
      const SizedBox(height: 16),
      ...List.generate(2, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 66, height: 66,
                decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _bar(60, 12),
                const SizedBox(height: 9),
                _bar(double.infinity, 12),
                const SizedBox(height: 7),
                _bar(160, 12),
              ])),
            ]),
          )),
    ]);
  }
}

// ─── À l'affiche (events + ads) ───────────────────────────────────────────────
class _AfficheSection extends StatefulWidget {
  @override
  State<_AfficheSection> createState() => _AfficheSectionState();
}

class _AfficheSectionState extends State<_AfficheSection> {
  late final Future<List<AfficheItem>> _future = DatabaseService().getAffiche(limit: 12);

  static List<AfficheItem> _sample() => const [
        AfficheItem(id: 'a1', type: 'event', title: 'Concours blanc national', subtitle: 'Sam. 28 juin · en ligne'),
        AfficheItem(id: 'a2', type: 'sponsored', title: 'Prépa ENS Yaoundé', subtitle: 'Stages intensifs · –20 %'),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/affiche'),
          child: SecHead(eyebrow: 'Événements & partenaires', title: 'À l\'affiche'),
        ),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<AfficheItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 185, child: Center(child: CircularProgressIndicator(color: OC.o500)));
          }
          var items = snap.data ?? const <AfficheItem>[];
          if (items.isEmpty) items = _sample();
          return Column(children: [
            SizedBox(
              height: 185,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 13),
                itemBuilder: (_, i) => _afficheCard(context, items[i]),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(items.length, (i) =>
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == 0 ? 18 : 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: i == 0 ? OC.o500 : OC.o100, borderRadius: BorderRadius.circular(3)),
              ),
            )),
          ]);
        },
      ),
    ]);
  }
}

Widget _afficheCard(BuildContext context, AfficheItem a) {
  final hasImg = a.imageUrl != null && a.imageUrl!.isNotEmpty;
  return GestureDetector(
    onTap: () => context.push('/affiche-detail', extra: a),
    child: Container(
      width: 270,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OC.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (hasImg)
          Image.network(a.imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: OC.panel),
              loadingBuilder: (_, c, p) => p == null ? c : Container(color: OC.panel))
        else
          Container(color: OC.panel, child: const Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 48))),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.84)]),
          ),
        ),
        Positioned(top: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: a.badgeColor, borderRadius: BorderRadius.circular(999)),
            child: Text(a.badge, style: body(9.5, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.06 * 9.5)),
          ),
        ),
        Positioned(bottom: 13, left: 14, right: 14,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: display(16.5, weight: FontWeight.w700, color: Colors.white)),
            if (a.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(a.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w500)),
            ],
          ]),
        ),
      ]),
    ),
  );
}

// ─── Community ────────────────────────────────────────────────────────────────
class _CommunitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const socials = [
      [Icons.chat_bubble_rounded, 'WhatsApp', '12k', Color(0xFF25D366)],
      [Icons.send_rounded, 'Telegram', '8k', Color(0xFF2AABEE)],
      [Icons.music_note_rounded, 'TikTok', '@onbuch', Colors.black],
      [Icons.facebook_rounded, 'Facebook', 'Page', Color(0xFF1877F2)],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SecHead(eyebrow: 'Reste connectée', title: 'La communauté', action: null),
      const SizedBox(height: 14),
      Row(
        children: List.generate(socials.length, (i) {
          final s = socials[i];
          final color = s[3] as Color;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? 11 : 0),
              child: Column(children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: OC.line, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(s[0] as IconData, color: color, size: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(s[1] as String,
                    style: body(11.5, weight: FontWeight.w700, color: OC.ink),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(s[2] as String, style: body(10, weight: FontWeight.w600, color: OC.muted)),
              ]),
            ),
          );
        }),
      ),
    ]);
  }
}
