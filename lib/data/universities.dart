import '../models/university.dart';

/// Annuaire de repli des universités camerounaises (utilisé tant que la
/// collection Appwrite `universities` n'est pas renseignée par l'admin).
/// Le `rank` est un classement *indicatif* — éditable côté back-office.
/// Sources : MINESUP (offre de formation), sites officiels des universités.
const List<University> kUniversities = [
  // ── Universités d'État ────────────────────────────────────────────────────
  University(
    name: 'Université de Yaoundé I', acronym: 'UY1', city: 'Yaoundé',
    type: 'Publique', founded: 1962, rank: 1, order: 1,
    fields: ['Sciences', 'Médecine', 'Polytechnique', 'Lettres', 'Éducation'],
    website: 'https://uy1.uninet.cm',
    description: 'La plus ancienne université du pays. Abrite l\'ENS, la FMSB et l\'École Nationale Supérieure Polytechnique.',
  ),
  University(
    name: 'Université de Douala', acronym: 'UD', city: 'Douala',
    type: 'Publique', founded: 1993, rank: 2, order: 2,
    fields: ['Sciences économiques', 'Génie', 'Sciences', 'Médecine', 'Beaux-arts'],
    website: 'https://www.univ-douala.cm',
    description: 'Grand pôle économique et technologique : ESSEC, IUT, ENSET, FGI.',
  ),
  University(
    name: 'Université de Dschang', acronym: 'UDs', city: 'Dschang',
    type: 'Publique', founded: 1993, rank: 3, order: 3,
    fields: ['Agronomie', 'Sciences', 'Droit', 'Sciences économiques'],
    website: 'https://www.univ-dschang.org',
    description: 'Référence en agronomie et sciences de l\'environnement (FASA).',
  ),
  University(
    name: 'Université de Buea', acronym: 'UB', city: 'Buea',
    type: 'Publique', founded: 1993, rank: 4, order: 4,
    fields: ['Anglophone', 'Sciences', 'Technologie', 'Santé', 'Éducation'],
    website: 'https://www.ubuea.cm',
    description: 'Université de tradition anglo-saxonne, réputée en sciences et en éducation.',
  ),
  University(
    name: 'Université de Yaoundé II', acronym: 'UY2', city: 'Soa',
    type: 'Publique', founded: 1993, rank: 5, order: 5,
    fields: ['Droit', 'Sciences politiques', 'Sciences économiques', 'Relations internationales'],
    website: 'https://www.universite-yde2.org',
    description: 'Spécialisée en sciences juridiques, politiques et économiques. Abrite l\'IRIC.',
  ),
  University(
    name: 'Université de Ngaoundéré', acronym: 'UN', city: 'Ngaoundéré',
    type: 'Publique', founded: 1993, rank: 6, order: 6,
    fields: ['Sciences alimentaires', 'Génie', 'Sciences', 'Sciences économiques'],
    website: 'https://www.univ-ndere.cm',
    description: 'Pôle reconnu en sciences alimentaires et agro-industrie (ENSAI).',
  ),
  University(
    name: 'Université de Maroua', acronym: 'UMa', city: 'Maroua',
    type: 'Publique', founded: 2008, rank: 7, order: 7,
    fields: ['Éducation', 'Mines', 'Génie', 'Sciences'],
    website: 'https://www.univ-maroua.cm',
    description: 'Forme massivement les enseignants (ENS) et les techniciens des mines (EGEM).',
  ),
  University(
    name: 'Université de Bamenda', acronym: 'UBa', city: 'Bamenda',
    type: 'Publique', founded: 2010, rank: 8, order: 8,
    fields: ['Anglophone', 'Éducation', 'Sciences', 'Technologie', 'Santé'],
    website: 'https://www.uniba.cm',
    description: 'Université anglophone : ENS Bambili, College of Technology, sciences de la santé.',
  ),

  // ── Universités privées / confessionnelles de référence ───────────────────
  University(
    name: 'Université Catholique d\'Afrique Centrale', acronym: 'UCAC', city: 'Yaoundé',
    type: 'Privée', founded: 1991, rank: 9, order: 20,
    fields: ['Gestion', 'Droit', 'Santé', 'Sciences sociales', 'Philosophie'],
    website: 'https://www.ucac.cm',
    description: 'Université privée de premier plan (FSSG, FSJP, École des sciences de la santé).',
  ),
  University(
    name: 'Université des Montagnes', acronym: 'UdM', city: 'Bangangté',
    type: 'Privée', founded: 2000, rank: 10, order: 21,
    fields: ['Médecine', 'Pharmacie', 'Sciences de la santé', 'Génie'],
    website: 'https://www.udesmontagnes.org',
    description: 'Université privée réputée pour ses formations médicales et de santé.',
  ),
  University(
    name: 'The ICT University', acronym: 'ICTU', city: 'Yaoundé',
    type: 'Privée', founded: 2010, rank: 11, order: 22,
    fields: ['Informatique', 'Technologies', 'Gestion', 'Management'],
    website: 'https://ictuniversity.org',
    description: 'Spécialisée dans les technologies de l\'information et le management.',
  ),
  University(
    name: 'Université Adventiste Cosendai', acronym: 'UAC', city: 'Nanga-Eboko',
    type: 'Privée', founded: 1993, rank: 12, order: 23,
    fields: ['Gestion', 'Sciences infirmières', 'Théologie', 'Informatique'],
    website: 'https://www.cosendai-adventist.cm',
    description: 'Université privée confessionnelle (gestion, santé, informatique).',
  ),
];
