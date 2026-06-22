/// Série / filière proposée à l'élève, rattachée à un cursus (examen).
/// Configurée côté backend (collection `exam_series`) par l'admin — elle reflète
/// la taxonomie des annales : examen → subdivision (category) → série/filière
/// (name + code) → matières (subjects). Sert de base à l'enregistrement des
/// épreuves/documents.
class ExamSeries {
  final String exam;        // cursus, ex. « Baccalauréat »
  final String? category;   // subdivision, ex. « Enseignement général (ESG) »
  final String name;        // libellé de la série/filière, ex. « D — Maths… »
  final String code;        // code éventuel de la série, ex. « D », « F2 »
  final List<String> subjects; // matières de la filière (épreuves)
  final int sortOrder;
  final bool active;

  const ExamSeries({
    required this.exam,
    required this.name,
    this.category,
    this.code = '',
    this.subjects = const [],
    this.sortOrder = 0,
    this.active = true,
  });

  factory ExamSeries.fromMap(Map<String, dynamic> m) {
    final cat = (m['category'] ?? '').toString().trim();
    final order = m['sortOrder'];
    final rawSubjects = (m['subjects'] ?? '').toString();
    return ExamSeries(
      exam: (m['exam'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      category: cat.isEmpty ? null : cat,
      code: (m['code'] ?? '').toString().trim(),
      subjects: rawSubjects
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      sortOrder: order is int ? order : int.tryParse('$order') ?? 0,
      active: m['active'] != false,
    );
  }
}
