# Guide de rédaction — Fascicule « Algorithmique & Programmation » Tle TI (OnBuch)

Tu rédiges **UN chapitre complet** (cours + code commenté + exercices corrigés) d'un
fascicule LaTeX, conforme au **programme officiel MINESEC Terminale TI**. Langue :
**français**. Compilé avec **tectonic** (XeLaTeX).

## AVANT d'écrire
Lis `preamble.tex` (macros/environnements disponibles) et `ch03_php_intro.tex`
(LE modèle de style à imiter exactement : structure, ton, dosage cours/code/exos).

## Sortie
Un fichier `chXX_*.tex` commençant directement par `\chapter{Titre}`.
**Pas** de `\documentclass`, `\begin{document}` ni ```` ``` ````. Préambule déjà chargé.

## Structure imposée du chapitre
1. `\chapter{...}` puis un encadré `\begin{synthese}[Au programme]...\end{synthese}` (2-3 lignes).
2. Le **cours** en `\section{}` / `\subsection{}` : définitions, syntaxe, exemples de code
   **commentés**, méthodes. Vise **8 à 14 pages**.
3. `\section{Exercices}` avec `\rubrique{Application}` / `\rubrique{Entraînement}` :
   **8 à 14 exercices** `\exo{titre}\diff{1|2|3}`, du simple au difficile.
4. `\section{Corrigés}` : corrigés **détaillés** (`\corrige{de l'exercice n}`) avec le
   code solution. Corrige au moins les exercices d'Application.
5. Terminer par un encadré `\begin{aretenir}...\end{aretenir}` (le réflexe clé).

## Environnements & macros (préambule)
- Boîtes : `definition`, `propriete[...]`, `syntaxe`, `remarque`, `attention`, `exemple`,
  `methode`, `aretenir`, `synthese[Titre]`.
- **Code** (coloration syntaxique automatique, contenu VERBATIM) :
  `\begin{codephp}...\end{codephp}`, `\begin{codec}...\end{codec}`,
  `\begin{codehtml}...\end{codehtml}`, `\begin{codesql}...\end{codesql}`,
  `\begin{codejs}...\end{codejs}`. Le code à l'intérieur est littéral : écris `$`, `%`,
  `_`, `{`, `}`, `&` tels quels. **N'écris jamais** `\end{codephp}` dans le code.
- Code **inline** dans le texte : `\code{...}` (ex. `\code{echo}`, `\code{$_POST}`).
  ⚠️ dans `\code{...}` (mode texte), échappe les caractères spéciaux LaTeX :
  `\code{\$nom}`, `\code{\%}`, `\code{\_GET}`, `\code{\&\&}`, `\code{\{}`.
- Exercices : `\exo{titre}` + `\diff{1}`/`\diff{2}`/`\diff{3}` (étoiles) ; `\rubrique{Thème}` ;
  `\corrige{de l'exercice n}` ; `\fig{légende}` (sous un code/figure).
- Listes : `\begin{enumerate}[label=\arabic*)]` ou `[label=\alph*)]`.

## Exigences pédagogiques
- **Code EXACT et exécutable** : chaque exemple doit fonctionner (syntaxe PHP/C/SQL/HTML
  réelle). Vérifie mentalement chaque programme.
- Contexte **camerounais** dans les énoncés (lycées, villes, francs CFA, gestion d'élèves,
  de produits…) quand c'est naturel.
- Programme **Terminale TI uniquement** (web dynamique PHP/MySQL, et C procédural). Pas de
  notions hors-programme (pas de POO en C, pas de frameworks).
- Beaucoup d'exemples concrets et courts ; commente le code en français.

## Compilation (OBLIGATOIRE)
Crée un wrapper `wrapXX.tex` :
```
\documentclass[11pt,a4paper,openany]{book}
\input{preamble.tex}
\begin{document}
\include{chXX_nom}
\end{document}
```
Compile `tectonic wrapXX.tex`, vise **0 erreur**, corrige si besoin, PUIS **supprime**
le wrapper et ses fichiers temporaires. Ne touche à AUCUN autre fichier.

## Pièges LaTeX
- `\corrige` (pas `\corrigé`). Dans le texte hors code, échappe `& % $ _ # { }`.
- Le code va dans un environnement `codexxx` (verbatim) — n'y mets pas de commande LaTeX.
- Tableaux : `\begin{tabular}{@{}lll@{}}` + `\toprule/\midrule/\bottomrule`.
