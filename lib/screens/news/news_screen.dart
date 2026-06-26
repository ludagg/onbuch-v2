import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../models/article.dart';
import '../../services/database_service.dart';

/// Page listant toutes les actualités du fil OnBuch.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final Future<List<Article>> _future = DatabaseService().getArticles(limit: 60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Actualités'),
      body: FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: List.generate(6, (_) => const SkeletonMediaRow()),
            );
          }
          final articles = snap.data ?? const <Article>[];
          if (articles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.feed_outlined, size: 46, color: OC.faint),
                  const SizedBox(height: 12),
                  Text('Aucune actualité pour le moment', style: display(18, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Le fil OnBuch s\'affichera ici.',
                      textAlign: TextAlign.center, style: body(13.5, color: OC.muted)),
                ]),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: articles.length,
            itemBuilder: (_, i) => _ArticleItem(articles[i]),
          );
        },
      ),
    );
  }
}

class _ArticleItem extends StatelessWidget {
  final Article article;
  const _ArticleItem(this.article);

  @override
  Widget build(BuildContext context) {
    final cat = categoryStyle(article.category);
    final hasImg = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/article', extra: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: SizedBox(
                width: 96,
                child: hasImg
                    ? CachedImage(article.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: cat.tint,
                            child: Center(child: Icon(Icons.article_outlined, color: cat.accent, size: 26))),
                        loadingBuilder: (_, child, p) => p == null ? child : Container(color: OC.panel))
                    : Container(color: cat.tint,
                        child: Center(child: Icon(Icons.article_outlined, color: cat.accent, size: 26))),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: cat.tint, borderRadius: BorderRadius.circular(7)),
                    child: Text(article.category.toUpperCase(),
                        style: body(9.5, weight: FontWeight.w800, color: cat.accent)),
                  ),
                  const SizedBox(height: 7),
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.25)),
                  const SizedBox(height: 5),
                  Text('${article.source} · ${timeAgo(article.publishedAt)}',
                      style: body(11, color: OC.muted, weight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
