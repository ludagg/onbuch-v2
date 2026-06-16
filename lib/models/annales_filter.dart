/// Filtre de navigation des annales, traduit en paramètres de requête pour
/// l'API `ol` (`/api/documents` et `/api/facets`).
///
/// Immuable ; utiliser [copyWith] pour dériver un filtre plus précis lors des
/// drill-downs (classe → matière → série/année).
class AnnalesFilter {
  /// Titre affiché en en-tête de l'écran de parcours (ex. « Terminale », « Baccalauréat »).
  final String label;

  final String? cycle;
  final String? schoolLevel;
  final String? subject;
  final String? examType;
  final String? series;
  final String? system;
  final int? year;
  final String? docType;
  final String? search;

  const AnnalesFilter({
    this.label = 'Annales',
    this.cycle,
    this.schoolLevel,
    this.subject,
    this.examType,
    this.series,
    this.system,
    this.year,
    this.docType,
    this.search,
  });

  AnnalesFilter copyWith({
    String? label,
    String? cycle,
    String? schoolLevel,
    String? subject,
    String? examType,
    String? series,
    String? system,
    int? year,
    String? docType,
    String? search,
    bool clearSeries = false,
    bool clearYear = false,
    bool clearSearch = false,
  }) {
    return AnnalesFilter(
      label: label ?? this.label,
      cycle: cycle ?? this.cycle,
      schoolLevel: schoolLevel ?? this.schoolLevel,
      subject: subject ?? this.subject,
      examType: examType ?? this.examType,
      series: clearSeries ? null : (series ?? this.series),
      system: system ?? this.system,
      year: clearYear ? null : (year ?? this.year),
      docType: docType ?? this.docType,
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  /// Paramètres de requête non nuls, prêts pour l'URL de l'API.
  Map<String, String> toParams() {
    final m = <String, String>{};
    void put(String k, String? v) {
      if (v != null && v.isNotEmpty) m[k] = v;
    }

    put('cycle', cycle);
    put('schoolLevel', schoolLevel);
    put('subject', subject);
    put('examType', examType);
    put('series', series);
    put('system', system);
    put('docType', docType);
    put('search', search);
    if (year != null) m['year'] = '$year';
    return m;
  }
}
