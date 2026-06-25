# Guide — RÉDIGER un chapitre du fascicule d'Informatique Tle C/D/E (OnBuch)

Tu rédiges UN chapitre du fascicule d'Informatique des Terminales scientifiques (C, D,
E — Baccalauréat, Cameroun, programme MINESEC). **Philosophie de ce livre** : un cours
réduit à des **résumés simples et clairs**, et SURTOUT **énormément d'exercices type
examen, TOUS corrigés**. Langue : **français**.

## Sortie attendue
- **UNIQUEMENT du LaTeX**, à partir de `\chapter{...}`. NI `\documentclass`, NI
  `\usepackage`, NI `\begin{document}`. Pas de ```` ``` ````.
- Préambule déjà chargé (tcolorbox, listings, tikz…). N'ajoute AUCUN package.

## Structure IMPOSÉE du chapitre
1. `\chapter{Titre exact}` + une phrase d'intro `\textit{...}`.
2. `\section{L'essentiel du cours}` — un **résumé COURT et simple** (pas un cours
   développé) : l'élève doit comprendre vite. Utilise :
   - `\begin{definition}[Nom]...\end{definition}`, `\begin{propriete}...\end{propriete}`,
   - `\begin{aretenir}...\end{aretenir}` (points clés), `\begin{exemple}...\end{exemple}`,
   - des **listes à puces** pour les notions, et des **exemples de code** quand utile.
   Vise 1 à 2 pages maximum de cours.
3. `\section{Exercices}` — **BEAUCOUP d'exercices** (vise **20 à 30**), classés par
   `\rubrique{Thème}`, de difficulté croissante `\exo{}\diff{n}` ($n=1,2,3$). Inclure des
   **exercices type Baccalauréat** (`\sujetbac[...]`). Privilégie les exercices réalistes
   et variés (voir « Types d'exercices » plus bas).
4. `\section{Corrigés}` — le corrigé **DÉTAILLÉ de CHAQUE exercice** de la section 3
   (aucun exercice sans corrigé). Utilise `\corrige{de l'exercice n}`.

## Code : environnements dédiés (IMPORTANT)
- **Pseudo-code / algorithmique** (français) :
  ```
  \begin{algo}
  Algorithme Nom
  Variables ...
  Début
    ...
  Fin
  \end{algo}
  ```
- **Langage C** : `\begin{ccode} ... \end{ccode}`
- **SQL** : `\begin{sqlcode} ... \end{sqlcode}`
- Ne mets PAS de code dans une formule math. Ne mets jamais de code « brut » sans un de
  ces environnements.

## Types d'exercices attendus (selon le chapitre)
- **Codage / numération** : conversions binaire↔octal↔décimal↔hexadécimal, opérations
  en binaire, codage des entiers (complément à 2), des caractères (ASCII), capacités mémoire (octets, Kio/Mio).
- **Architecture / systèmes** : QCM, rôle des composants, calculs (fréquence, capacité,
  débit), commandes système.
- **Bases de données** : dessiner/lire un **MCD** (entités, associations, cardinalités),
  passage MCD → modèle relationnel, **requêtes SQL** (SELECT/INSERT/UPDATE/DELETE, jointures, WHERE, ORDER BY, agrégats).
- **Tableur** : écrire des **formules** (=SOMME, =SI, références relatives/absolues), résultats de calculs.
- **Algorithmique** : écrire un algorithme en pseudo-code (boucles, conditions, tableaux),
  dérouler/tracer un algorithme (tableau de valeurs), corriger un algorithme.
- **Langage C** : écrire/compléter/corriger un programme C, prédire la sortie.
- **Réseaux** : topologies, matériels, **adressage IP** (classes, masque, nombre d'hôtes),
  calculs de débit, schémas de réseau.

## Règles ABSOLUES
- **Exact** : code qui compile mentalement, conversions justes, requêtes SQL correctes,
  MCD cohérents. Vérifie tous les résultats numériques des corrigés.
- **Programme Tle C/D/E Cameroun**. Contexte camerounais bienvenu (noms, écoles, FCFA).
- LaTeX **pur et compilable**, AUCUN package en plus.
- Pour un schéma trop complexe (MCD élaboré, topologie réseau dessinée), préfère un
  **tableau** ou une description claire ; en dernier recours `\imgph{cle}{description}`.
- `\corrige{}` pour CHAQUE exercice (le livre se distingue par ses corrigés complets).
- Sortie = **LaTeX du chapitre seul** (cours résumé → exercices → corrigés).
