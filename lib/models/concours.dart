/// Un concours (entrée grande école, fonction publique…) géré par l'admin.
class Concours {
  final String id;
  final String name;
  final String organizer;
  final String? description;
  final String? communique; // lien vers le communiqué officiel
  final String? link; // lien inscription / infos
  final DateTime? registrationDeadline;
  final DateTime? examDate;
  final bool resultsAvailable;
  final String? resultsLink;
  final DateTime? resultsDate;
  final String? audience;
  final String? debouches; // métiers / débouchés (saisis par l'admin)
  final int order;

  const Concours({
    required this.id,
    required this.name,
    required this.organizer,
    this.description,
    this.communique,
    this.link,
    this.registrationDeadline,
    this.examDate,
    this.resultsAvailable = false,
    this.resultsLink,
    this.resultsDate,
    this.audience,
    this.debouches,
    this.order = 0,
  });

  /// Prochaine date pertinente (inscription puis épreuves), pour le compte à rebours.
  DateTime? get nextDate {
    final now = DateTime.now();
    if (registrationDeadline != null && registrationDeadline!.isAfter(now)) {
      return registrationDeadline;
    }
    if (examDate != null && examDate!.isAfter(now)) return examDate;
    return examDate ?? registrationDeadline;
  }

  factory Concours.fromMap(Map<String, dynamic> d, {required String id}) {
    DateTime? dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    final ord = d['order'];
    return Concours(
      id: id,
      name: (d['name'] ?? 'Concours').toString(),
      organizer: (d['organizer'] ?? '').toString(),
      description: _s(d['description']),
      communique: _s(d['communique']),
      link: _s(d['link']),
      registrationDeadline: dt(d['registrationDeadline']),
      examDate: dt(d['examDate']),
      resultsAvailable: d['resultsAvailable'] == true,
      resultsLink: _s(d['resultsLink']),
      resultsDate: dt(d['resultsDate']),
      audience: _s(d['audience']),
      debouches: _s(d['debouches']),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
