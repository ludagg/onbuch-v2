/// Modèles du module Exercices (banque d'exercices par matière/classe).

/// Chapitre d'exercices (rattaché à une matière + une classe/série), géré par
/// l'admin. Le filtrage par classe reprend la logique des matières (`Subject`).
class ExerciseChapter {
  final String id;
  final String subject; // nom de la matière (ex. « Mathématiques »)
  final String title;
  final String exam; // ex. « Baccalauréat » — vide = tous
  final String track; // série (code/libellé) — vide = toutes
  final String levels; // classes concernées (ex. « Terminale,1ère ») — vide = toutes
  final String? description;
  final int order;

  const ExerciseChapter({
    required this.id,
    required this.subject,
    required this.title,
    this.exam = '',
    this.track = '',
    this.levels = '',
    this.description,
    this.order = 0,
  });

  /// Le chapitre concerne-t-il l'examen + la série de l'élève ? (même logique
  /// souple que `Subject.appliesToClass`).
  bool appliesToClass(String? exam, String? serie) {
    final e = (exam ?? '').trim().toLowerCase();
    if (this.exam.trim().isNotEmpty && e.isNotEmpty && this.exam.trim().toLowerCase() != e) return false;
    final t = track.trim().toLowerCase();
    if (t.isEmpty) return true;
    final s = (serie ?? '').trim().toLowerCase();
    if (s.isEmpty) return true;
    if (t == s) return true;
    if (t.length <= 4 && (s.startsWith(t) || t.startsWith(s))) return true;
    return false;
  }

  factory ExerciseChapter.fromMap(Map<String, dynamic> d, {required String id}) {
    String s(dynamic v) => (v ?? '').toString();
    final ord = d['order'];
    return ExerciseChapter(
      id: id,
      subject: s(d['subject']),
      title: s(d['title']).isEmpty ? 'Chapitre' : s(d['title']),
      exam: s(d['exam']),
      track: s(d['track']),
      levels: s(d['levels']),
      description: s(d['description']).isEmpty ? null : s(d['description']),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }
}

/// Une fiche d'exercices : énoncé (PDF) + correction (PDF).
class ExerciseSheet {
  final String id;
  final String chapterId;
  final String subject;
  final String title;
  final String difficulty; // ex. « facile » / « moyen » / « difficile » — libre
  final String statementPdfUrl;
  final String? correctionPdfUrl;
  final int order;

  const ExerciseSheet({
    required this.id,
    required this.chapterId,
    required this.subject,
    required this.title,
    this.difficulty = '',
    required this.statementPdfUrl,
    this.correctionPdfUrl,
    this.order = 0,
  });

  bool get hasCorrection => (correctionPdfUrl ?? '').trim().isNotEmpty;

  factory ExerciseSheet.fromMap(Map<String, dynamic> d, {required String id}) {
    String s(dynamic v) => (v ?? '').toString();
    final ord = d['order'];
    return ExerciseSheet(
      id: id,
      chapterId: s(d['chapterId']),
      subject: s(d['subject']),
      title: s(d['title']).isEmpty ? 'Fiche d\'exercices' : s(d['title']),
      difficulty: s(d['difficulty']),
      statementPdfUrl: s(d['statementPdfUrl']),
      correctionPdfUrl: s(d['correctionPdfUrl']).isEmpty ? null : s(d['correctionPdfUrl']),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }
}

/// Statut d'une fiche pour l'élève.
enum ExerciseStatus { none, seen, found, notFound }

ExerciseStatus exerciseStatusFrom(String? s) {
  switch (s) {
    case 'found':
      return ExerciseStatus.found;
    case 'not_found':
      return ExerciseStatus.notFound;
    case 'seen':
      return ExerciseStatus.seen;
    default:
      return ExerciseStatus.none;
  }
}

String exerciseStatusKey(ExerciseStatus s) {
  switch (s) {
    case ExerciseStatus.found:
      return 'found';
    case ExerciseStatus.notFound:
      return 'not_found';
    case ExerciseStatus.seen:
      return 'seen';
    case ExerciseStatus.none:
      return '';
  }
}
