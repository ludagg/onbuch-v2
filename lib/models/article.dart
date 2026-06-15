/// Article du fil OnBuch (actualités, conseils, bourses…).
class Article {
  final String id;
  final String category;
  final String title;
  final String source;
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
    this.imageUrl,
    this.body,
    this.featured = false,
  });

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
