import 'package:flutter/material.dart';

/// Matière d'un cours / d'une fiche de révision.
///
/// Sur le modèle de [CalendarEventType] : un enum stable + une extension
/// donnant `label`, `color`, `bg`, `abbr` et la clé [tileKey] compatible avec
/// le widget `SubjTile` (réutilisation des mêmes teintes que partout ailleurs).
enum CourseSubject { maths, pc, svt, francais, philo, anglais, histgeo }

CourseSubject _subjectFrom(String s) {
  switch (s.trim().toLowerCase()) {
    case 'maths': return CourseSubject.maths;
    case 'pc': return CourseSubject.pc;
    case 'svt': return CourseSubject.svt;
    case 'francais': return CourseSubject.francais;
    case 'philo': return CourseSubject.philo;
    case 'anglais': return CourseSubject.anglais;
    case 'histgeo': return CourseSubject.histgeo;
    default: return CourseSubject.maths;
  }
}

extension CourseSubjectX on CourseSubject {
  /// Clé stockée en base (`subject`).
  String get key {
    switch (this) {
      case CourseSubject.maths: return 'maths';
      case CourseSubject.pc: return 'pc';
      case CourseSubject.svt: return 'svt';
      case CourseSubject.francais: return 'francais';
      case CourseSubject.philo: return 'philo';
      case CourseSubject.anglais: return 'anglais';
      case CourseSubject.histgeo: return 'histgeo';
    }
  }

  String get label {
    switch (this) {
      case CourseSubject.maths: return 'Mathématiques';
      case CourseSubject.pc: return 'Physique-Chimie';
      case CourseSubject.svt: return 'SVT';
      case CourseSubject.francais: return 'Français';
      case CourseSubject.philo: return 'Philosophie';
      case CourseSubject.anglais: return 'Anglais';
      case CourseSubject.histgeo: return 'Histoire-Géo';
    }
  }

  /// Libellé compris par `SubjTile` (réutilise sa palette d'initiales colorées).
  String get tileKey {
    switch (this) {
      case CourseSubject.maths: return 'Maths';
      case CourseSubject.pc: return 'Phys-Chimie';
      case CourseSubject.svt: return 'SVT';
      case CourseSubject.francais: return 'Français';
      case CourseSubject.philo: return 'Philo';
      case CourseSubject.anglais: return 'Anglais';
      case CourseSubject.histgeo: return 'Hist-Géo';
    }
  }

  /// Couleur d'accent (alignée sur `SubjTile._map`).
  Color get color {
    switch (this) {
      case CourseSubject.maths: return const Color(0xFF2D6CDF);
      case CourseSubject.pc: return const Color(0xFF1E9E63);
      case CourseSubject.svt: return const Color(0xFF0E9AA0);
      case CourseSubject.francais: return const Color(0xFFDB4F12);
      case CourseSubject.philo: return const Color(0xFF7A5AE0);
      case CourseSubject.anglais: return const Color(0xFFC0392B);
      case CourseSubject.histgeo: return const Color(0xFFA6651E);
    }
  }

  /// Teinte de fond claire (alignée sur `SubjTile._map`).
  Color get bg {
    switch (this) {
      case CourseSubject.maths: return const Color(0xFFE7EEFB);
      case CourseSubject.pc: return const Color(0xFFE5F3EB);
      case CourseSubject.svt: return const Color(0xFFE1F2F2);
      case CourseSubject.francais: return const Color(0xFFFDEBE2);
      case CourseSubject.philo: return const Color(0xFFEEE9FA);
      case CourseSubject.anglais: return const Color(0xFFFAE7E4);
      case CourseSubject.histgeo: return const Color(0xFFF6ECDC);
    }
  }
}

/// Cours ou fiche de révision rattaché à une matière.
///
/// Un seul type pour les deux : l'attribut [kind] (`cours` | `fiche`) fait
/// office de discriminant, comme `category` pour les articles. Le corps [body]
/// utilise la même syntaxe Markdown/LaTeX/`onbuch-plot` que le Tuteur et se rend
/// via `RichAnswer`.
class Course {
  final String id;
  final String title;
  final CourseSubject subject;
  final String kind; // 'cours' | 'fiche'
  final String? body;
  final String? summary;
  final String? classe;
  final String? serie;
  final String? examen;
  final int order;
  final String? chapter;
  final bool premium;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.title,
    required this.subject,
    required this.createdAt,
    this.kind = 'cours',
    this.body,
    this.summary,
    this.classe,
    this.serie,
    this.examen,
    this.order = 0,
    this.chapter,
    this.premium = false,
  });

  bool get isFiche => kind == 'fiche';

  /// Temps de lecture estimé (minutes), à partir du corps. Même logique que
  /// [Article.readTimeMinutes].
  int get readTimeMinutes {
    final text = (body ?? '').trim();
    if (text.isEmpty) return 1;
    final words = text.split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 99);
  }

  /// Vrai si ce contenu concerne un élève dont la classe / série valent
  /// [profileClasse] / [profileSerie]. Un champ vide en base = « tout le
  /// monde ». Comparaison insensible à la casse / aux espaces.
  bool matchesProfile({String? profileClasse, String? profileSerie}) {
    return _matchOne(classe, profileClasse) && _matchOne(serie, profileSerie);
  }

  static bool _matchOne(String? courseValue, String? profileValue) {
    final c = (courseValue ?? '').trim().toLowerCase();
    if (c.isEmpty) return true; // s'applique à tout le monde
    final p = (profileValue ?? '').trim().toLowerCase();
    if (p.isEmpty) return true; // profil non renseigné : ne pas masquer
    return c == p;
  }

  /// Construit un [Course] depuis un document Appwrite (lecture défensive,
  /// comme `Article.fromMap` / `Exam.fromMap`).
  factory Course.fromMap(
    Map<String, dynamic> data, {
    required String id,
    required String createdAtFallback,
  }) {
    final ord = data['order'];
    return Course(
      id: id,
      title: (data['title'] ?? '').toString(),
      subject: _subjectFrom((data['subject'] ?? 'maths').toString()),
      kind: (data['kind'] ?? 'cours').toString().trim().isEmpty
          ? 'cours'
          : (data['kind']).toString().trim().toLowerCase(),
      body: _nullStr(data['body']),
      summary: _nullStr(data['summary']),
      classe: _nullStr(data['classe']),
      serie: _nullStr(data['serie']),
      examen: _nullStr(data['examen']),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
      chapter: _nullStr(data['chapter']),
      premium: data['premium'] == true,
      createdAt: DateTime.tryParse(createdAtFallback) ?? DateTime.now(),
    );
  }

  static String? _nullStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
