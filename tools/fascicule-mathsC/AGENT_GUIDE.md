# Guide V2 — ENRICHIR un chapitre du fascicule Maths Tle C (OnBuch)

Tu **enrichis massivement** UN chapitre déjà existant du fascicule de mathématiques
Terminale C (Bac scientifique, Cameroun, programme MINESEC/APC). Objectif :
qualité « **grand livre de référence** » que les élèves adorent — cours très
développé, figures, résumés, méthodes, et **beaucoup** d'exercices.

## Point de départ
- Le chapitre actuel existe déjà : `/tmp/book/<FICHIER>.tex` (on te donne le nom).
  **LIS-LE EN ENTIER d'abord.** Tu dois GARDER tout son bon contenu (cours, figures,
  exemples, exercices déjà présents) et **l'AUGMENTER fortement** — ne supprime
  rien de correct, ajoute beaucoup.
- `preamble.tex` (NE PAS modifier) définit tous les environnements ci-dessous.
- Chapitres de référence à imiter pour le style : `ch_derivation.tex`, `ch_complexes.tex`.

## Cible quantitative (ce chapitre doit grossir nettement)
- **Cours** : développé, chaque notion expliquée + justifiée/démontrée quand c'est au programme,
  avec de l'intuition et des exemples. Vise plusieurs `\section`.
- **Figures** : **4 à 6** figures pertinentes (TikZ / pgfplots), sobres, aux couleurs OnBuch.
- **Méthodes** : **6 à 9** `\methode{}`, chacune avec une explication claire + un `\begin{exemple}` résolu.
- **Exercices d'application CORRIGÉS** : **14 à 20**, classés par `\rubrique{}`, avec corrigés détaillés.
- **Exercices d'entraînement NON corrigés** : **20 à 35** (un GROS banc), classés par `\rubrique{}`,
  énoncés seulement (pas de corrigé) — c'est voulu.
- **Sujets type Baccalauréat** : **2 à 4**, complets et **corrigés** en détail.
- Une **fiche de révision** (résumé) via l'environnement `\begin{synthese}...\end{synthese}`.

## Structure IMPOSÉE du chapitre (dans cet ordre)
1. `\chapter{Titre exact}` (garde le titre existant) + court paragraphe d'intro `\textit{...}`.
2. **Le cours** : plusieurs `\section{...}`. Dedans :
   - `\begin{definition}[Nom]...\end{definition}` (orange)
   - `\begin{theoreme}[Nom]...\end{theoreme}`, `\begin{propriete}[Nom]...\end{propriete}` (vert)
   - `\begin{remarque}...\end{remarque}`, `\begin{exemple}...\end{exemple}` (utilise-les souvent)
   - `\begin{aretenir}...\end{aretenir}` (encadré « À retenir », 2-3 fois)
   - **4 à 6 figures** : `\begin{illus}` + `tikzpicture`/`axis` + `\fig{Figure — légende.}` + `\end{illus}`.
   - Développe les PREUVES / justifications quand elles sont au programme (sobrement).
3. `\section{L'essentiel à retenir}` : une **fiche de révision** condensée :
   `\begin{synthese}` ... (formules clés, théorèmes, plan de résolution, pièges) ... `\end{synthese}`.
4. `\section{Méthodes \& savoir-faire}` : **6 à 9** `\methode{Titre}` + explication + `\begin{exemple}` résolu.
5. `\section{Exercices d'application}` : **classés** par `\rubrique{Thème}` (4-6 rubriques).
   Chaque exercice : `\exo{}\diff{n} énoncé...` (n = 1/2/3 → ★/★★/★★★). **14 à 20** exercices.
6. `\section{Exercices d'entraînement}` : **GROS banc NON corrigé**, classé par `\rubrique{}`.
   `\exo{}\diff{n} énoncé...` ; **20 à 35** exercices ; AUCUN corrigé pour cette section.
7. `\section{Sujets type Baccalauréat}` : **2 à 4** sujets, chacun introduit par
   `\sujetbac[contexte court]` puis l'énoncé (souvent en `\begin{enumerate}[label=\arabic*)]` à parties).
8. `\section{Corrigés}` : corrigés détaillés **des exercices d'application** (section 5)
   et **des sujets type Bac** (section 7). Utilise `\corrige{de l'exercice n}` et
   `\corrige{du sujet n}`. **NE corrige PAS** les exercices d'entraînement (section 6).

## Commandes & environnements (préambule — déjà disponibles)
- Boîtes : `definition[Nom]`, `theoreme[Nom]`, `propriete[Nom]`, `remarque`, `exemple`, `aretenir`,
  `synthese` (fiche de révision, fond sombre), `illus` (cadre figure).
- Macros : `\methode{}`, `\rubrique{}`, `\exo{}`, `\diff{1|2|3}`, `\corrige{}`, `\sujetbac[..]`, `\fig{}`.
- Maths : `\R \N \Z \Q \C` (ensembles), `\dd` (d droit, intégrales), `\Card`.
- Listes : `\begin{enumerate}[label=\alph*)]` ou `[label=\arabic*)]`.
- Couleurs figures : `onbo, onbo2, onbgreen, onbink, onbblue, onbmuted, onbline, onbsoft`.
- tikz libs chargées : `arrows.meta, positioning, calc, decorations.pathreplacing, angles, quotes`.
  pgfplots `compat=1.18`.

## Règles ABSOLUES
- **Mathématiquement EXACT** : vérifie TOUS les calculs des exemples et corrigés.
- **Programme Tle C Cameroun**. Contexte camerounais bienvenu dans les énoncés (villes, francs CFA,
  situations réelles) quand c'est naturel — sans en faire trop.
- LaTeX **pur et compilable**, AUCUN package en plus (tout est dans preamble.tex).
- **Figures compilables** : garde-les simples. ⚠️ PIÈGE CONNU : les libs tikz `intersections` et
  pgfplots `fillbetween` NE SONT PAS chargées. Pour remplir sous une courbe, utilise
  `\addplot[...] {...} \closedcycle;` (PAS `fill between`). Ne charge AUCUNE lib en plus.
- N'écris NI `\documentclass` NI `\begin{document}` : seulement le contenu (à partir de `\chapter{...}`).
- Les corrigés de la section 8 doivent correspondre EXACTEMENT à la numérotation des exercices
  d'application (l'ordre des `\exo` de la section 5).

## Procédure OBLIGATOIRE (tu DOIS compiler avant de rendre)
1. `mkdir -p /tmp/book/agents/<CLE>` ; copie `preamble.tex` et `logo.png` de `/tmp/book` dedans.
2. Écris le chapitre enrichi dans `/tmp/book/agents/<CLE>/chap.tex`.
3. Fichier test `main.tex` :
   ```
   \input{preamble.tex}
   \usepackage{graphicx}
   \begin{document}\mainmatter
   \include{chap}
   \end{document}
   ```
4. Compile : `cd /tmp/book/agents/<CLE> && tectonic -X compile --outdir . main.tex`.
   S'il y a une ERREUR, CORRIGE le `.tex` et recompile JUSQU'À un PDF sans erreur.
   Vérifie aussi qu'aucune figure n'est cassée (pas d'« Extra alignment », « Missing $ », etc.).
5. Quand ça compile proprement, **copie le chapitre final** vers `/tmp/book/<FICHIER>.tex` (écrase l'ancien).
6. Réponds par un récap court : fichier, nb de pages du PDF, nb d'exercices d'application / d'entraînement /
   sujets bac, nb de figures, nb de méthodes. NE renvoie PAS tout le LaTeX.
