import 'package:flutter/material.dart';

/// Type d'événement du calendrier scolaire (couleur associée).
enum CalendarEventType { rentree, composition, conge, examen, resultats, concours, info }

CalendarEventType _typeFrom(String s) {
  switch (s) {
    case 'rentree': return CalendarEventType.rentree;
    case 'composition': return CalendarEventType.composition;
    case 'conge': return CalendarEventType.conge;
    case 'examen': return CalendarEventType.examen;
    case 'resultats': return CalendarEventType.resultats;
    case 'concours': return CalendarEventType.concours;
    default: return CalendarEventType.info;
  }
}

extension CalendarEventTypeX on CalendarEventType {
  String get label {
    switch (this) {
      case CalendarEventType.rentree: return 'Rentrée';
      case CalendarEventType.composition: return 'Composition';
      case CalendarEventType.conge: return 'Congés';
      case CalendarEventType.examen: return 'Examen';
      case CalendarEventType.resultats: return 'Résultats';
      case CalendarEventType.concours: return 'Concours';
      case CalendarEventType.info: return 'Info';
    }
  }

  Color get color {
    switch (this) {
      case CalendarEventType.rentree: return const Color(0xFFE07A0C);
      case CalendarEventType.composition: return const Color(0xFF7A5AE0);
      case CalendarEventType.conge: return const Color(0xFF1E9E63);
      case CalendarEventType.examen: return const Color(0xFFD2462E);
      case CalendarEventType.resultats: return const Color(0xFF2D6CDF);
      case CalendarEventType.concours: return const Color(0xFF0E9AA0);
      case CalendarEventType.info: return const Color(0xFF978B80);
    }
  }

  IconData get icon {
    switch (this) {
      case CalendarEventType.rentree: return Icons.flag_rounded;
      case CalendarEventType.composition: return Icons.edit_note_rounded;
      case CalendarEventType.conge: return Icons.beach_access_rounded;
      case CalendarEventType.examen: return Icons.school_rounded;
      case CalendarEventType.resultats: return Icons.emoji_events_rounded;
      case CalendarEventType.concours: return Icons.track_changes_rounded;
      case CalendarEventType.info: return Icons.info_outline_rounded;
    }
  }
}

/// Événement du calendrier scolaire (repère officiel, concours, examen…).
class CalendarEvent {
  final String id;
  final String title;
  final CalendarEventType type;
  final DateTime start;
  final DateTime end; // = start si pas de fin
  final String? description;
  final String? link;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.start,
    required this.end,
    this.description,
    this.link,
  });

  /// Vrai si l'événement couvre le jour [day] (comparaison à la journée).
  bool coversDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  bool get isRange =>
      start.year != end.year || start.month != end.month || start.day != end.day;

  factory CalendarEvent.fromMap(Map<String, dynamic> data, {required String id}) {
    final start = DateTime.tryParse((data['startDate'] ?? '').toString())?.toLocal() ?? DateTime.now();
    final endRaw = data['endDate'];
    final end = endRaw == null ? start : (DateTime.tryParse(endRaw.toString())?.toLocal() ?? start);
    return CalendarEvent(
      id: id,
      title: (data['title'] ?? '').toString(),
      type: _typeFrom((data['type'] ?? 'info').toString()),
      start: start,
      end: end,
      description: _nullStr(data['description']),
      link: _nullStr(data['link']),
    );
  }

  static String? _nullStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
