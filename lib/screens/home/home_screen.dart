import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathOperation;
import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/annale_store.dart';
import '../../services/gamification_service.dart';
import '../../services/tutor_service.dart';
import '../../widgets/annale_actions.dart';
import '../../utils/launch.dart';
import '../../models/article.dart';
import '../../models/exam.dart';
import '../../models/home_announcement.dart';
import '../../models/affiche.dart';
import '../../models/social_link.dart';
import '../../models/annale.dart';
import '../../models/fascicule.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Change de clé pour forcer toutes les sections à se reconstruire (et donc à
  // recharger leurs données) lors d'un « tirer pour rafraîchir ».
  Key _contentKey = UniqueKey();

  Future<void> _refresh() async {
    final online = await DatabaseService.isOnline();
    DatabaseService.clearCache(); // force le rechargement (réseau, sinon disque)
    if (mounted) setState(() => _contentKey = UniqueKey());
    if (!mounted) return;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Tu es hors ligne — affichage des dernières données enregistrées.',
          style: body(13.5, color: Colors.white, weight: FontWeight.w600),
        ),
        backgroundColor: OC.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: RefreshIndicator(
        color: OC.o500,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            child: KeyedSubtree(
              key: _contentKey,
              child: Column(children: [
              const SizedBox(height: 16),
              // Greeting
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Center(child: _Greeting()),
              ),
              const SizedBox(height: 14),

              // Stats (sans conteneur — directement sur le fond)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HeaderStats(),
              ),
              const SizedBox(height: 18),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/search'),
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
                    Icon(Icons.search_rounded, size: 21, color: OC.muted),
                    const SizedBox(width: 13),
                    Expanded(child: Text('Rechercher…', style: body(15, color: OC.muted, weight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () => context.push('/tutor/capture'),
                      child: Container(
                        width: 42, height: 42, margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: OC.grad,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.34), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ),
                ),
              ),
              const SizedBox(height: 18),

              // Raccourcis rapides (juste sous la recherche)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const _QuickLinks(),
              ),
              const SizedBox(height: 22),

              // Hero — carrousel d'examens (compte à rebours résultats)
              _HeroCarousel(),
              const SizedBox(height: 18),

              // Tuteur CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const _TuteurCard(),
              ),
              const SizedBox(height: 22),

              // Nos fascicules — carrousel de couvertures qui défile en boucle
              // (directement sur la page, sans conteneur)
              const _FasciculesCarousel(),
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

              // Réseaux sociaux — rejoins-nous (icônes rondes)
              const _SocialIconsRow(),

              // Signature
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => openUrl(context, 'https://wa.me/237678438557'),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'OnBuch a été créé avec ❤️ par ',
                            style: body(12.5, color: OC.muted, weight: FontWeight.w500)),
                        TextSpan(text: 'Ludovic Aggaï',
                            style: body(12.5, color: OC.o600, weight: FontWeight.w800)
                                .copyWith(decoration: TextDecoration.underline, decorationColor: OC.o600)),
                      ]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ]),
            ),
          ),
        ],
        ),
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
  // Salutations qui tournent à chaque ouverture. Seule « Salut » porte le
  // prénom ; les autres restent courtes (sinon trop longues avec le prénom).
  static final List<String Function(String?)> _greetings = [
    (n) => n == null ? 'Salut 👋' : 'Salut, $n 👋',
    (_) => 'Le goat est de retour 🐐',
    (_) => 'Content de te revoir ✨',
    (_) => 'Prêt à tout déchirer ? 💪',
    (_) => 'De retour, boss 👑',
    (_) => 'On déchire aujourd\'hui ? 🔥',
  ];
  // Mémorise le dernier index pour éviter de répéter la même à l'ouverture suivante.
  static int _last = -1;

  static int _pick() {
    final n = _greetings.length;
    if (n <= 1) return 0;
    var i = math.Random().nextInt(n);
    if (i == _last) i = (i + 1) % n; // pas deux fois de suite la même
    _last = i;
    return i;
  }

  // Valeur initiale lue **de façon synchrone** dans le cache : si le prénom est
  // déjà connu (navigation, redémarrage à chaud), il s'affiche sans clignoter.
  String? _first = AuthService.cachedFirstName;
  // Choisie une seule fois à la création (= à chaque ouverture de l'accueil).
  late final int _idx = _pick();

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
    final name = (_first != null && _first!.isNotEmpty) ? _first : null;
    return Text(
      _greetings[_idx](name),
      textAlign: TextAlign.center,
      style: display(24, weight: FontWeight.w600),
    );
  }
}

// ─── Stats d'en-tête (XP · Rang · Examen · Crédits) — SANS conteneur ─────────
// Valeurs EN DUR pour l'instant (TODO : profil + gamification + quota Tuteur).
class _HeaderStats extends StatefulWidget {
  const _HeaderStats();

  @override
  State<_HeaderStats> createState() => _HeaderStatsState();
}

class _HeaderStatsState extends State<_HeaderStats> {
  String _examShort = '—';
  String _credits = '—';

  @override
  void initState() {
    super.initState();
    // Pointe la présence du jour (streak + bonus quotidien) puis charge les infos.
    GamificationService.instance.recordActivity();
    _loadProfile();
    _loadCredits();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return;
    final p = await DatabaseService().getUserProfile(user.$id);
    if (!mounted || p == null) return;
    final s = _shortExam((p['examen'] ?? '').toString(), (p['serie'] ?? '').toString());
    setState(() => _examShort = s);
  }

  Future<void> _loadCredits() async {
    final q = await TutorService().getQuota();
    if (mounted) setState(() => _credits = '${q.credits}');
  }

  String _shortExam(String examen, String serie) {
    const abbr = {
      'Baccalauréat': 'Bac', 'Probatoire': 'Prob', 'BEPC': 'BEPC', 'CAP': 'CAP', 'BT': 'BT',
      'BTS': 'BTS', 'HND': 'HND', 'GCE O Level': 'GCE O', 'GCE A Level': 'GCE A', 'Concours': 'Concours',
    };
    final e = abbr[examen] ?? (examen.isNotEmpty ? examen.split(' ').first : '');
    var code = '';
    final s = serie.trim();
    if (s.contains('—')) {
      code = s.split('—').first.trim();
    } else if (s.contains('-')) {
      code = s.split('-').first.trim();
    } else if (s.isNotEmpty && s.length <= 5) {
      code = s;
    }
    final out = [e, code].where((x) => x.isNotEmpty).join(' ');
    return out.isEmpty ? '—' : out;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GamificationState>(
      valueListenable: GamificationService.instance.state,
      builder: (context, g, _) {
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _stat('${g.xp}', 'XP total', OC.warn),
            _div(),
            _stat('—', 'Rang national', OC.blue),
            _div(),
            _stat(_examShort, 'Examen', const Color(0xFF7A5AE0)),
            _div(),
            // Seul « Crédits » est cliquable → page Crédits.
            _stat(_credits, 'Crédits', OC.good, onTap: () => context.push('/credits')),
          ]),
        );
      },
    );
  }

  Widget _div() => Container(width: 1, color: OC.line, margin: const EdgeInsets.symmetric(vertical: 4));

  Widget _stat(String value, String label, Color accent, {VoidCallback? onTap}) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: display(19, weight: FontWeight.w800, color: accent)),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
      );
}

// ─── Hero carousel (examens — états & compteurs) ──────────────────────────────
class _HeroCarousel extends StatefulWidget {
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _ctrl = PageController();
  int _page = 0;
  // Annonces admin (en tête) + examens, chargés ensemble.
  late final Future<List<dynamic>> _future = Future.wait([
    DatabaseService().getHomeAnnouncements(),
    DatabaseService().getExams(),
  ]);
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
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _HeroSkeleton();
        }
        final announcements =
            (snap.data?[0] as List<HomeAnnouncement>?) ?? const <HomeAnnouncement>[];
        var exams = (snap.data?[1] as List<Exam>?) ?? const <Exam>[];
        if (exams.isEmpty) exams = _sample();

        // Cartes : annonces admin en tête (position 1+), puis examens.
        final cards = <Widget>[
          for (final a in announcements) _AnnouncementCard(a),
          for (final e in exams) _HeroCard(e),
        ];

        return Column(children: [
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: cards.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: cards[i],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProgressDots(count: cards.length, active: _page.clamp(0, cards.length - 1).toInt()),
        ]);
      },
    );
  }
}

// ─── Annonce configurable (admin) — carte en tête du carrousel ────────────────
class _AnnouncementCard extends StatelessWidget {
  final HomeAnnouncement a;
  const _AnnouncementCard(this.a);

  void _open(BuildContext context) {
    final t = a.ctaTarget.trim();
    if (t.isEmpty) return;
    if (t.startsWith('/')) {
      context.go(t); // route interne
    } else {
      openUrl(context, t); // http(s), onbuch://, tel:, wa.me…
    }
  }

  @override
  Widget build(BuildContext context) {
    final light = a.isLightText;
    final fg = light ? Colors.white : OC.ink;
    final fgSoft = light ? Colors.white.withValues(alpha: 0.88) : OC.ink2;
    final base = a.bgColorValue ?? OC.darkHero;

    return GestureDetector(
      onTap: a.hasCta ? () => _open(context) : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: base,
          gradient: a.bgColorValue == null && !a.hasImage
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [OC.darkHero, OC.darkHero2],
                )
              : null,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(fit: StackFit.expand, children: [
          // Image de fond (couvrante) + repli silencieux sur le fond coloré.
          if (a.hasImage)
            CachedImage(a.imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          // Voile pour la lisibilité du texte clair sur image (haut ET bas
          // assombris ; centre plus clair pour laisser respirer l'image).
          if (a.hasImage && light)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.46),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (a.eyebrow.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: light ? Colors.white.withValues(alpha: 0.18) : OC.o600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(a.eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(9.5, weight: FontWeight.w800, color: light ? Colors.white : OC.o700)
                          .copyWith(letterSpacing: 1.1)),
                ),
                const SizedBox(height: 11),
              ],
              if (a.title.isNotEmpty)
                Text(a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: display(20.5, weight: FontWeight.w800, color: fg).copyWith(height: 1.12)),
              if (a.body.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(a.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: body(12.5, weight: FontWeight.w500, color: fgSoft).copyWith(height: 1.32)),
              ],
              const Spacer(),
              if (a.hasCta)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _open(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: light ? Colors.white : OC.ink,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 12, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(a.ctaLabel,
                            style: body(13, weight: FontWeight.w800, color: light ? OC.ink : Colors.white)),
                        const SizedBox(width: 7),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: light ? OC.ink : Colors.white),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
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
            Icon(Icons.arrow_forward_rounded, size: 16, color: OC.ink),
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
            Icon(Icons.arrow_forward_rounded, size: 15, color: OC.ink),
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
// ─── Carrousel « Nos fascicules » — couvertures qui défilent en boucle ───────
// Présenté directement sur la page (sans carte/conteneur). Les couvertures se
// suivent les unes à côté des autres et avancent en continu (boucle infinie).
class _FasciculesCarousel extends StatefulWidget {
  const _FasciculesCarousel();
  @override
  State<_FasciculesCarousel> createState() => _FasciculesCarouselState();
}

class _FasciculesCarouselState extends State<_FasciculesCarousel>
    with SingleTickerProviderStateMixin {
  static const double _coverW = 116;
  static const double _coverH = 164;
  static const double _gap = 14;
  static const double _ext = _coverW + _gap; // largeur d'un élément
  static const double _speed = 22; // pixels / seconde

  final _scroll = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  List<Fascicule> _items = const [];

  @override
  void initState() {
    super.initState();
    DatabaseService().getFascicules().then((list) {
      if (!mounted) return;
      final withPdf = list.where((f) => f.hasPdf).toList();
      setState(() => _items = withPdf);
      if (withPdf.length > 1) {
        _ticker = createTicker(_tick)..start();
      }
    });
  }

  void _tick(Duration now) {
    if (!_scroll.hasClients || _items.isEmpty) return;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.5) return; // ignore les sauts (1er frame, retour en avant-plan)
    final loop = _items.length * _ext; // longueur d'un cycle complet
    var off = _scroll.offset + _speed * dt;
    if (off >= loop) off -= loop; // bouclage transparent (le set suivant est identique)
    _scroll.jumpTo(off);
  }

  void _open(Fascicule f) {
    if (!f.hasPdf) return;
    context.push('/annales/pdf', extra: {
      'url': f.pdfUrl,
      'title': f.title,
      'subtitle': f.shelfSubtitle.isEmpty ? 'Fascicule OnBuch' : f.shelfSubtitle,
      'offlineId': 'fascicule:${f.id}',
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Petit intitulé (avec marge) ; le carrousel, lui, va bord à bord.
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          Text('Nos fascicules', style: display(18, weight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('la bibliothèque OnBuch',
              style: body(12, color: OC.muted, weight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/fascicules'),
            child: Text('Tout voir', style: body(12.5, weight: FontWeight.w800, color: OC.o600)),
          ),
        ]),
      ),
      SizedBox(
        height: _coverH,
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemExtent: _ext,
          // « infini » : on boucle sur la liste (le défilement repart au début).
          itemCount: _items.isEmpty ? 0 : _items.length * 1000,
          itemBuilder: (_, i) => _cover(_items[i % _items.length]),
        ),
      ),
    ]);
  }

  Widget _cover(Fascicule f) {
    return Padding(
      padding: const EdgeInsets.only(right: _gap),
      child: GestureDetector(
        onTap: () => _open(f),
        child: Container(
          width: _coverW,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: OC.panel,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: OC.ink.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: f.hasCover
              ? CachedImage(f.coverUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(f),
                  loadingBuilder: (c, child, p) => p == null ? child : _fallback(f))
              : _fallback(f),
        ),
      ),
    );
  }

  Widget _fallback(Fascicule f) => Container(
        color: OC.darkHero,
        padding: const EdgeInsets.all(10),
        alignment: Alignment.bottomLeft,
        child: Text(f.title,
            maxLines: 4, overflow: TextOverflow.ellipsis,
            style: display(12, weight: FontWeight.w700, color: Colors.white).copyWith(height: 1.15)),
      );
}

class _TuteurCard extends StatelessWidget {
  const _TuteurCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.o50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Column(children: [
        // ── Léo + bulle de dialogue ───────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const LeoMascot(size: 60, mood: LeoMood.wave),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OC.o100, width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LÉO · TUTEUR IA',
                    style: body(9.5, weight: FontWeight.w800, color: OC.o600).copyWith(letterSpacing: 0.1 * 9.5)),
                const SizedBox(height: 4),
                Text('Bloqué sur un exo ?', style: display(16.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Montre-le-moi en photo, je te le corrige 📸',
                    style: body(12, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.3)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // ── CTA pleine largeur ────────────────────────────────────────────
        GestureDetector(
          onTap: () => context.go('/tutor/capture'),
          child: Container(
            width: double.infinity, height: 48,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Text('Scanner un exercice', style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Raccourcis ───────────────────────────────────────────────────────────────
// ─── Raccourcis rapides (rangée d'icônes colorées sous la recherche) ─────────
class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  // [icône, libellé, action ("go:" = onglet, "push:" = écran)]. Les couleurs
  // sont résolues au build (teintes OC, mutables selon le thème) → mêmes teintes
  // que la barre de statistiques.
  static const _items = <List<Object>>[
    [Icons.menu_book_rounded, 'Cours', 'go:/cours'],
    [Icons.article_rounded, 'Annales', 'go:/annales'],
    [Icons.edit_rounded, 'Exercices', 'push:/exercices'],
    [Icons.explore_rounded, 'Orientation', 'go:/concours'],
    [Icons.camera_alt_rounded, 'Scanner', 'push:/tutor/capture'],
  ];

  void _tap(BuildContext context, String action) {
    final i = action.indexOf(':');
    final kind = action.substring(0, i);
    final route = action.substring(i + 1);
    if (kind == 'push') {
      context.push(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mêmes teintes que la barre de statistiques (OC.good/blue/warn + violet),
    // plus l'orange de marque pour le Scanner.
    final colors = <Color>[OC.good, const Color(0xFF7A5AE0), OC.blue, OC.warn, OC.o600];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_items.length, (i) {
        final it = _items[i];
        final color = colors[i % colors.length];
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _tap(context, it[2] as String),
            child: Column(children: [
              // Style « sans cadre » : grande icône colorée directement, sans
              // pastille ni ombre.
              Icon(it[0] as IconData, color: color, size: 32),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    it[1] as String,
                    maxLines: 1,
                    softWrap: false,
                    style: body(12, weight: FontWeight.w700, color: OC.ink2),
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

// ─── Saved papers (hors-ligne) ────────────────────────────────────────────────
class _SavedSection extends StatefulWidget {
  const _SavedSection();

  @override
  State<_SavedSection> createState() => _SavedSectionState();
}

class _SavedSectionState extends State<_SavedSection> {
  List<Annale> _items = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AnnaleStore.instance.offline();
    if (mounted) setState(() { _items = items; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final has = _items.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: has ? () async { await context.push('/annales/offline'); _load(); } : null,
          child: SecHead(eyebrow: 'Hors-ligne', title: 'Tes épreuves', action: has ? 'Tout voir' : null),
        ),
      ),
      const SizedBox(height: 14),
      if (!has)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/annales'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(13)),
                  child: Icon(Icons.download_for_offline_outlined, size: 24, color: OC.waInk),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_loaded ? 'Aucune épreuve hors-ligne' : 'Tes épreuves hors-ligne', style: body(14, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('Rends une épreuve dispo hors-ligne pour la consulter sans connexion, dans l\'app.',
                      style: body(12, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.35)),
                ])),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 20, color: OC.muted),
              ]),
            ),
          ),
        )
      else
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (_, i) => _offlineCard(_items[i]),
          ),
        ),
    ]);
  }

  Widget _offlineCard(Annale a) {
    return GestureDetector(
      onTap: () async { await context.push('/annales/detail', extra: a); _load(); },
      onLongPress: () => showAnnaleActions(context, a, onChanged: _load),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SubjLogo(a.subject, size: 34),
            const Spacer(),
            Icon(Icons.download_done_rounded, size: 17, color: OC.waInk),
          ]),
          const SizedBox(height: 10),
          Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13, weight: FontWeight.w700).copyWith(height: 1.2)),
          const Spacer(),
          Text([a.subject, if (a.year.isNotEmpty) a.year].join(' · '),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
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
  return CachedImage(
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
          CachedImage(a.imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: OC.panel),
              loadingBuilder: (_, c, p) => p == null ? c : Container(color: OC.panel))
        else
          Container(color: OC.panel, child: Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 48))),
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
class _CommunitySection extends StatefulWidget {
  @override
  State<_CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<_CommunitySection> {
  final Future<List<SocialLink>> _future = DatabaseService().getSocialLinks();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SocialLink>>(
      future: _future,
      builder: (context, snap) {
        final links = snap.data ?? const <SocialLink>[];
        // Lien du groupe WhatsApp (configuré par l'admin) : entrée « whatsapp ».
        final wa = links.where((s) => s.platform == 'whatsapp' && s.url.trim().isNotEmpty);
        final url = wa.isNotEmpty ? wa.first.url : '';
        if (url.isEmpty) return const SizedBox.shrink();
        return _CommunityTicket(url: url);
      },
    );
  }
}

/// Invitation « ticket VIP » doré à rejoindre la communauté WhatsApp étudiante.
class _CommunityTicket extends StatelessWidget {
  final String url;
  const _CommunityTicket({required this.url});

  static const _ink = Color(0xFF4A3A0E); // brun doré foncé (texte)
  static const _ink2 = Color(0xFF7A621E);
  static const _stub = 86.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openUrl(context, url),
      child: Container(
        // Lueur dorée derrière le ticket.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFFCDA63F).withValues(alpha: 0.38), blurRadius: 20, offset: const Offset(0, 9)),
          ],
        ),
        child: ClipPath(
          clipper: _TicketClipper(stub: _stub),
          child: Container(
            height: 108,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCEFA6), Color(0xFFEACB66), Color(0xFFCBA23A)],
              ),
            ),
            child: Stack(children: [
              // Voile clair en haut (effet « brillance »).
              Positioned(top: 0, left: 0, right: 0, height: 44,
                child: DecoratedBox(decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)]),
                ))),
              Row(children: [
                // Corps : invitation
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(children: [
                        const Icon(Icons.workspace_premium_rounded, size: 15, color: _ink2),
                        const SizedBox(width: 5),
                        Text('COMMUNAUTÉ VIP', style: body(10.5, weight: FontWeight.w800, color: _ink2)
                            .copyWith(letterSpacing: 0.13 * 10.5)),
                      ]),
                      const SizedBox(height: 7),
                      Text('Rejoins le groupe WhatsApp',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: display(16.5, weight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 3),
                      Text('Entraide, annales & bons plans entre étudiants',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: body(11.5, weight: FontWeight.w600, color: _ink2).copyWith(height: 1.25)),
                    ]),
                  ),
                ),
                // Talon : perforation + WhatsApp + « Rejoindre »
                SizedBox(
                  width: _stub,
                  child: Stack(children: [
                    Positioned(left: 0, top: 16, bottom: 16, child: _Perforation()),
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 46, height: 46,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Center(child: FaIcon(FontAwesomeIcons.whatsapp, size: 24, color: Color(0xFF25D366))),
                        ),
                        const SizedBox(height: 7),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('REJOINDRE', style: body(9.5, weight: FontWeight.w800, color: _ink)
                              .copyWith(letterSpacing: 0.06 * 9.5)),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, size: 11, color: _ink),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Ligne de perforation verticale (pointillés) du ticket.
class _Perforation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(
      9, (_) => Container(width: 2, height: 5,
        decoration: BoxDecoration(color: const Color(0xFF8A6D1E).withValues(alpha: 0.55), borderRadius: BorderRadius.circular(2))),
    ));
  }
}

/// Forme « ticket » : rectangle arrondi avec deux encoches au niveau du talon.
class _TicketClipper extends CustomClipper<Path> {
  final double stub;
  const _TicketClipper({required this.stub});

  @override
  Path getClip(Size size) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)));
    final dx = size.width - stub;
    const r = 9.0;
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(dx, 0), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(dx, size.height), radius: r));
    return Path.combine(PathOperation.difference, body, notches);
  }

  @override
  bool shouldReclip(covariant _TicketClipper oldClipper) => oldClipper.stub != stub;
}

/// Rangée compacte d'icônes de réseaux sociaux (rondes, couleur de marque) en
/// bas d'accueil — liens pilotés par l'admin (collection `social_links`).
class _SocialIconsRow extends StatefulWidget {
  const _SocialIconsRow();
  @override
  State<_SocialIconsRow> createState() => _SocialIconsRowState();
}

class _SocialIconsRowState extends State<_SocialIconsRow> {
  final Future<List<SocialLink>> _future = DatabaseService().getSocialLinks();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SocialLink>>(
      future: _future,
      builder: (context, snap) {
        final links = (snap.data ?? const <SocialLink>[])
            .where((s) => s.url.isNotEmpty)
            .toList();
        if (links.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            Text('REJOINS-NOUS',
                style: body(10.5, weight: FontWeight.w800, color: OC.muted)
                    .copyWith(letterSpacing: 0.14 * 10.5)),
            const SizedBox(height: 13),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 12,
              children: [
                for (final s in links)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => openUrl(context, s.url),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: s.color.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(child: FaIcon(s.faIcon, color: Colors.white, size: 20)),
                    ),
                  ),
              ],
            ),
          ]),
        );
      },
    );
  }
}
