/// Article du fil OnBuch (actualités, conseils, bourses…).
class Article {
  final String id;
  final String category;
  final String title;
  final String source;
  final String? excerpt;
  final String? imageUrl;
  final String? body;
  final bool featured;
  final DateTime publishedAt;

  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.source,
    required this.publishedAt,
    this.excerpt,
    this.imageUrl,
    this.body,
    this.featured = false,
  });

  /// Temps de lecture estimé (minutes), à partir du corps de l'article.
  int get readTimeMinutes {
    final text = (body ?? '').trim();
    if (text.isEmpty) return 1;
    final words = text.split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 99);
  }

  /// Paragraphes du corps (séparés par des lignes vides ou des retours ligne).
  List<String> get paragraphs {
    final text = (body ?? '').trim();
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Construit un [Article] depuis un document Appwrite.
  ///
  /// [id] et [createdAtFallback] proviennent des métadonnées du document
  /// (`$id`, `$createdAt`) ; [data] est la map des attributs.
  factory Article.fromMap(
    Map<String, dynamic> data, {
    required String id,
    required String createdAtFallback,
  }) {
    final published = (data['publishedAt'] ?? createdAtFallback).toString();
    return Article(
      id: id,
      category: (data['category'] ?? 'Actu').toString(),
      title: (data['title'] ?? '').toString(),
      source: (data['source'] ?? 'OnBuch').toString(),
      excerpt: _nullableString(data['excerpt']),
      imageUrl: _nullableString(data['imageUrl']),
      body: _nullableString(data['body']),
      featured: data['featured'] == true,
      publishedAt: DateTime.tryParse(published) ?? DateTime.now(),
    );
  }

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
