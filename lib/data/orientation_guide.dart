import 'package:flutter/material.dart';

/// Une filière post-bac (famille de concours / écoles) avec ses débouchés.
/// Sert à « fixer » les bacheliers : à quoi mène concrètement chaque concours.
class OrientationField {
  final String title;
  final String tagline;
  /// Sigles / mots-clés permettant de rattacher un concours à cette filière
  /// (rapprochement automatique avec le nom du concours).
  final List<String> keywords;
  /// Quelques écoles emblématiques (exemples).
  final List<String> schools;
  /// Métiers et débouchés concrets.
  final List<String> debouches;
  final IconData icon;
  final Color accent;

  const OrientationField({
    required this.title,
    required this.tagline,
    required this.keywords,
    required this.schools,
    required this.debouches,
    required this.icon,
    required this.accent,
  });
}

/// Base de connaissances « orientation » — principales filières camerounaises.
const List<OrientationField> kOrientationGuide = [
  OrientationField(
    title: 'Ingénierie & Polytechnique',
    tagline: 'Concevoir, construire, innover : les métiers d\'ingénieur.',
    keywords: ['ENSP', 'ENSPD', 'ENSPY', 'POLYTECHNIQUE', 'POLYTECH', 'ENSTP', 'ENSAI', 'EGEM', 'EGCIM', 'ENSPT', 'SUP\'PTIC', 'SUPPTIC', 'FET', 'ENGINEERING', 'TECHNOLOGY', 'GENIE', 'GÉNIE'],
    schools: ['ENSP Yaoundé / Maroua', 'ENSPD Douala', 'ENSTP (travaux publics)', 'ENSAI Ngaoundéré', 'Sup\'PTIC'],
    debouches: [
      'Ingénieur génie civil, électrique, mécanique, industriel',
      'Ingénieur informatique / réseaux & télécoms',
      'Ingénieur agro-industriel, mines & géologie',
      'Chef de projet, bureau d\'études, chercheur',
    ],
    icon: Icons.engineering_rounded,
    accent: Color(0xFF2D6CDF),
  ),
  OrientationField(
    title: 'Médecine & Santé',
    tagline: 'Soigner et sauver des vies.',
    keywords: ['FMSB', 'FMSP', 'MEDECINE', 'MÉDECINE', 'SANTE', 'SANTÉ', 'FACSANTE', 'PHARMACIE', 'IFSP', 'IDE', 'INFIRMIER'],
    schools: ['FMSB Yaoundé', 'FMSP Douala', 'Facultés de médecine', 'Écoles d\'infirmiers (IDE)'],
    debouches: [
      'Médecin généraliste ou spécialiste',
      'Pharmacien, chirurgien-dentiste',
      'Infirmier(ère) diplômé(e) d\'État, sage-femme',
      'Technicien médico-sanitaire, biologiste',
    ],
    icon: Icons.medical_services_rounded,
    accent: Color(0xFFD2462E),
  ),
  OrientationField(
    title: 'Enseignement (ENS / ENSET)',
    tagline: 'Transmettre le savoir, former les générations.',
    keywords: ['ENS', 'ENSET', 'ENIEG', 'ENIET', 'NORMALE'],
    schools: ['ENS Yaoundé / Bambili / Maroua', 'ENSET Douala / Kumba', 'ENIEG, ENIET'],
    debouches: [
      'Professeur des lycées (enseignement général)',
      'Professeur de l\'enseignement technique',
      'Instituteur de l\'enseignement primaire',
      'Conseiller d\'orientation, inspecteur (après expérience)',
    ],
    icon: Icons.school_rounded,
    accent: Color(0xFF1E9E63),
  ),
  OrientationField(
    title: 'Administration & Magistrature',
    tagline: 'Servir l\'État aux postes de responsabilité.',
    keywords: ['ENAM'],
    schools: ['ENAM (École Nationale d\'Administration et de Magistrature)'],
    debouches: [
      'Administrateur civil, magistrat, greffier',
      'Inspecteur des impôts, des douanes, du trésor',
      'Administrateur du travail, de la prévoyance sociale',
      'Régisseur, cadre de la fonction publique',
    ],
    icon: Icons.account_balance_rounded,
    accent: Color(0xFF7A5AE0),
  ),
  OrientationField(
    title: 'Diplomatie & Relations internationales',
    tagline: 'Représenter et négocier pour le pays.',
    keywords: ['IRIC', 'DIPLOMATIE', 'RELATIONS INTERNATIONALES'],
    schools: ['IRIC (Institut des Relations Internationales du Cameroun)'],
    debouches: [
      'Diplomate, attaché des affaires étrangères',
      'Analyste en relations internationales',
      'Cadre d\'organisations internationales (ONU, UA…)',
      'Spécialiste en coopération & développement',
    ],
    icon: Icons.public_rounded,
    accent: Color(0xFF0E9AA0),
  ),
  OrientationField(
    title: 'Défense & Sécurité',
    tagline: 'Protéger la nation et les citoyens.',
    keywords: ['EMIA', 'ESM', 'MILITAIRE', 'ARMEE', 'ARMÉE', 'GENDARMERIE', 'POLICE', 'ENAP', 'EAMAC'],
    schools: ['EMIA (École Militaire Interarmées)', 'Écoles de police & de gendarmerie', 'EAMAC (aviation civile)'],
    debouches: [
      'Officier de l\'armée de terre, de l\'air, de la marine',
      'Officier de gendarmerie, commissaire de police',
      'Contrôleur aérien, ingénieur de l\'aviation civile',
      'Cadre de l\'administration pénitentiaire',
    ],
    icon: Icons.shield_rounded,
    accent: Color(0xFF4A5568),
  ),
  OrientationField(
    title: 'Agriculture, Forêts & Élevage',
    tagline: 'Nourrir le pays et gérer ses ressources.',
    keywords: ['FASA', 'AGRONOMIE', 'AGRICULTURE', 'EAUX ET FORETS', 'EAUX ET FORÊTS', 'FORESTERIE', 'ELEVAGE', 'ÉLEVAGE', 'ZOOTECHNIE', 'VETERINAIRE', 'VÉTÉRINAIRE'],
    schools: ['FASA Dschang', 'Écoles des eaux & forêts (Mbalmayo)', 'ENSAI Ngaoundéré'],
    debouches: [
      'Ingénieur agronome',
      'Ingénieur des eaux, forêts et chasse',
      'Ingénieur zootechnicien, vétérinaire',
      'Cadre agro-industriel, entrepreneur agricole',
    ],
    icon: Icons.agriculture_rounded,
    accent: Color(0xFF2F855A),
  ),
  OrientationField(
    title: 'Commerce, Gestion & Économie',
    tagline: 'Piloter les entreprises et les finances.',
    keywords: ['ESSEC', 'COMMERCE', 'GESTION', 'IUT', 'FSEG', 'COMPTABILITE', 'COMPTABILITÉ', 'FINANCE', 'BANQUE', 'MARKETING'],
    schools: ['ESSEC Douala', 'IUT (GEA, GLT…)', 'Facultés de sciences éco. & gestion'],
    debouches: [
      'Cadre commercial, marketing, ressources humaines',
      'Comptable, auditeur, contrôleur de gestion',
      'Banquier, analyste financier',
      'Logisticien, entrepreneur',
    ],
    icon: Icons.trending_up_rounded,
    accent: Color(0xFFB7791F),
  ),
  OrientationField(
    title: 'Journalisme & Communication',
    tagline: 'Informer, raconter, influencer.',
    keywords: ['ESSTIC', 'JOURNALISME', 'COMMUNICATION', 'MEDIAS', 'MÉDIAS'],
    schools: ['ESSTIC (Yaoundé II)'],
    debouches: [
      'Journaliste (presse, radio, télé, web)',
      'Chargé de communication, attaché de presse',
      'Publicitaire, community manager',
      'Documentaliste, éditeur',
    ],
    icon: Icons.campaign_rounded,
    accent: Color(0xFFDD6B20),
  ),
  OrientationField(
    title: 'Arts, Design & Architecture',
    tagline: 'Créer, dessiner, bâtir le beau.',
    keywords: ['BEAUX-ARTS', 'BEAUX ARTS', 'IBAF', 'IBAN', 'ARCHITECTURE', 'DESIGN', 'ARTS'],
    schools: ['Institut des Beaux-Arts (Foumban, Nkongsamba)'],
    debouches: [
      'Artiste plasticien, sculpteur, peintre',
      'Designer, infographiste, illustrateur',
      'Architecte d\'intérieur, décorateur',
      'Métiers de la culture & du patrimoine',
    ],
    icon: Icons.palette_rounded,
    accent: Color(0xFFD53F8C),
  ),
  OrientationField(
    title: 'Sport & Animation (INJS)',
    tagline: 'Bouger, encadrer, animer la jeunesse.',
    keywords: ['INJS', 'SPORT', 'EPS', 'JEUNESSE', 'ANIMATION'],
    schools: ['INJS (Institut National de la Jeunesse et des Sports)'],
    debouches: [
      'Professeur d\'éducation physique (EPS)',
      'Entraîneur, préparateur physique',
      'Conseiller de jeunesse et d\'animation',
      'Gestionnaire d\'infrastructures sportives',
    ],
    icon: Icons.sports_soccer_rounded,
    accent: Color(0xFF3182CE),
  ),
  OrientationField(
    title: 'Université (Licence générale)',
    tagline: 'Construire son parcours à la faculté.',
    keywords: ['FACULTE', 'FACULTÉ', 'LICENCE', 'UNIVERSITE', 'UNIVERSITÉ'],
    schools: ['Sciences (FS)', 'Lettres & sciences humaines (FALSH)', 'Sciences juridiques & politiques (FSJP)'],
    debouches: [
      'Poursuite en Master puis Doctorat / recherche',
      'Enseignant-chercheur, cadre d\'entreprise',
      'Métiers du droit, des sciences, des lettres',
      'Préparation aux concours après la licence',
    ],
    icon: Icons.menu_book_rounded,
    accent: Color(0xFF718096),
  ),
];

/// Retire les accents et met en majuscules, pour un rapprochement robuste.
String _norm(String s) {
  const map = {
    'À': 'A', 'Â': 'A', 'Ä': 'A', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Î': 'I', 'Ï': 'I', 'Ô': 'O', 'Ö': 'O', 'Û': 'U', 'Ù': 'U', 'Ü': 'U', 'Ç': 'C',
  };
  final up = s.toUpperCase();
  final b = StringBuffer();
  for (final ch in up.split('')) {
    b.write(map[ch] ?? ch);
  }
  // Retire les apostrophes (droite et typographique) : SUP'PTIC ≡ SUPPTIC.
  return b.toString().replaceAll('\'', '').replaceAll('’', '');
}

/// Rapproche un concours (par son nom) d'une filière du guide, si possible.
OrientationField? matchOrientation(String name) {
  if (name.trim().isEmpty) return null;
  final up = _norm(name);
  for (final f in kOrientationGuide) {
    for (final k in f.keywords) {
      final kk = _norm(k);
      // Frontière de « mot » : le sigle doit être isolé (évite ENS dans ENSP).
      // Les mots-clés ne contiennent aucun métacaractère regex (lettres, chiffres,
      // espaces, apostrophe, tiret) → interpolation directe sans échappement.
      final re = RegExp('(^|[^A-Z0-9])${kk}(\$|[^A-Z0-9])');
      if (re.hasMatch(up)) return f;
    }
  }
  return null;
}
