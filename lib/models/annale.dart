import '../api_config.dart';

/// Une épreuve / document de la bibliothèque OnBuch.
///
/// Reflète une ligne de la table `Document` de l'API `ol`, dimensions
/// normalisées incluses (cf. src/lib/categorize.ts côté NextJS).
class Annale {
  final String id;
  final String title;
  final String author;
  final String? fileUrl;
  final String? description;

  // Dimensions normalisées (peuvent être nulles avant le backfill).
  final String? subject; // « Mathématiques », « SVT »…
  final String? schoolLevel; // « Terminale », « 3ème », « Form 1 »…
  final String? series; // « A », « C », « D », « TI »…
  final String? examType; // « Baccalauréat », « Probatoire »…
  final String? docType; // « Épreuve », « Corrigé »…
  final int? year; // 2025…
  final String? system; // « Francophone » | « Anglophone »
  final String? cycle; // « Lycée » | « Collège » | « Primaire »

  final int views;
  final int downloads;
  final double rating;

  const Annale({
    required this.id,
    required this.title,
    required this.author,
    this.fileUrl,
    this.description,
    this.subject,
    this.schoolLevel,
    this.series,
    this.examType,
    this.docType,
    this.year,
    this.system,
    this.cycle,
    this.views = 0,
    this.downloads = 0,
    this.rating = 0,
  });

  factory Annale.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    return Annale(
      id: '${j['id']}',
      title: (j['title'] ?? '').toString(),
      author: (j['author'] ?? 'Document officiel').toString(),
      fileUrl: _str(j['fileUrl']),
      description: _str(j['description']),
      subject: _str(j['subject']),
      schoolLevel: _str(j['schoolLevel']),
      series: _str(j['series']),
      examType: _str(j['examType']),
      docType: _str(j['docType']),
      year: j['year'] is int ? j['year'] as int : int.tryParse('${j['year'] ?? ''}'),
      system: _str(j['system']),
      cycle: _str(j['cycle']),
      views: asInt(j['views']),
      downloads: asInt(j['downloads']),
      rating: (j['rating'] is num) ? (j['rating'] as num).toDouble() : 0,
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ── Libellés d'affichage (les titres bruts sont longs et bruités) ──────────

  /// Matière lisible, avec repli sur « Document ».
  String get subjectLabel => subject ?? 'Document';

  /// Classe + série, ex. « Terminale C ». Vide si inconnue.
  String get classLabel {
    final parts = [schoolLevel, series].where((e) => e != null && e!.isNotEmpty);
    return parts.join(' ');
  }

  /// En-tête principal d'une carte/détail (la matière).
  String get heading => subjectLabel;

  /// Ligne de contexte « Terminale C · Baccalauréat · 2025 » (sans doublons).
  String get contextLine {
    final parts = <String>[];
    if (classLabel.isNotEmpty) parts.add(classLabel);
    if (examType != null && examType != schoolLevel) parts.add(examType!);
    if (year != null) parts.add('$year');
    return parts.join(' · ');
  }

  /// Type de document à défaut « Épreuve ».
  String get docTypeLabel => docType ?? 'Épreuve';

  bool get isCorrige => docType == 'Corrigé';

  /// URL à ouvrir dans le lecteur (le fichier direct, rapide).
  String get viewUrl => fileUrl ?? '$onbuchApiBaseUrl/api/download?documentId=$id';

  /// URL de téléchargement (proxy `ol` : suit les stats + filigrane).
  String get downloadUrl => '$onbuchApiBaseUrl/api/download?documentId=$id';

  bool get hasFile => (fileUrl != null && fileUrl!.isNotEmpty);
}

/// Page paginée de résultats renvoyée par l'API `/api/documents`.
class AnnalePage {
  final List<Annale> items;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNextPage;

  const AnnalePage({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory AnnalePage.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as List? ?? []);
    final pag = (j['pagination'] as Map?) ?? const {};
    return AnnalePage(
      items: data.map((e) => Annale.fromJson(e as Map<String, dynamic>)).toList(),
      total: (pag['total'] ?? data.length) as int,
      page: (pag['page'] ?? 1) as int,
      totalPages: (pag['totalPages'] ?? 1) as int,
      hasNextPage: (pag['hasNextPage'] ?? false) as bool,
    );
  }

  static const empty = AnnalePage(items: [], total: 0, page: 1, totalPages: 1, hasNextPage: false);
}
