import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Matière (programme).
class Subject {
  final String id;
  final String name;
  final String code; // initiales pour la tuile (ex. "Ma")
  final Color color;
  final int order;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    this.order = 0,
  });

  factory Subject.fromMap(Map<String, dynamic> d, {required String id}) {
    final name = (d['name'] ?? 'Matière').toString();
    final code = (d['code'] ?? '').toString().trim();
    return Subject(
      id: id,
      name: name,
      code: code.isNotEmpty ? code : _initials(name),
      color: _parseColor(d['color']) ?? OC.o500,
      order: d['order'] is int ? d['order'] as int : int.tryParse('${d['order']}') ?? 0,
    );
  }

  static String _initials(String name) {
    final n = name.trim();
    return n.isEmpty ? '?' : (n.length >= 2 ? n.substring(0, 2) : n.substring(0, 1));
  }

  static Color? _parseColor(dynamic v) {
    if (v == null) return null;
    var s = v.toString().trim().replaceAll('#', '').replaceAll('0x', '');
    if (s.length == 6) s = 'FF$s';
    final n = int.tryParse(s, radix: 16);
    return n == null ? null : Color(n);
  }
}

/// Chapitre d'une matière.
class Chapter {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? pdfUrl;
  final int order;

  const Chapter({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.videoUrl,
    this.pdfUrl,
    this.order = 0,
  });

  factory Chapter.fromMap(Map<String, dynamic> d, {required String id}) {
    String? s(dynamic v) {
      if (v == null) return null;
      final x = v.toString().trim();
      return x.isEmpty ? null : x;
    }

    return Chapter(
      id: id,
      subjectId: (d['subjectId'] ?? '').toString(),
      title: (d['title'] ?? '').toString(),
      description: s(d['description']),
      videoUrl: s(d['videoUrl']),
      pdfUrl: s(d['pdfUrl']),
      order: d['order'] is int ? d['order'] as int : int.tryParse('${d['order']}') ?? 0,
    );
  }
}
