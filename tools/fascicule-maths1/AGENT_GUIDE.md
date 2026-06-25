# Guide — RÉDIGER LES EXERCICES d'un chapitre du fascicule de Maths Première C (OnBuch)

Tu rédiges **UNIQUEMENT les exercices et leurs corrigés** d'un chapitre de Mathématiques
de Première C (Cameroun, programme MINESEC, préparation au Probatoire et au Baccalauréat).
Le COURS est rédigé séparément (par un professeur) — tu n'écris PAS de cours. Langue : **français**.

## Sortie attendue
- **UNIQUEMENT du LaTeX**, commençant directement par `\section{Exercices d'application}`.
  NI `\chapter`, NI `\documentclass`, NI `\usepackage`, NI `\begin{document}`. Pas de ```` ``` ````.
- Préambule déjà chargé (amsmath, tikz, pgfplots, tcolorbox…). N'ajoute AUCUN package.

## Structure imposée (dans cet ordre)
1. `\section{Exercices d'application}` — classés par `\rubrique{Thème}` (3 à 6 rubriques),
   **12 à 18** exercices `\exo{}\diff{n}` ($n=1,2,3$ → ★ à ★★★), du plus simple au plus difficile.
2. `\section{Exercices d'entraînement}` — **un GROS banc** : **18 à 30** exercices `\exo{}\diff{n}`,
   classés par `\rubrique{}`, énoncés SEULEMENT (pas de corrigé pour cette section).
3. `\section{Problèmes type Probatoire/Bac}` — **2 à 4** problèmes via `\sujetbac[contexte]` puis
   l'énoncé (souvent en `\begin{enumerate}[label=\arabic*)]` à parties).
4. `\section{Corrigés}` — corrigés **détaillés** des exercices d'application (section 1) ET des
   problèmes (section 3), via `\corrige{de l'exercice n}` / `\corrige{du problème n}`.
   **NE corrige PAS** les exercices d'entraînement (section 2).

## Macros disponibles (préambule)
- `\exo{}`, `\diff{1|2|3}`, `\rubrique{}`, `\sujetbac[..]`, `\corrige{}`, `\methode{}`.
- Boîtes : `exemple`, `remarque` (utilisables dans les corrigés si besoin).
- Maths : `\R \N \Z \Q \C` (ensembles), `\dd` (d droit), `\Card`.
- Listes : `\begin{enumerate}[label=\alph*)]` ou `[label=\arabic*)]`.
- Figures : `\begin{illus}` + `tikzpicture`/`axis` (pgfplots) + `\fig{légende}` (APRÈS la figure) + `\end{illus}`.
  ⚠️ pgfplots : libs `intersections`/`fillbetween` NON chargées → pour remplir sous une courbe,
  `\addplot[...] {...} \closedcycle;`.

## Exigences
- **Mathématiquement EXACT** : vérifie TOUS les calculs des corrigés ; les énoncés doivent
  avoir des données cohérentes et des résultats « propres » quand c'est possible.
- **Programme Première C Cameroun** uniquement (pas de notions de Terminale). Contexte camerounais
  bienvenu dans les énoncés (villes, francs CFA, situations réelles) quand c'est naturel.
- Progression réelle de la difficulté ; énoncés variés et non répétitifs.
- Les corrigés de la section 4 suivent EXACTEMENT la numérotation des exercices d'application (section 1).
- Sortie = **LaTeX des exercices seuls** (application → entraînement → problèmes → corrigés). Rien d'autre.
