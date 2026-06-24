# Fascicule de Mathématiques — Terminale C (Bac Scientifique, Cameroun)
## Plan détaillé — à valider avant rédaction

> Référence : programme APC (4 compétences / thèmes / leçons), ossature GPM Tle C
> (19 ch.) + ajouts camerounais (algèbre linéaire, matrices, graphes) → **23 chapitres**.
> Conventions : énoncés contexte camerounais, progression Facile→Bac, design OnBuch.
> Structure de CHAQUE chapitre :
> **A. L'essentiel du cours** (définitions, théorèmes, propriétés — encadrés)
> **B. Méthodes & savoir-faire** (techniques-types, chacune avec un exemple résolu)
> **C. Exercices d'application** (progressifs) → **D. Problèmes type Bac** → **E. Corrigés**

---

# PARTIE I — ANALYSE

## Chapitre 1 — Limites et continuité
**Cours.** Limites finies/infinies en un point et à l'infini ; limites de référence ; opérations sur les limites ; formes indéterminées ($\frac00,\frac\infty\infty,\infty-\infty,0\times\infty$) ; limite d'une fonction composée ; limite d'une fonction monotone ; continuité en un point et sur un intervalle ; prolongement par continuité ; théorème des valeurs intermédiaires (TVI) et corollaire (fonction strictement monotone) ; image d'un intervalle.
**Méthodes.** M1 lever une FI (factorisation, conjugué, terme de plus haut degré) · M2 limite d'une composée · M3 étudier la continuité / prolonger par continuité · M4 appliquer le TVI (existence d'une solution de $f(x)=0$) · M5 dénombrer/encadrer les solutions par dichotomie.
**Exercices.** Calculs de limites ; asymptotes (rappel) ; continuité avec paramètre ; TVI et encadrement de racine. **Problème Bac** : étude de continuité + existence de solution.

## Chapitre 2 — Dérivabilité, étude de fonctions et convexité
**Cours.** Dérivabilité en un point (nombre dérivé, tangente), à gauche/droite ; fonction dérivée ; dérivées des fonctions de référence et opérations ; dérivée d'une composée ; dérivées successives ; sens de variation ; extremums ; **inégalité des accroissements finis** ; **convexité, concavité, point d'inflexion** (lien avec $f''$) ; asymptotes et branches infinies ; plan d'étude complet.
**Méthodes.** M1 calculer une dérivée (composée, quotient, racine) · M2 équation de tangente · M3 dresser variations + extremums · M4 étudier la convexité et les points d'inflexion · M5 rechercher les asymptotes/branches infinies · M6 plan complet d'étude et tracé · M7 appliquer l'inégalité des accroissements finis.
**Exercices.** Tangentes, variations, convexité ; études de fonctions polynômes/rationnelles/irrationnelles. **Problème Bac** : étude complète avec paramètre + convexité.

## Chapitre 3 — Suites numériques
**Cours.** Modes de génération ; suites majorées/minorées/bornées ; monotonie ; suites arithmétiques, géométriques, **arithmético-géométriques**, récurrentes $u_{n+1}=f(u_n)$ ; convergence/divergence ; théorèmes (suite croissante majorée, comparaison, gendarmes) ; suites adjacentes.
**Méthodes.** M1 raisonnement par récurrence · M2 étudier monotonie et bornitude · M3 reconnaître/exploiter une suite arithmético-géométrique (suite auxiliaire) · M4 étudier $u_{n+1}=f(u_n)$ (point fixe, convergence) · M5 limites par comparaison/gendarmes · M6 déterminer le plus petit $n$ tel que $u_n\ge 10^p$ ou $|u_n-\ell|\le 10^{-p}$.
**Exercices.** Calculs de termes/sommes ; récurrence ; convergence. **Problème Bac** : suite récurrente + suite auxiliaire + limite.

## Chapitre 4 — Fonction logarithme népérien
**Cours.** Définition (primitive de $1/x$), propriétés algébriques, dérivée de $\ln u$, variations, limites de référence, courbe ; logarithme décimal $\log$ ; logarithme de base $a$.
**Méthodes.** M1 résoudre équations/inéquations avec $\ln$ (conditions d'existence) · M2 changement de variable ($X=\ln x$) · M3 dériver et étudier une fonction avec $\ln$ · M4 limites de référence et croissances · M5 primitives du type $u'/u$.
**Exercices.** Équations/inéquations ; études de fonctions avec $\ln$ ; applications (pH, échelles log). **Problème Bac** : étude de fonction comportant $\ln$ + aire.

## Chapitre 5 — Fonctions exponentielles et puissances
**Cours.** Exponentielle népérienne (réciproque de $\ln$), propriétés, dérivée de $e^u$, limites de référence, courbe ; exponentielle de base $a$ ; fonctions puissances $x^\alpha$ ; **croissances comparées** ($\ln$, $e^x$, $x^\alpha$).
**Méthodes.** M1 résoudre équations/inéquations avec $\exp$ (et changement de variable, type 2nd degré) · M2 dériver/étudier une fonction avec $\exp$ · M3 lever une indétermination par croissances comparées · M4 étudier une fonction puissance / dérivation logarithmique $u^v$.
**Exercices.** Équations ; études ; croissances comparées ; modèles (croissance, désintégration). **Problème Bac** : fonction avec $\exp$ + tangentes + position.

## Chapitre 6 — Primitives
**Cours.** Définition (primitive d'une fonction continue) ; ensemble des primitives ; primitives des fonctions de référence ; formes $u'u^n$, $u'/u$, $u'e^u$, $u'/\sqrt u$, trigonométriques.
**Méthodes.** M1 reconnaître une forme et primitiver · M2 primitive vérifiant une condition initiale · M3 linéariser avant de primitiver (trigonométrie).
**Exercices.** Calculs de primitives ; conditions initiales. **Problème Bac** : primitive + lien avec une étude.

## Chapitre 7 — Calcul intégral
**Cours.** Intégrale d'une fonction continue ; primitive et intégrale ; relation de Chasles, linéarité, positivité, ordre ; valeur moyenne, inégalité de la moyenne ; **intégration par parties** ; aires et volumes de révolution.
**Méthodes.** M1 calculer une intégrale (primitive) · M2 intégration par parties (et IPP répétée) · M3 calcul d'aire entre courbes · M4 volume de révolution · M5 encadrer/étudier une intégrale ; suite d'intégrales $I_n$.
**Exercices.** Calculs ; IPP ; aires/volumes ; suites d'intégrales. **Problème Bac** : $I_n$ par IPP + limite + aire.

## Chapitre 8 — Équations différentielles
**Cours.** Équations $y'=ay$ ; $y'=ay+b$ ; $y''=0$ ; $y''=\omega^2 y$ ; $y''=-\omega^2 y$ ; solution générale et solution vérifiant des conditions initiales.
**Méthodes.** M1 résoudre chaque type · M2 trouver une solution particulière (second membre constant) · M3 déterminer la solution vérifiant des conditions initiales · M4 vérifier/justifier qu'une fonction est solution.
**Exercices.** Résolutions ; conditions initiales. **Problème Bac** : modélisation (physique/croissance) par une EDO + étude de la solution.

---

# PARTIE II — ALGÈBRE & ARITHMÉTIQUE

## Chapitre 9 — Nombres complexes
**Cours.** Forme algébrique (partie réelle/imaginaire, conjugué, module) ; opérations ; équation du second degré dans $\C$ ; forme trigonométrique et exponentielle, argument ; **formules de Moivre et d'Euler** ; racines carrées, racines $n$-ièmes, racines de l'unité ; interprétation géométrique (affixe, module = distance, argument = angle).
**Méthodes.** M1 calculs et résolution d'équations (2nd degré, à coefficients complexes) · M2 passer algébrique ↔ trigonométrique/exponentielle · M3 Moivre (puissances) et Euler (linéarisation) · M4 racines $n$-ièmes (placement sur le cercle) · M5 caractérisations géométriques (cercle, droite, alignement).
**Exercices.** Calculs, équations, formes, racines. **Problème Bac** : complexes + lieux/configurations (préparation au ch. 17).

## Chapitre 10 — Arithmétique I : divisibilité, congruences, numération
**Cours.** Divisibilité dans $\Z$ ; division euclidienne ; congruences modulo $n$ (propriétés, compatibilité) ; nombres premiers ; critères de divisibilité (2,3,5,9,10,11) ; **décomposition en facteurs premiers** (existence/unicité) ; **systèmes de numération** (changements de base).
**Méthodes.** M1 utiliser les congruences (reste d'une division, chiffre des unités) · M2 raisonnement par récurrence / disjonction de cas / absurde · M3 décomposer en facteurs premiers · M4 écrire un nombre dans une autre base et inversement.
**Exercices.** Divisibilité, congruences, critères, bases. **Problème Bac** : congruences + récurrence (divisibilité d'une expression).

## Chapitre 11 — Arithmétique II : PGCD, PPCM, Bézout, Gauss
**Cours.** Multiples/diviseurs communs ; PGCD, PPCM ; nombres premiers entre eux ; **algorithme d'Euclide** ; **théorème de Bézout** et identité ; **théorème de Gauss** ; relation $\mathrm{PGCD}\times\mathrm{PPCM}=|ab|$.
**Méthodes.** M1 calculer PGCD/PPCM (Euclide, décomposition) · M2 identité de Bézout (Euclide étendu) · M3 résoudre $ax+by=c$ dans $\Z^2$ · M4 résoudre $ax\equiv b\ [n]$ · M5 appliquer Gauss (divisibilité, problèmes concrets).
**Exercices.** PGCD/PPCM, Bézout, équations diophantiennes. **Problème Bac** : équation diophantienne + interprétation (cryptographie simple, restes chinois).

## Chapitre 12 — Dénombrement
**Cours.** Principe additif et multiplicatif ; $p$-listes ; arrangements ; permutations ; combinaisons et propriétés ($\binom np$, symétrie, Pascal) ; **formule du binôme de Newton**.
**Méthodes.** M1 choisir le bon modèle (liste/arrangement/combinaison) · M2 dénombrer avec contraintes · M3 utiliser le binôme et les identités combinatoires.
**Exercices.** Tirages, anagrammes, comités, binôme. **Problème Bac** : dénombrement (préparation aux probabilités, ch. 20).

---

# PARTIE III — GÉOMÉTRIE

## Chapitre 13 — Barycentre et lignes de niveau
**Cours.** Barycentre/isobarycentre de $n$ points pondérés ; homogénéité ; **associativité (barycentres partiels)** ; coordonnées du barycentre ; réduction de $\sum\alpha_i\vec{MA_i}$ et $\sum\alpha_i MA_i^2$ ; lignes de niveau ($M\mapsto\sum\alpha_i MA_i^2$, $M\mapsto MA/MB$, $M\mapsto$ angle).
**Méthodes.** M1 réduire une somme vectorielle pondérée · M2 réduire $\sum\alpha_i MA_i^2$ (formule de Leibniz) · M3 déterminer/construire une ligne de niveau · M4 prouver alignement, concours, lieux.
**Exercices.** Barycentres, réductions, lignes de niveau. **Problème Bac** : configuration + lignes de niveau.

## Chapitre 14 — Produit scalaire et géométrie de l'espace
**Cours.** Produit scalaire (plan et espace), expressions, orthogonalité ; **produit vectoriel** (définition, propriétés, aire) ; repérage dans l'espace ; équation cartésienne d'un plan (vecteur normal), représentation paramétrique d'une droite ; positions relatives ; distance d'un point à un plan/droite ; **équation d'une sphère**, plan tangent.
**Méthodes.** M1 produit scalaire (calculs, orthogonalité, angles) · M2 produit vectoriel (normale, aire, volume) · M3 équations de plans et droites · M4 positions relatives et intersections · M5 distances · M6 sphères (équation, intersection avec un plan).
**Exercices.** Plans, droites, distances, sphères. **Problème Bac** : configuration dans l'espace (tétraèdre, intersections).

## Chapitre 15 — Isométries du plan (et de l'espace)
**Cours.** Isométries ; déplacements et antidéplacements ; propriétés conservées (distances, produit scalaire, barycentre, angles, alignement) ; translations, rotations, symétries (centrale, orthogonale, glissée) ; décomposition en symétries ; classification par points invariants. *(Volet espace : symétries, rotations.)*
**Méthodes.** M1 classer une isométrie (points invariants) · M2 déterminer la nature d'une composée · M3 décomposer en symétries orthogonales · M4 exploiter les conservations (problèmes de construction/démonstration).
**Exercices.** Nature, composées, constructions. **Problème Bac** : composées d'isométries + configuration.

## Chapitre 16 — Similitudes directes du plan
**Cours.** Définition, **forme réduite**, éléments caractéristiques (centre, rapport, angle), réciproque ; conservations (angles orientés, parallélisme, rapports) ; composée homothétie ∘ déplacement ; figures semblables ; écriture complexe $z'=az+b$.
**Méthodes.** M1 déterminer une similitude (centre/rapport/angle ; par deux points et leurs images) · M2 forme réduite ↔ écriture complexe · M3 construire l'image d'une figure · M4 calculer distances/aires sous similitude.
**Exercices.** Détermination, écriture complexe, constructions. **Problème Bac** : similitude + lieu géométrique.

## Chapitre 17 — Nombres complexes et transformations du plan
**Cours.** Écritures complexes des transformations (translation, symétrie centrale, symétries orthogonales par rapport aux axes, homothétie, rotation, similitude directe) ; caractérisations complexes (alignement, triangle particulier, cocyclicité, cercle, droite).
**Méthodes.** M1 reconnaître une transformation par son écriture complexe · M2 traduire une transformation en écriture complexe · M3 déterminer des lieux géométriques (complexes) · M4 prouver des propriétés (angle droit, points cocycliques).
**Exercices.** Reconnaissance, lieux, configurations. **Problème Bac** : complexes ↔ géométrie (sujet type C).

## Chapitre 18 — Coniques
**Cours.** Définition par foyer–directrice–excentricité ; axe focal, sommets ; équations réduites de la **parabole**, l'**ellipse**, l'**hyperbole** ; éléments (foyers, directrices, asymptotes, paramètre) ; reconnaissance d'une conique à partir de $ax^2+by^2+2cx+2dy+e=0$.
**Méthodes.** M1 reconnaître une conique et déterminer ses éléments · M2 équation réduite (changement de repère, mise sous forme canonique) · M3 tracer une conique · M4 propriétés focales / tangentes.
**Exercices.** Identification, éléments, tracés. **Problème Bac** : conique + lieu géométrique.

---

# PARTIE IV — ORGANISATION DES DONNÉES & PROBABILITÉS

## Chapitre 19 — Statistiques à deux variables
**Cours.** Série double, nuage de points, point moyen, séries marginales ; **covariance**, **coefficient de corrélation linéaire** ; **droites de régression** ($y$ en $x$ et $x$ en $y$, moindres carrés).
**Méthodes.** M1 représenter un nuage + point moyen · M2 calculer covariance et corrélation · M3 déterminer une droite d'ajustement · M4 estimer/prévoir ; ajustement par changement de variable (exponentiel/log).
**Exercices.** Nuages, corrélation, régression, prévision. **Problème Bac** : ajustement affine + estimation.

## Chapitre 20 — Probabilités et variables aléatoires
**Cours.** Vocabulaire, équiprobabilité ; **probabilité conditionnelle**, indépendance ; **formule des probabilités totales**, arbre pondéré, système complet ; variable aléatoire, loi, fonction de répartition ; **espérance, variance, écart-type** ; **schéma de Bernoulli, loi binomiale** $B(n,p)$ ($E=np$, $V=np(1-p)$).
**Méthodes.** M1 calculer une probabilité (dénombrement, ch. 12) · M2 probabilité conditionnelle + arbre + probabilités totales · M3 établir la loi d'une v.a. et sa fonction de répartition · M4 calculer $E$, $V$, $\sigma$ · M5 reconnaître et utiliser la loi binomiale.
**Exercices.** Conditionnelles, arbres, v.a., binomiale. **Problème Bac** : épreuve composée + v.a. + binomiale.

---

# PARTIE V — SPÉCIFIQUE CAMEROUN (réforme / GPM)

## Chapitre 21 — Algèbre linéaire : espaces vectoriels et applications linéaires
**Cours.** Espace vectoriel réel (axiomes), sous-espaces vectoriels ; combinaison linéaire, famille génératrice, famille libre/liée, **base, dimension** ($\R^2$, $\R^3$) ; applications linéaires, noyau, image ; propriétés.
**Méthodes.** M1 montrer qu'un ensemble est un sous-espace vectoriel · M2 étudier liberté/génération, extraire une base · M3 montrer qu'une application est linéaire · M4 déterminer noyau et image.
**Exercices.** Sous-espaces, bases, applications linéaires. **Problème Bac** : application linéaire de $\R^2$/$\R^3$ (lien avec matrices et géométrie).

## Chapitre 22 — Matrices
**Cours.** Matrices, types, opérations (somme, produit par un scalaire, **produit matriciel**) ; matrice identité, matrice inverse ($2\times2$, $3\times3$) ; déterminant ; **écriture matricielle d'un système linéaire** ; matrice d'une application linéaire / d'une transformation.
**Méthodes.** M1 opérations et produit matriciel · M2 inverse et déterminant · M3 résoudre un système par les matrices · M4 puissances $A^n$ (récurrence, diagonalisation simple) · M5 matrice d'une transformation du plan.
**Exercices.** Calcul matriciel, inverses, systèmes, $A^n$. **Problème Bac** : système + suite définie matriciellement.

## Chapitre 23 — Théorie des graphes
**Cours.** Graphe non orienté ; sommets, arêtes, ordre, **degré** ; graphe simple/complet/biparti ; **matrice d'adjacence** ; chaînes, cycles, **connexité** ; (chaîne/cycle eulérien, coloration — selon le programme).
**Méthodes.** M1 modéliser une situation par un graphe · M2 lire/écrire la matrice d'adjacence · M3 étudier la connexité, chercher une chaîne/un cycle · M4 utiliser les puissances de la matrice d'adjacence (nombre de chemins).
**Exercices.** Modélisation, degrés, matrice d'adjacence, connexité. **Problème Bac** : situation concrète (réseau, planning) modélisée par un graphe.

---

## Annexes prévues
- **Formulaire** (limites/dérivées/primitives de référence, identités trigonométriques, complexes, probabilités).
- **Alphabet grec**, symboles et notations.
- Index des **méthodes** par chapitre.

## Format de production
- Un seul PDF (classe `book`), compilé par **tectonic** (XeLaTeX), design OnBuch
  (couverture Léo, gros numéros de chapitre orange, encadrés Définition/Théorème/
  Propriété/Méthode/Exemple/À retenir/Exercice/Corrigé). Préambule prêt :
  `tools/fascicule-mathsC/` (à finaliser).
- Réinjection du **stock d'exercices** déjà produits (banque OnBuch) dans les parties C/D.
