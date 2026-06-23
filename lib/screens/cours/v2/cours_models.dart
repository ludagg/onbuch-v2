import 'package:flutter/material.dart';

/// Modèles « Cours v2 » (architecture Packs → Détail → Chapitre). DONNÉES
/// FICTIVES (placeholder) pour valider la structure — branchement API ensuite.
/// La logique d'accès (premium / crédits) est conservée via `premium` + le
/// verrouillage par progression (`statut` / `verrouille`).

enum ChapStatut { complete, enCours, verrouille }

class Exercice {
  final String id;
  final String libelle; // « Exercice 1 »
  final String enonce; // LaTeX inline, ex. « \int (2x+3)\,dx »
  final String statut; // non_fait | fait | corrige
  final bool verrouille;
  final String? lockMsg;
  const Exercice(this.id, this.libelle, this.enonce,
      {this.statut = 'non_fait', this.verrouille = false, this.lockMsg});
}

class Chapitre {
  final String id;
  final int index;
  final String titre;
  final ChapStatut statut;
  final String cours; // contenu riche (Markdown + LaTeX)
  final List<String> pointsCles;
  final List<String> formules; // LaTeX (sans délimiteurs)
  final String aRetenir;
  final List<Exercice> exercices;
  final String? fichePdfUrl;
  const Chapitre({
    required this.id,
    required this.index,
    required this.titre,
    required this.statut,
    this.cours = '',
    this.pointsCles = const [],
    this.formules = const [],
    this.aRetenir = '',
    this.exercices = const [],
    this.fichePdfUrl,
  });
  bool get accessible => statut != ChapStatut.verrouille;
}

class Pack {
  final String id;
  final String titre;
  final String serie; // « Bac C »
  final String niveau; // « Première » | « Terminale »
  final String matiere;
  final int nbLecons;
  final int nbExercices;
  final int nbFichesOuTP;
  final String fichesLabel; // « Fiches méthodes » | « TP expliqués »
  final int nbExamensBlancs;
  final double note;
  final int dureeHeures;
  final bool populaire;
  final double progressionPct; // 0..1
  final bool premium;
  final List<Chapitre> chapitres;
  const Pack({
    required this.id,
    required this.titre,
    required this.serie,
    required this.niveau,
    required this.matiere,
    required this.nbLecons,
    required this.nbExercices,
    required this.nbFichesOuTP,
    this.fichesLabel = 'Fiches méthodes',
    required this.nbExamensBlancs,
    required this.note,
    required this.dureeHeures,
    this.populaire = false,
    this.progressionPct = 0,
    this.premium = false,
    this.chapitres = const [],
  });

  String get meta => '$nbLecons leçons · $nbExercices exercices · $nbFichesOuTP ${fichesLabel.toLowerCase()}';
  String get noteDuree => '★ $note · ${dureeHeures}h de contenu';
  int get leconsFaites => (nbLecons * progressionPct).round();
}

/// Couleur d'accent par matière (cohérente avec la marque, orange dominant).
Color matiereTint(String matiere) {
  final m = matiere.toLowerCase();
  if (m.contains('phys')) return const Color(0xFF2D6CDF);
  if (m.contains('chim')) return const Color(0xFF1E9E63);
  return const Color(0xFFE9700D); // Maths / défaut → orange
}

// ── Données de démonstration ────────────────────────────────────────────────
const _coursIntegrales = '''
## Notion de primitive

Soit \$f\$ une fonction continue sur un intervalle \$I\$. On appelle **primitive**
de \$f\$ sur \$I\$ toute fonction \$F\$ dérivable telle que \$F'(x) = f(x)\$.

Si \$F\$ est une primitive de \$f\$, alors toutes les primitives de \$f\$ s'écrivent
\$F(x) + C\$, où \$C\$ est une constante réelle.

## Intégrale d'une fonction

L'intégrale indéfinie de \$f\$ est l'ensemble de ses primitives :
\$\$ \\int f(x)\\,dx = F(x) + C \$\$

L'**intégrale définie** entre \$a\$ et \$b\$ mesure l'aire algébrique sous la courbe :
\$\$ \\int_a^b f(x)\\,dx = F(b) - F(a) \$\$

## Exemple

Calculons \$\\int (2x + 3)\\,dx\$. Une primitive de \$2x+3\$ est \$x^2 + 3x\$, donc :
\$\$ \\int (2x+3)\\,dx = x^2 + 3x + C \$\$
''';

const _miniCours = '''
Ce chapitre fait partie du pack. Le contenu détaillé (cours, exemples et
exercices) sera disponible ici.
''';

Chapitre _chap(int i, String t, ChapStatut s) =>
    Chapitre(id: 'c$i', index: i, titre: t, statut: s, cours: _miniCours);

final _integrales = Chapitre(
  id: 'c4',
  index: 4,
  titre: 'Intégrales',
  statut: ChapStatut.enCours,
  cours: _coursIntegrales,
  pointsCles: const [
    'Une primitive \$F\$ de \$f\$ vérifie \$F\'(x) = f(x)\$.',
    'Deux primitives d\'une même fonction diffèrent d\'une constante.',
    'L\'intégrale définie \$\\int_a^b f\$ mesure l\'aire algébrique sous la courbe.',
    'On n\'oublie jamais la constante \$C\$ dans une intégrale indéfinie.',
  ],
  formules: const [
    r'\int f(x)\,dx = F(x) + C',
    r'\int_a^b f(x)\,dx = F(b) - F(a)',
    r'\int k\,f(x)\,dx = k \int f(x)\,dx',
  ],
  aRetenir:
      'Intégrer, c\'est « remonter » la dérivation. Pour vérifier un résultat, '
      'dérive ta primitive : tu dois retrouver la fonction de départ.',
  exercices: const [
    Exercice('e1', 'Exercice 1', r'\int (2x + 3)\,dx', statut: 'non_fait'),
    Exercice('e2', 'Exercice 2', r'\int (x^2 - 4x + 1)\,dx', statut: 'non_fait'),
    Exercice('e3', 'Exercice 3', r'\int \frac{1}{x}\,dx', statut: 'non_fait'),
    Exercice('e4', 'Exercice 4', r'\int e^{x}\,dx',
        verrouille: true, lockMsg: 'Terminer le cours pour déverrouiller'),
    Exercice('e5', 'Exercice 5', r'\int \cos(x)\,dx',
        verrouille: true, lockMsg: 'Terminer le cours pour déverrouiller'),
  ],
  fichePdfUrl: '',
);

final List<Pack> kPacks = [
  Pack(
    id: 'maths_tc',
    titre: 'Maths Terminale C',
    serie: 'Bac C',
    niveau: 'Terminale',
    matiere: 'Maths',
    nbLecons: 42,
    nbExercices: 120,
    nbFichesOuTP: 18,
    nbExamensBlancs: 6,
    note: 4.8,
    dureeHeures: 32,
    populaire: true,
    progressionPct: 0.80,
    chapitres: [
      _chap(1, 'Suites numériques', ChapStatut.complete),
      _chap(2, 'Limites', ChapStatut.complete),
      _chap(3, 'Dérivées', ChapStatut.complete),
      _integrales,
      _chap(5, 'Probabilités', ChapStatut.verrouille),
    ],
  ),
  Pack(
    id: 'phys_tc',
    titre: 'Physique Terminale C',
    serie: 'Bac C',
    niveau: 'Terminale',
    matiere: 'Physique',
    nbLecons: 28,
    nbExercices: 95,
    nbFichesOuTP: 12,
    fichesLabel: 'TP expliqués',
    nbExamensBlancs: 5,
    note: 4.7,
    dureeHeures: 26,
    chapitres: [
      _chap(1, 'Cinématique', ChapStatut.enCours),
      _chap(2, 'Lois de Newton', ChapStatut.verrouille),
      _chap(3, 'Champs', ChapStatut.verrouille),
    ],
  ),
  Pack(
    id: 'chimie_tc',
    titre: 'Chimie Terminale C',
    serie: 'Bac C',
    niveau: 'Terminale',
    matiere: 'Chimie',
    nbLecons: 26,
    nbExercices: 78,
    nbFichesOuTP: 10,
    nbExamensBlancs: 4,
    note: 4.6,
    dureeHeures: 24,
    chapitres: [
      _chap(1, 'Cinétique chimique', ChapStatut.enCours),
      _chap(2, 'Acides et bases', ChapStatut.verrouille),
    ],
  ),
  Pack(
    id: 'maths_p',
    titre: 'Maths Première',
    serie: 'Bac C',
    niveau: 'Première',
    matiere: 'Maths',
    nbLecons: 36,
    nbExercices: 110,
    nbFichesOuTP: 16,
    nbExamensBlancs: 5,
    note: 4.8,
    dureeHeures: 30,
    chapitres: [
      _chap(1, 'Second degré', ChapStatut.enCours),
      _chap(2, 'Dérivation', ChapStatut.verrouille),
    ],
  ),
  Pack(
    id: 'phys_p',
    titre: 'Physique Première',
    serie: 'Bac C',
    niveau: 'Première',
    matiere: 'Physique',
    nbLecons: 24,
    nbExercices: 70,
    nbFichesOuTP: 8,
    fichesLabel: 'TP expliqués',
    nbExamensBlancs: 4,
    note: 4.6,
    dureeHeures: 22,
    chapitres: [_chap(1, 'Énergie', ChapStatut.enCours)],
  ),
  Pack(
    id: 'chimie_p',
    titre: 'Chimie Première',
    serie: 'Bac C',
    niveau: 'Première',
    matiere: 'Chimie',
    nbLecons: 24,
    nbExercices: 80,
    nbFichesOuTP: 10,
    nbExamensBlancs: 4,
    note: 4.7,
    dureeHeures: 28,
    chapitres: [_chap(1, 'La matière', ChapStatut.enCours)],
  ),
];

Pack? packById(String id) {
  for (final p in kPacks) {
    if (p.id == id) return p;
  }
  return null;
}

const List<String> kCategories = ['Bac C', 'Première', 'Terminale', 'Maths', 'Physique', 'Chimie'];
