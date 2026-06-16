/// Cycle de vie d'un examen, du point de vue de l'élève.
enum ExamState {
  /// Les épreuves n'ont pas encore eu lieu.
  upcoming,

  /// Épreuves passées, résultats pas encore publiés.
  awaiting,

  /// Résultats disponibles.
  resultsAvailable,
}

/// Examen affiché dans le carrousel d'accueil (compte à rebours + état).
///
/// L'état se calcule automatiquement à partir des dates, sauf si [status]
/// force une valeur (`upcoming` / `awaiting` / `published`).
class Exam {
  final String id;
  final String label;
  final DateTime examDate;
  final DateTime? resultsDate;
  final String status; // auto | upcoming | awaiting | published
  final int order;

  const Exam({
    required this.id,
    required this.label,
    required this.examDate,
    this.resultsDate,
    this.status = 'auto',
    this.order = 0,
  });

  ExamState get state {
    switch (status) {
      case 'upcoming':
        return ExamState.upcoming;
      case 'awaiting':
        return ExamState.awaiting;
      case 'published':
        return ExamState.resultsAvailable;
    }
    // Mode automatique : déduit des dates.
    final now = DateTime.now();
    if (now.isBefore(examDate)) return ExamState.upcoming;
    if (resultsDate != null && !now.isBefore(resultsDate!)) {
      return ExamState.resultsAvailable;
    }
    return ExamState.awaiting;
  }

  /// Date cible du compte à rebours selon l'état, ou `null` si l'état n'en a
  /// pas (résultats déjà sortis, ou attente sans date de résultats connue).
  DateTime? get countdownTarget {
    switch (state) {
      case ExamState.upcoming:
        return examDate;
      case ExamState.awaiting:
        return resultsDate;
      case ExamState.resultsAvailable:
        return null;
    }
  }

  factory Exam.fromMap(
    Map<String, dynamic> data, {
    required String id,
    required String createdAtFallback,
  }) {
    final exam = (data['examDate'] ?? createdAtFallback).toString();
    final res = data['resultsDate'];
    final ord = data['order'];
    return Exam(
      id: id,
      label: (data['label'] ?? 'Examen').toString(),
      examDate: DateTime.tryParse(exam) ?? DateTime.now(),
      resultsDate: res == null ? null : DateTime.tryParse(res.toString()),
      status: (data['status'] ?? 'auto').toString(),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }
}
