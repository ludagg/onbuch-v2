import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Matière (programme).
class Subject {
  final String id;
  final String name;
  final String code; // initiales pour la tuile (ex. "Ma")
  final Color color;
  final String levels; // classes concernées (ex. "Terminale,1ère"), vide = toutes
  final int order;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    this.levels = '',
    this.order = 0,
  });

  /// Icône représentative de la matière (déduite du nom) — plus parlante que
  /// les initiales sur les tuiles.
  IconData get icon {
    final n = name.toLowerCase();
    if (n.contains('math')) return Icons.calculate_rounded;
    if (n.contains('phys') || n.contains('chim')) return Icons.science_rounded;
    if (n.contains('svt') || n.contains('vie') || n.contains('bio') || n.contains('nature')) return Icons.biotech_rounded;
    if (n.contains('philo')) return Icons.psychology_rounded;
    if (n.contains('franç') || n.contains('france') || n.contains('lettre')) return Icons.menu_book_rounded;
    if (n.contains('angl') || n.contains('espagnol') || n.contains('allemand') || n.contains('langue')) return Icons.translate_rounded;
    if (n.contains('hist') || n.contains('géo') || n.contains('geo')) return Icons.public_rounded;
    if (n.contains('info') || n.contains('numér') || n.contains('numer')) return Icons.computer_rounded;
    if (n.contains('éco') || n.contains('eco') || n.contains('gestion') || n.contains('compta')) return Icons.trending_up_rounded;
    if (n.contains('sport') || n.contains('eps')) return Icons.fitness_center_rounded;
    return Icons.auto_stories_rounded;
  }

  /// Vrai si la matière concerne la [classe] de l'élève (ou s'applique à toutes).
  bool appliesTo(String? classe) {
    if (levels.trim().isEmpty || classe == null || classe.trim().isEmpty) return true;
    final c = classe.toLowerCase();
    return levels.toLowerCase().split(RegExp(r'[,;]')).map((e) => e.trim()).any((l) => l.isNotEmpty && c.contains(l));
  }

  factory Subject.fromMap(Map<String, dynamic> d, {required String id}) {
    final name = (d['name'] ?? 'Matière').toString();
    final code = (d['code'] ?? '').toString().trim();
    return Subject(
      id: id,
      name: name,
      code: code.isNotEmpty ? code : _initials(name),
      color: _parseColor(d['color']) ?? OC.o500,
      levels: (d['levels'] ?? '').toString(),
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
