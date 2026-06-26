import 'package:flutter/material.dart';

/// Une université / grande école camerounaise présentée dans l'annuaire
/// « Universités » (page Orientation). Gérable par l'admin (collection
/// `universities`) avec repli sur une liste curée embarquée (`kUniversities`).
class University {
  final String name;        // « Université de Yaoundé I »
  final String acronym;     // « UY1 »
  final String city;        // « Yaoundé »
  final String type;        // « Publique » | « Privée »
  final int founded;        // année de création (0 = inconnue)
  final List<String> fields;// domaines phares (filtres rapides)
  final String website;     // site officiel (optionnel)
  final String description; // courte présentation
  final int rank;           // classement national (1 = en tête ; 0 = non classé)
  final int order;
  final bool active;

  const University({
    required this.name,
    required this.acronym,
    required this.city,
    this.type = 'Publique',
    this.founded = 0,
    this.fields = const [],
    this.website = '',
    this.description = '',
    this.rank = 0,
    this.order = 0,
    this.active = true,
  });

  bool get isPublic => type.trim().toLowerCase().startsWith('pub');

  factory University.fromMap(Map<String, dynamic> m, {String? id}) {
    String s(dynamic v) => (v ?? '').toString().trim();
    int i(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    final rawFields = s(m['fields']);
    return University(
      name: s(m['name']),
      acronym: s(m['acronym']),
      city: s(m['city']),
      type: s(m['type']).isEmpty ? 'Publique' : s(m['type']),
      founded: i(m['founded']),
      fields: rawFields.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      website: s(m['website']),
      description: s(m['description']),
      rank: i(m['rank']),
      order: i(m['order']),
      active: m['active'] != false,
    );
  }

  /// Couleur d'accent déterministe (identité visuelle de la fiche).
  Color get accent {
    const palette = [
      Color(0xFF2D6CDF), Color(0xFF1E9E63), Color(0xFFDB4F12),
      Color(0xFF7A5AE0), Color(0xFF0E9AA0), Color(0xFFA6701A),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }
}
