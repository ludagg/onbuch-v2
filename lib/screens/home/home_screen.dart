import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/appwrite_client.dart';
import '../../services/database_service.dart';
import '../../models/article.dart';

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
            actions: [
              Stack(alignment: Alignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 23),
                  color: OC.ink,
                  onPressed: () {},
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: OC.o500,
                      shape: BoxShape.circle,
                      border: Border.all(color: OC.bg, width: 1.5),
                    ),
                  ),
                ),
              ]),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: OC.line2, width: 1.5),
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 22, color: OC.ink),
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: OBTopMenu(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Center(child: Text('Bonjour, Aïcha 👋', style: display(24, weight: FontWeight.w600))),
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

// ─── Examen à venir (compte à rebours) ────────────────────────────────────────
class _ExamCountdown {
  final String label;
  final DateTime date;
  const _ExamCountdown(this.label, this.date);
}

// ─── Hero carousel (plusieurs examens) ────────────────────────────────────────
class _HeroCarousel extends StatefulWidget {
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _ctrl = PageController();
  int _page = 0;

  static final _exams = [
    _ExamCountdown('Baccalauréat 2026', DateTime(2026, 6, 18, 10)),
    _ExamCountdown('Probatoire 2026', DateTime(2026, 6, 22, 10)),
    _ExamCountdown('BEPC 2026', DateTime(2026, 7, 1, 10)),
    _ExamCountdown('GCE O/A Level 2026', DateTime(2026, 7, 8, 10)),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 210,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: _exams.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _HeroCard(_exams[i]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ProgressDots(count: _exams.length, active: _page),
    ]);
  }
}

// ─── Hero card (dark editorial — compacte) ────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final _ExamCountdown exam;
  const _HeroCard(this.exam);

  @override
  Widget build(BuildContext context) {
    final diff = exam.date.difference(DateTime.now());
    final available = diff.isNegative;
    final days = available ? 0 : diff.inDays;
    final hours = available ? 0 : diff.inHours % 24;
    final mins = available ? 0 : diff.inMinutes % 60;
    String two(int v) => v.toString().padLeft(2, '0');

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
        // glow blob
        Positioned(
          top: -80, right: -60,
          child: Container(
            width: 170, height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [OC.o500.withValues(alpha: 0.50), OC.o500.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(
              color: OC.o500,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.22), blurRadius: 6, spreadRadius: 2)],
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
          Text(
            available ? 'Résultats disponibles' : 'Résultats bientôt disponibles',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: display(19, weight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          // Countdown
          Row(children: [
            _CountUnit(two(days), 'jours'),
            _ColonSep(),
            _CountUnit(two(hours), 'heures'),
            _ColonSep(),
            _CountUnit(two(mins), 'min'),
          ]),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
            margin: const EdgeInsets.symmetric(vertical: 11),
          ),
          Row(children: [
            const Icon(Icons.notifications_outlined, size: 16, color: Color(0xFFFFB489)),
            const SizedBox(width: 7),
            Text('Alerte activée',
                style: body(12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.86))),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/results'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                child: Row(children: [
                  Text('Vérifier', style: body(12.5, weight: FontWeight.w700, color: OC.ink)),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: OC.ink),
                ]),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

class _ColonSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(':',
            style: display(24, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.22))),
      );
}

class _CountUnit extends StatelessWidget {
  final String value, unit;
  const _CountUnit(this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(children: [
        Text(value, style: mono(26, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 5),
        Text(unit, style: body(10, color: Colors.white.withValues(alpha: 0.5), weight: FontWeight.w600)
            .copyWith(letterSpacing: 0.04 * 10)),
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
      SecHead(eyebrow: 'Le fil OnBuch', title: 'Actualités'),
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

// Couleurs (accent + teinte) associées à une catégorie d'article.
class _CatStyle {
  final Color accent, tint;
  const _CatStyle(this.accent, this.tint);
}

_CatStyle _catStyle(String category) {
  switch (category.toLowerCase()) {
    case 'examens':
      return const _CatStyle(OC.o600, OC.o50);
    case 'bourses':
      return const _CatStyle(OC.blue, OC.blueBg);
    case 'conseil':
      return const _CatStyle(OC.waInk, OC.goodBg);
    case 'concours':
      return const _CatStyle(OC.blue, OC.blueBg);
    case 'alerte':
      return const _CatStyle(OC.bad, OC.badBg);
    default:
      return const _CatStyle(OC.o600, OC.o50);
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  if (diff.inDays < 35) return 'il y a ${(diff.inDays / 7).floor()} sem';
  return 'il y a ${(diff.inDays / 30).floor()} mois';
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
    final cat = _catStyle(article.category);
    return Container(
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
              Text('${article.source} · ${_timeAgo(article.publishedAt)}',
                  style: body(11.5, color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Article — ligne de liste ─────────────────────────────────────────────────
class _ArticleRow extends StatelessWidget {
  final Article article;
  const _ArticleRow(this.article);

  @override
  Widget build(BuildContext context) {
    final cat = _catStyle(article.category);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        Text('${article.source} · ${_timeAgo(article.publishedAt)}',
            style: body(11, color: OC.muted, weight: FontWeight.w500)),
      ])),
    ]);
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
class _AfficheSection extends StatelessWidget {
  const _AfficheSection();

  @override
  Widget build(BuildContext context) {
    const items = [
      ['ÉVÉNEMENT', OC.o500, 'Concours blanc national', 'Sam. 28 juin · en ligne'],
      ['SPONSORISÉ', Color(0xFF3A3346), 'Prépa ENS Yaoundé', 'Stages intensifs · –20 %'],
    ];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SecHead(eyebrow: 'Événements & partenaires', title: 'À l\'affiche', action: null),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 185,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 13),
          itemBuilder: (_, i) {
            final it = items[i];
            return Container(
              width: 270,
              decoration: BoxDecoration(
                color: OC.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(19), child: Container(
                  color: OC.panel,
                  child: const Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 48)),
                )),
                Positioned(top: 0, left: 0, right: 0, bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha:0.84)]),
                    ),
                  ),
                ),
                Positioned(top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: it[1] as Color, borderRadius: BorderRadius.circular(999)),
                    child: Text(it[0] as String, style: body(9.5, weight: FontWeight.w800, color: Colors.white)
                        .copyWith(letterSpacing: 0.06 * 9.5)),
                  ),
                ),
                Positioned(bottom: 13, left: 14, right: 14,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it[2] as String, style: display(16.5, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(it[3] as String, style: body(11.5, color: Colors.white.withValues(alpha:0.8), weight: FontWeight.w500)),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: i == 0 ? 18 : 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == 0 ? OC.o500 : OC.o100,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      )),
    ]);
  }
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
