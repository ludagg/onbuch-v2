/// Une bourse d'études présentée dans la page « Bourses » (Orientation).
/// Gérable par l'admin (collection `bourses`) avec repli sur une liste curée
/// embarquée (`kBourses`).
class Bourse {
  final String title;       // « Bourse du gouvernement chinois (CSC) »
  final String provider;    // organisme, ex. « Gouvernement chinois »
  final String level;       // niveaux, ex. « Licence · Master · Doctorat »
  final String destination; // pays/zone, ex. « Chine », « Cameroun »
  final String coverage;    // prise en charge, ex. « Frais + logement + allocation »
  final String deadline;    // texte libre, ex. « Mars (annuel) »
  final String description;
  final String link;        // lien officiel / candidature
  final List<String> tags;  // mots-clés (filtres rapides)
  final int order;
  final bool active;

  const Bourse({
    required this.title,
    this.provider = '',
    this.level = '',
    this.destination = '',
    this.coverage = '',
    this.deadline = '',
    this.description = '',
    this.link = '',
    this.tags = const [],
    this.order = 0,
    this.active = true,
  });

  /// Bourse pour étudier au Cameroun (vs à l'étranger) — sert de filtre.
  bool get isLocal {
    final d = destination.trim().toLowerCase();
    return d.contains('cameroun') || d.contains('local');
  }

  factory Bourse.fromMap(Map<String, dynamic> m, {String? id}) {
    String s(dynamic v) => (v ?? '').toString().trim();
    int i(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    final rawTags = s(m['tags']);
    return Bourse(
      title: s(m['title']),
      provider: s(m['provider']),
      level: s(m['level']),
      destination: s(m['destination']),
      coverage: s(m['coverage']),
      deadline: s(m['deadline']),
      description: s(m['description']),
      link: s(m['link']),
      tags: rawTags.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      order: i(m['order']),
      active: m['active'] != false,
    );
  }
}
