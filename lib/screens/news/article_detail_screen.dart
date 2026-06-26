import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/article.dart';
import '../../utils/launch.dart';

/// Page de détail d'une actualité du fil OnBuch.
class ArticleDetailScreen extends StatelessWidget {
  final Article? article;
  const ArticleDetailScreen({super.key, this.article});

  @override
  Widget build(BuildContext context) {
    final a = article;
    if (a == null) return const _ArticleNotFound();

    final cat = categoryStyle(a.category);
    final hasImage = a.imageUrl != null && a.imageUrl!.isNotEmpty;
    final paragraphs = a.paragraphs;

    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(
        slivers: [
          // ── En-tête avec image de couverture ──────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: hasImage ? 280 : 120,
            backgroundColor: OC.darkHero,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _RoundIcon(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => _back(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundIcon(
                  icon: Icons.share_outlined,
                  onTap: () => shareArticle(context, a.title),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                if (hasImage)
                  CachedImage(
                    a.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _CoverFallback(),
                    loadingBuilder: (_, child, p) => p == null ? child : const _CoverFallback(),
                  )
                else
                  const _CoverFallback(),
                // Voile pour la lisibilité des icônes
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Colors.transparent, Color(0x33000000)],
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── Corps de l'article ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Badge catégorie
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(color: cat.tint, borderRadius: BorderRadius.circular(999)),
                  child: Text(a.category.toUpperCase(),
                      style: body(11, weight: FontWeight.w800, color: cat.accent)
                          .copyWith(letterSpacing: 0.04 * 11)),
                ),
                const SizedBox(height: 14),

                // Titre
                Text(a.title, style: display(25, weight: FontWeight.w700).copyWith(height: 1.18)),
                const SizedBox(height: 14),

                // Méta : source · date · temps de lecture
                Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      gradient: OC.grad,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.source, style: body(13, weight: FontWeight.w700, color: OC.ink)),
                      const SizedBox(height: 2),
                      Text('${timeAgo(a.publishedAt)} · ${a.readTimeMinutes} min de lecture',
                          style: body(11.5, weight: FontWeight.w500, color: OC.muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 18),
                const HRule(),
                const SizedBox(height: 18),

                // Chapô (excerpt) en exergue
                if (a.excerpt != null) ...[
                  Text(a.excerpt!,
                      style: body(15.5, weight: FontWeight.w600, color: OC.ink2).copyWith(height: 1.5)),
                  const SizedBox(height: 18),
                ],

                // Corps
                if (paragraphs.isNotEmpty)
                  ...paragraphs.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(p, style: body(15, color: OC.ink).copyWith(height: 1.62)),
                      ))
                else if (a.excerpt == null)
                  Text('Le contenu détaillé de cet article sera bientôt disponible.',
                      style: body(14.5, color: OC.muted).copyWith(height: 1.5)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

// Icône ronde semi-transparente (barre d'en-tête).
class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// Couverture par défaut quand il n'y a pas d'image.
class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OC.darkHero, OC.darkHero2],
        ),
      ),
      child: Center(
        child: Icon(Icons.article_rounded, color: Colors.white.withValues(alpha: 0.18), size: 64),
      ),
    );
  }
}

class _ArticleNotFound extends StatelessWidget {
  const _ArticleNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: OC.ink),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.article_outlined, size: 48, color: OC.faint),
            const SizedBox(height: 14),
            Text('Article introuvable', style: display(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Cet article n\'est plus disponible.',
                textAlign: TextAlign.center, style: body(14, color: OC.muted)),
          ]),
        ),
      ),
    );
  }
}
