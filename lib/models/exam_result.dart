/// Résultat d'examen publié (collection admin `exam_results`).
///
/// La recherche se fait par `examType` + `tableNumber` (numéro de table /
/// numéro de candidat figurant sur la convocation).
class ExamResult {
  final String id;
  final String examType; // ex. 'Baccalauréat', 'BEPC', 'GCE O Level'
  final String? serie; // ex. 'D' (séries) — optionnel
  final String year; // ex. '2026'
  final String tableNumber; // clé de recherche
  final String candidateName;
  final String? center; // centre d'examen
  final String? city;
  final bool admitted;
  final String? mention; // ex. 'Bien' (si admis)
  final String? average; // ex. '14,25/20'
  final String? threshold; // moyenne d'admissibilité (cas non admis)

  const ExamResult({
    required this.id,
    required this.examType,
    required this.year,
    required this.tableNumber,
    required this.candidateName,
    required this.admitted,
    this.serie,
    this.center,
    this.city,
    this.mention,
    this.average,
    this.threshold,
  });

  /// 'Baccalauréat · Série D'
  String get examLine =>
      [examType, if (serie != null && serie!.trim().isNotEmpty) 'Série $serie']
          .join(' · ');

  /// 'Session 2026'
  String get sessionLine => 'Session $year';

  /// 'N° table 10428 · Centre Lycée…, Douala'
  String get candidateMeta {
    final loc = [
      if (center != null && center!.trim().isNotEmpty) 'Centre $center',
      if (city != null && city!.trim().isNotEmpty) city,
    ].join(', ');
    return ['N° table $tableNumber', if (loc.isNotEmpty) loc].join(' · ');
  }

  factory ExamResult.fromMap(Map<String, dynamic> data, {required String id}) {
    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final admitted = data['admitted'] == true ||
        data['admitted'].toString().toLowerCase() == 'true' ||
        data['admitted'].toString() == '1';

    return ExamResult(
      id: id,
      examType: (data['examType'] ?? '').toString().trim(),
      serie: s(data['serie']),
      year: (data['year'] ?? '').toString().trim(),
      tableNumber: (data['tableNumber'] ?? '').toString().trim(),
      candidateName: (data['candidateName'] ?? '').toString().trim(),
      center: s(data['center']),
      city: s(data['city']),
      admitted: admitted,
      mention: s(data['mention']),
      average: s(data['average']),
      threshold: s(data['threshold']),
    );
  }
}
