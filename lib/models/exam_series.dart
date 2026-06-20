/// Série / filière proposée à l'élève, rattachée à un cursus (examen).
/// Configurée côté backend (collection `exam_series`) par l'admin.
class ExamSeries {
  final String exam;        // cursus, ex. « Baccalauréat »
  final String? category;   // regroupement, ex. « Enseignement général »
  final String name;        // libellé affiché ET stocké, ex. « C — Maths… »
  final int sortOrder;
  final bool active;

  const ExamSeries({
    required this.exam,
    required this.name,
    this.category,
    this.sortOrder = 0,
    this.active = true,
  });

  factory ExamSeries.fromMap(Map<String, dynamic> m) {
    final cat = (m['category'] ?? '').toString().trim();
    final order = m['sortOrder'];
    return ExamSeries(
      exam: (m['exam'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      category: cat.isEmpty ? null : cat,
      sortOrder: order is int ? order : int.tryParse('$order') ?? 0,
      active: m['active'] != false,
    );
  }
}
