import '../models/bourse.dart';

/// Liste de repli des bourses d'études (utilisée tant que la collection
/// Appwrite `bourses` n'est pas renseignée par l'admin). Informations
/// indicatives — vérifier toujours les dates et conditions sur le lien officiel.
const List<Bourse> kBourses = [
  Bourse(
    title: 'Bourses d\'excellence MINESUP', provider: 'État du Cameroun',
    level: 'Licence · Master · Doctorat', destination: 'Cameroun',
    coverage: 'Allocation annuelle aux meilleurs étudiants',
    deadline: 'Rentrée universitaire (annuel)', order: 1,
    tags: ['Cameroun', 'Excellence', 'Public'],
    description: 'Aides et primes d\'excellence du Ministère de l\'Enseignement Supérieur pour les étudiants les plus méritants des universités d\'État.',
    link: 'https://www.minesup.gov.cm',
  ),
  Bourse(
    title: 'Bourse du gouvernement chinois (CSC)', provider: 'Gouvernement chinois',
    level: 'Licence · Master · Doctorat', destination: 'Chine',
    coverage: 'Frais de scolarité + logement + allocation mensuelle',
    deadline: 'Décembre – Avril (annuel)', order: 2,
    tags: ['Étranger', 'Chine', 'Complète'],
    description: 'Programme du China Scholarship Council pour étudier dans les universités chinoises. Candidature via l\'ambassade ou l\'université d\'accueil.',
    link: 'https://www.campuschina.org',
  ),
  Bourse(
    title: 'Bourses du gouvernement français (BGF)', provider: 'Ambassade de France',
    level: 'Master · Doctorat', destination: 'France',
    coverage: 'Allocation, frais, couverture sociale (selon programme)',
    deadline: 'Variable (campagne annuelle)', order: 3,
    tags: ['Étranger', 'France'],
    description: 'Bourses de l\'ambassade de France au Cameroun (Campus France) pour poursuivre ses études supérieures en France.',
    link: 'https://www.cameroun.campusfrance.org',
  ),
  Bourse(
    title: 'Bourses Commonwealth', provider: 'Commonwealth (Royaume-Uni)',
    level: 'Master · Doctorat', destination: 'Royaume-Uni',
    coverage: 'Frais + billet + allocation',
    deadline: 'Octobre – Décembre (annuel)', order: 4,
    tags: ['Étranger', 'Anglophone', 'Complète'],
    description: 'Pour les ressortissants des pays du Commonwealth (dont le Cameroun) souhaitant étudier au Royaume-Uni.',
    link: 'https://cscuk.fcdo.gov.uk',
  ),
  Bourse(
    title: 'Bourses DAAD (Allemagne)', provider: 'DAAD',
    level: 'Master · Doctorat', destination: 'Allemagne',
    coverage: 'Allocation mensuelle + assurances + voyage',
    deadline: 'Variable selon le programme', order: 5,
    tags: ['Étranger', 'Allemagne', 'Recherche'],
    description: 'Office allemand d\'échanges universitaires : bourses d\'études et de recherche en Allemagne.',
    link: 'https://www.daad.de',
  ),
  Bourse(
    title: 'Bourses du gouvernement marocain (AMCI)', provider: 'AMCI – Maroc',
    level: 'Licence · Master', destination: 'Maroc',
    coverage: 'Inscription + allocation mensuelle',
    deadline: 'Mars – Mai (annuel)', order: 6,
    tags: ['Étranger', 'Maroc'],
    description: 'Agence Marocaine de Coopération Internationale : bourses pour étudier dans les établissements publics marocains.',
    link: 'https://www.amci.ma',
  ),
  Bourse(
    title: 'Bourses du gouvernement russe', provider: 'Rossotrudnichestvo',
    level: 'Licence · Master · Doctorat', destination: 'Russie',
    coverage: 'Scolarité + allocation + logement',
    deadline: 'Variable (campagne annuelle)', order: 7,
    tags: ['Étranger', 'Russie', 'Complète'],
    description: 'Quotas de bourses offerts par la Fédération de Russie aux étudiants camerounais.',
    link: 'https://education-in-russia.com',
  ),
  Bourse(
    title: 'Bourses Mastercard Foundation', provider: 'Mastercard Foundation',
    level: 'Licence · Master', destination: 'Afrique & international',
    coverage: 'Bourse complète (frais, logement, accompagnement)',
    deadline: 'Variable selon l\'université partenaire', order: 8,
    tags: ['Complète', 'Leadership', 'International'],
    description: 'Programme Scholars pour jeunes africains talentueux et engagés, via un réseau d\'universités partenaires.',
    link: 'https://mastercardfdn.org/all/scholars',
  ),
];
