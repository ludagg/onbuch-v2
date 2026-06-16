/// Compteurs agrégés renvoyés par `/api/facets`, utilisés pour générer
/// dynamiquement les dossiers et les filtres de la bibliothèque.

class Facet {
  final String value;
  final int count;
  const Facet(this.value, this.count);

  factory Facet.fromJson(Map<String, dynamic> j) =>
      Facet('${j['value']}', (j['count'] ?? 0) as int);
}

class FacetSet {
  final int total;
  final List<Facet> cycles;
  final List<Facet> schoolLevels;
  final List<Facet> subjects;
  final List<Facet> examTypes;
  final List<Facet> series;
  final List<Facet> docTypes;
  final List<Facet> years;

  const FacetSet({
    this.total = 0,
    this.cycles = const [],
    this.schoolLevels = const [],
    this.subjects = const [],
    this.examTypes = const [],
    this.series = const [],
    this.docTypes = const [],
    this.years = const [],
  });

  factory FacetSet.fromJson(Map<String, dynamic> j) {
    List<Facet> list(String k) =>
        ((j[k] as List?) ?? const []).map((e) => Facet.fromJson(e as Map<String, dynamic>)).toList();
    return FacetSet(
      total: (j['total'] ?? 0) as int,
      cycles: list('cycles'),
      schoolLevels: list('schoolLevels'),
      subjects: list('subjects'),
      examTypes: list('examTypes'),
      series: list('series'),
      docTypes: list('docTypes'),
      years: list('years'),
    );
  }

  static const empty = FacetSet();
}
