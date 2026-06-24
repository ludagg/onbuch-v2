# Guide de rédaction d'un chapitre — Fascicule Maths Terminale C (OnBuch)

Tu rédiges UN chapitre du fascicule de mathématiques Terminale C (Bac scientifique,
Cameroun, programme MINESEC/APC). Il doit être de qualité « livre de référence » :
explications développées, figures, méthodes, beaucoup d'exercices classés, corrigés.

## Contexte fichiers (déjà présents dans /tmp/book)
- `preamble.tex` : préambule (NE PAS modifier). Définit tous les environnements ci-dessous.
- `logo.png` : logo (pour la compilation).
- Exemples de chapitres déjà validés à IMITER : `ch_derivation.tex`, `ch_complexes.tex`,
  `ch_arith1.tex`. LIS-EN AU MOINS UN avant d'écrire, pour copier exactement le style.
- `PLAN.md` (dans le repo `tools/fascicule-mathsC/`) : le plan détaillé de TON chapitre
  (notions, méthodes, types d'exercices). Respecte-le.

## Structure imposée du chapitre (dans cet ordre)
1. `\chapter{Titre exact}` puis un court paragraphe d'introduction en `\textit{...}` (3-4 lignes).
2. `\section{...}` pour chaque grande partie du cours. Dedans, les notions en encadrés :
   - `\begin{definition}[Nom]...\end{definition}` (orange)
   - `\begin{theoreme}[Nom]...\end{theoreme}` et `\begin{propriete}[Nom]...\end{propriete}` (vert)
   - `\begin{remarque}...\end{remarque}`, `\begin{exemple}...\end{exemple}`
   - `\begin{aretenir}...\end{aretenir}` (encadré « À retenir », à utiliser 1-2 fois)
3. **AU MOINS 2 FIGURES** pertinentes via :
   `\begin{illus}` + un `tikzpicture` (ou `axis` pgfplots) + `\fig{Figure — légende.}` + `\end{illus}`.
   Figures sobres, aux couleurs `onbo` (orange), `onbgreen` (vert), `onbblue`, `onbmuted`.
4. `\section{Méthodes \& savoir-faire}` : plusieurs `\methode{Titre de la méthode}` (3 à 6),
   chacune suivie d'une courte explication et d'un `\begin{exemple}...\end{exemple}` résolu.
5. `\section{Exercices}` : exercices CLASSÉS. Utilise `\rubrique{Thème}` pour chaque catégorie
   (3-5 rubriques, dont une « Problème type Baccalauréat »). Chaque exercice :
   `\exo{}\diff{n} énoncé...` où `n` = 1, 2 ou 3 (difficulté ★ ★★ ★★★). Vise 8 à 12 exercices.
6. `\section{Corrigés}` : un `\corrige{de l'exercice 1}` (puis 2, 3…, et `\corrige{du problème}`)
   par exercice, avec solution détaillée et justifiée.

## Commandes & raccourcis disponibles (préambule)
- Maths : `\R \N \Z \Q \C` (ensembles), `\dd` (d droit pour intégrales), `\Card`.
- Listes : `\begin{enumerate}[label=\alph*)]` ou `[label=\arabic*)]`.
- Couleurs figures : `onbo, onbo2, onbgreen, onbink, onbblue, onbmuted, onbline, onbsoft`.
- tikz libs chargées : `arrows.meta, positioning, calc, decorations.pathreplacing, angles, quotes`.
  pgfplots `compat=1.18` (utilise `\begin{axis}[...]\addplot[...]{...};\end{axis}` dans un tikzpicture).

## Règles ABSOLUES
- **Mathématiquement EXACT** : vérifie tous les calculs des exemples et corrigés.
- **Programme Tle C Cameroun** (g hors-sujet ici, c'est des maths). Contexte camerounais bienvenu
  dans les énoncés (villes, situations) quand c'est naturel.
- LaTeX **pur et compilable**. Pas de package en plus (tout est dans preamble.tex).
- Figures : garde-les SIMPLES et compilables (teste !). Pas de bibliothèque tikz non chargée.
- N'écris NI `\documentclass` NI `\begin{document}` : seulement le contenu du chapitre
  (à partir de `\chapter{...}`).

## Procédure OBLIGATOIRE (tu DOIS compiler avant de rendre)
1. `mkdir -p /tmp/book/agents/<CLE>` ; copie `preamble.tex` et `logo.png` de `/tmp/book` dedans.
2. Écris ton chapitre dans `/tmp/book/agents/<CLE>/chap.tex`.
3. Crée un fichier test `main.tex` :
   ```
   \input{preamble.tex}
   \usepackage{graphicx}
   \begin{document}\mainmatter
   \include{chap}
   \end{document}
   ```
4. Compile : `cd /tmp/book/agents/<CLE> && tectonic -X compile --outdir . main.tex`.
   S'il y a une ERREUR, CORRIGE le `.tex` et recompile JUSQU'À obtenir un PDF sans erreur.
5. Quand ça compile proprement, **copie le chapitre final** vers `/tmp/book/<NOM_FICHIER_FINAL>`.
6. Réponds en confirmant : nom du fichier final, nombre de pages du PDF, nombre d'exercices,
   et liste des figures. Ne renvoie PAS tout le LaTeX (juste le récap).
