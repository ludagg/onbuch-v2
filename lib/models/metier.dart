import 'package:flutter/material.dart';

/// Une fiche **métier** (orientation) : description, compétences, niveau
/// d'études, perspectives, évolution de carrière, filières liées. Le **salaire**
/// et les **témoignages** sont saisis par l'admin (vides tant que non remplis).
/// Gérée dans la collection `metiers` (repli liste vide).
class Metier {
  final String id;
  final String name;
  final String sector;
  final String description;
  final List<String> skills;
  final String educationLevel;
  final String prospects;
  final String careerPath;
  final List<String> relatedFilieres;
  final String salary;        // admin
  final List<String> testimonials; // admin ("Nom — texte" par ligne)
  final String icon;
  final int order;
  final bool active;

  const Metier({
    required this.id,
    required this.name,
    this.sector = '',
    this.description = '',
    this.skills = const [],
    this.educationLevel = '',
    this.prospects = '',
    this.careerPath = '',
    this.relatedFilieres = const [],
    this.salary = '',
    this.testimonials = const [],
    this.icon = '',
    this.order = 0,
    this.active = true,
  });

  static List<String> _split(String raw) {
    final r = raw.trim();
    if (r.isEmpty) return const [];
    final sep = r.contains('|') ? '|' : (r.contains('\n') ? '\n' : ';');
    return r.split(sep).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  factory Metier.fromMap(Map<String, dynamic> m, {String? id}) {
    String s(dynamic v) => (v ?? '').toString().trim();
    int i(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    return Metier(
      id: id ?? s(m['\$id']),
      name: s(m['name']),
      sector: s(m['sector']),
      description: s(m['description']),
      skills: _split(s(m['skills'])),
      educationLevel: s(m['educationLevel']),
      prospects: s(m['prospects']),
      careerPath: s(m['careerPath']),
      relatedFilieres: _split(s(m['relatedFilieres'])),
      salary: s(m['salary']),
      testimonials: _split(s(m['testimonials'])),
      icon: s(m['icon']),
      order: i(m['order']),
      active: m['active'] != false,
    );
  }

  /// Texte concaténé (minuscule) pour la recherche.
  String get searchBlob =>
      [name, sector, description, ...skills, ...relatedFilieres].join(' ').toLowerCase();

  /// Icône Material à partir d'un mot-clé simple.
  IconData get iconData {
    switch (icon) {
      case 'engineering': return Icons.engineering_rounded;
      case 'health': return Icons.medical_services_rounded;
      case 'code': return Icons.code_rounded;
      case 'gavel': return Icons.gavel_rounded;
      case 'school': return Icons.school_rounded;
      case 'business': return Icons.business_center_rounded;
      case 'design': return Icons.design_services_rounded;
      case 'agriculture': return Icons.agriculture_rounded;
      case 'media': return Icons.campaign_rounded;
      case 'science': return Icons.science_rounded;
      case 'security': return Icons.shield_rounded;
      case 'finance': return Icons.account_balance_rounded;
      case 'hotel': return Icons.hotel_rounded;
      case 'transport': return Icons.local_shipping_rounded;
      case 'social': return Icons.volunteer_activism_rounded;
      default: return Icons.work_rounded;
    }
  }

  /// Couleur d'accent déterministe.
  Color get accent {
    const palette = [
      Color(0xFF2D6CDF), Color(0xFF1E9E63), Color(0xFFDB4F12),
      Color(0xFF7A5AE0), Color(0xFF0E9AA0), Color(0xFFC0392B), Color(0xFFB7791F),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }
}
