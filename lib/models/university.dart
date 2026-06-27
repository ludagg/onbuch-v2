import 'package:flutter/material.dart';

/// Une université / grande école camerounaise présentée dans l'annuaire
/// « Universités » (page Orientation). Gérable par l'admin (collection
/// `universities`) avec repli sur une liste curée embarquée (`kUniversities`).
class University {
  final String name;        // « Université de Yaoundé I »
  final String acronym;     // « UY1 »
  final String city;        // « Yaoundé »
  final String region;      // région administrative, ex. « Centre »
  final String type;        // « Publique » | « Privée »
  final int founded;        // année de création (0 = inconnue)
  final List<String> fields;// domaines phares (filtres rapides)
  final List<String> schools;  // grandes écoles / facultés rattachées
  final List<String> programs; // exemples de cursus / filières offerts
  final String website;     // site officiel (optionnel)
  final String logoUrl;     // logo officiel (optionnel)
  final String description; // courte présentation
  final int rank;           // classement national (1 = en tête ; 0 = non classé)
  final int order;
  final bool active;

  // ── Fiche détaillée (gérée par l'admin ; vide = section masquée) ───────────
  final String tuition;            // frais de scolarité
  final String admission;          // conditions d'admission
  final String registrationDates;  // dates des inscriptions
  final List<String> documents;    // pièces à fournir
  final String places;             // nombre de places
  final String successRate;        // taux de réussite
  final String accreditation;      // accréditation des diplômes
  final List<String> campuses;     // campus disponibles
  final String residences;         // résidences universitaires

  const University({
    required this.name,
    required this.acronym,
    required this.city,
    this.region = '',
    this.type = 'Publique',
    this.founded = 0,
    this.fields = const [],
    this.schools = const [],
    this.programs = const [],
    this.website = '',
    this.logoUrl = '',
    this.description = '',
    this.rank = 0,
    this.order = 0,
    this.active = true,
    this.tuition = '',
    this.admission = '',
    this.registrationDates = '',
    this.documents = const [],
    this.places = '',
    this.successRate = '',
    this.accreditation = '',
    this.campuses = const [],
    this.residences = '',
  });

  /// Vrai s'il y a au moins une info de fiche détaillée à afficher.
  bool get hasDetails =>
      tuition.isNotEmpty || admission.isNotEmpty || registrationDates.isNotEmpty ||
      documents.isNotEmpty || places.isNotEmpty || successRate.isNotEmpty ||
      accreditation.isNotEmpty || campuses.isNotEmpty || residences.isNotEmpty;

  bool get isPublic => type.trim().toLowerCase().startsWith('pub');
  bool get hasLogo => logoUrl.trim().isNotEmpty;

  /// Découpe une liste sérialisée. On privilégie le séparateur `|` (utilisé en
  /// base car les noms d'écoles contiennent des virgules) ; à défaut on accepte
  /// `;` puis `,` (saisie admin simple).
  static List<String> _splitList(String raw) {
    final r = raw.trim();
    if (r.isEmpty) return const [];
    final sep = r.contains('|') ? '|' : (r.contains(';') ? ';' : ',');
    return r.split(sep).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  factory University.fromMap(Map<String, dynamic> m, {String? id}) {
    String s(dynamic v) => (v ?? '').toString().trim();
    int i(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    return University(
      name: s(m['name']),
      acronym: s(m['acronym']),
      city: s(m['city']),
      region: s(m['region']),
      type: s(m['type']).isEmpty ? 'Publique' : s(m['type']),
      founded: i(m['founded']),
      fields: _splitList(s(m['fields'])),
      schools: _splitList(s(m['schools'])),
      programs: _splitList(s(m['programs'])),
      website: s(m['website']),
      logoUrl: s(m['logoUrl']),
      description: s(m['description']),
      rank: i(m['rank']),
      order: i(m['order']),
      active: m['active'] != false,
      tuition: s(m['tuition']),
      admission: s(m['admission']),
      registrationDates: s(m['registrationDates']),
      documents: _splitList(s(m['documents'])),
      places: s(m['places']),
      successRate: s(m['successRate']),
      accreditation: s(m['accreditation']),
      campuses: _splitList(s(m['campuses'])),
      residences: s(m['residences']),
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
