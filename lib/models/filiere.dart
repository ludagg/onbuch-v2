import 'package:flutter/material.dart';

/// Une **filière de formation** (programme d'études) telle qu'on peut la suivre
/// au Cameroun : son domaine, les diplômes préparés, les séries du Bac
/// conseillées, les établissements qui la proposent, les concours d'entrée
/// éventuels, les compétences attendues et les débouchés (métiers).
///
/// Sert la page « Filières » : l'élève cherche une filière, vérifie qu'elle
/// existe, voit où la faire et ce qu'elle exige / à quoi elle mène.
class Filiere {
  final String name;

  /// Domaine / famille (sert au filtre) : ex. « Ingénierie & Technologie ».
  final String domain;

  /// Une phrase d'accroche.
  final String tagline;

  /// Présentation un peu plus longue (1–3 phrases).
  final String description;

  /// Diplômes préparés : « Licence », « Master », « Diplôme d'ingénieur »…
  final List<String> diplomas;

  /// Durée typique des études : « 3 ans », « 5 ans »…
  final String duration;

  /// Séries du Bac / profils conseillés : « C », « D », « TI », « A », « G »…
  final List<String> bacSeries;

  /// Établissements / universités camerounais qui proposent la filière.
  final List<String> universities;

  /// Concours ou voies d'accès (vide si admission sur dossier).
  final List<String> concours;

  /// Compétences & qualités utiles pour réussir.
  final List<String> skills;

  /// Métiers et débouchés concrets.
  final List<String> debouches;

  final IconData icon;
  final Color accent;

  const Filiere({
    required this.name,
    required this.domain,
    required this.tagline,
    required this.description,
    required this.diplomas,
    required this.duration,
    required this.bacSeries,
    required this.universities,
    required this.concours,
    required this.skills,
    required this.debouches,
    required this.icon,
    required this.accent,
  });

  /// Texte concaténé (minuscules) pour une recherche tolérante.
  String get searchBlob => [
        name,
        domain,
        tagline,
        description,
        ...diplomas,
        ...bacSeries,
        ...universities,
        ...concours,
        ...skills,
        ...debouches,
      ].join(' ').toLowerCase();
}
