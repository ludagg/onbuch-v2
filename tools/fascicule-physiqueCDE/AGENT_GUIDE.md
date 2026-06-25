# Guide — RÉDIGER un chapitre du fascicule de Physique Tle C/D/E/TI (OnBuch)

Tu rédiges UN chapitre complet du fascicule de Physique des Terminales scientifiques
(C, D, E, TI — Baccalauréat, Cameroun, programme MINESEC). Objectif : qualité
« **grand livre de référence** » — cours très développé, lois encadrées, figures,
résumés, méthodes, et **beaucoup** d'exercices corrigés. Langue : **français**.

## Sortie attendue
- **UNIQUEMENT du LaTeX**, à partir de `\chapter{...}`. N'écris NI `\documentclass`,
  NI `\usepackage`, NI `\begin{document}`. Pas de texte hors LaTeX, pas de ```` ``` ````.
- Tout le préambule (`preamble.tex`) est déjà chargé : n'ajoute AUCUN package.

## Structure IMPOSÉE du chapitre (dans cet ordre)
1. `\chapter{Titre exact}` + court paragraphe d'intro en `\textit{...}`.
2. **Le cours** — plusieurs `\section{...}`. Dedans, utilise abondamment :
   - `\begin{definition}[Nom]...\end{definition}` (orange)
   - `\begin{loi}[Nom]...\end{loi}`, `\begin{propriete}[Nom]...\end{propriete}` (vert)
   - `\begin{experience}[Titre]...\end{experience}` (bleu — manipulations/observations)
   - `\begin{remarque}...\end{remarque}`, `\begin{exemple}...\end{exemple}` (souvent)
   - `\begin{aretenir}...\end{aretenir}` (2-3 fois)
   - **4 à 7 figures** (voir « Figures » ci-dessous).
   - Démontre/justifie les résultats quand c'est au programme (sobrement).
3. `\section{L'essentiel à retenir}` : fiche de révision condensée dans
   `\begin{synthese}` ... (lois clés, formules, unités, plan de résolution, pièges) ... `\end{synthese}`.
4. `\section{Méthodes \& savoir-faire}` : **6 à 9** `\methode{Titre}` + explication + `\begin{exemple}` résolu.
5. `\section{Exercices d'application}` : **classés** par `\rubrique{Thème}` (4-6 rubriques).
   Chaque exercice `\exo{}\diff{n} énoncé...` (n=1/2/3 → ★/★★/★★★). **12 à 18** exercices.
6. `\section{Exercices d'entraînement}` : **GROS banc NON corrigé**, par `\rubrique{}`. **18 à 30** exercices.
7. `\section{Sujets type Baccalauréat}` : **2 à 3** sujets via `\sujetbac[contexte]` puis l'énoncé
   (souvent `\begin{enumerate}[label=\arabic*)]` à parties).
8. `\section{Corrigés}` : corrigés détaillés **des exercices d'application** (section 5) et **des
   sujets type Bac** (section 7), via `\corrige{de l'exercice n}` / `\corrige{du sujet n}`.
   **NE corrige PAS** les exercices d'entraînement (section 6).

## Unités & notation physique (OBLIGATOIRE)
- **Toujours** les valeurs avec unité via `siunitx` : `\SI{9.8}{\metre\per\second\squared}`,
  `\SI{12}{\volt}`, `\SI{50}{\hertz}`, `\SI{2e-3}{\farad}`, `\ang{30}`. Unité seule : `\si{\ohm}`.
- **N'INVENTE JAMAIS d'unité siunitx** : `\spires`, `\tours`, `\gauss`… n'existent pas → erreur de
  compilation. Pour un libellé NON-SI (spires/m, tr/min), écris-le en texte mathématique :
  `\num{2000}~\mathrm{spires/m}`, `\num{3000}~\mathrm{tr/min}` (PAS `\SI{...}{...}`).
  Décimale : siunitx affiche la virgule (locale FR) automatiquement — écris le point dans `\SI`.
- Vecteurs : `\vect{F}`, `\vect{B}`, `\vect{E}`, `\vect{v}` (jamais `\vec` brut autrement).
- Dérivées temporelles : `\dv{x}{t}`, `\dv[2]{x}{t}` n'existe pas → écris `\ddot{x}`, `\dot{x}`.

## Figures — TROIS modes (choisis le bon)
- **A. TikZ** (vecteurs, bilans de forces, trajectoires, lignes de champ, géométrie) et
  **pgfplots** (courbes, oscillogrammes, décroissance) et **circuitikz** (circuits électriques).
  Encadre-les ainsi :
  ```
  \begin{illus}
  \begin{tikzpicture}[...] ... \end{tikzpicture}   % ou {circuitikz} / {axis}
  \fig{Figure — légende courte.}
  \end{illus}
  ```
  ⚠️ `\fig{...}` se place **APRÈS** `\end{tikzpicture}`/`\end{axis}`/`\end{circuitikz}` (jamais à
  l'intérieur du dessin) et avant `\end{illus}` — sinon « Missing character … nullfont ».
- **B. IMAGE EXTERNE** — pour tout schéma **trop complexe ou réaliste** à dessiner en code
  (montages expérimentaux réels, spectres de raies, figures d'interférences photographiées,
  spectres de limaille, dispositifs d'optique fins). **NE tente PAS de les dessiner.**
  Pose à la place :
  ```
  \imgph{chXX-cle-courte}{Description précise en français : sujet, éléments visibles, type de vue.}
  ```
  - `chXX-cle-courte` : minuscules, tirets, unique (ex. `ch09-fentes-young`, `ch01-spectre-aimant`).
  - La description doit suffire à retrouver l'image (elle sert de requête de recherche).
- Vise **au plus 1 à 2 `\imgph` par chapitre** : privilégie TikZ/circuitikz/pgfplots partout où c'est raisonnable.

## Règles circuitikz (chap. 7 surtout)
- Dipôles : `to[R=$R$]`, `to[L=$L$]`, `to[C=$C$]`, `to[V=$E$]` (source), `to[battery1]`,
  `to[switch]` (interrupteur), `to[ammeter]`, `to[voltmeter]`. Échelle : `[scale=0.9, transform shape]`.
- Garde les circuits simples et fermés (mailles rectangulaires). Pas de lib externe.

## Règles ABSOLUES
- **Physiquement EXACT** : vérifie toutes les valeurs, unités, applications numériques et corrigés.
  Constantes usuelles : `g=\SI{9.8}{\metre\per\second\squared}`, `c=\SI{3e8}{\metre\per\second}`,
  `e=\SI{1.6e-19}{\coulomb}`, `G=\SI{6.67e-11}{}`, `h=\SI{6.63e-34}{\joule\second}`.
- **Programme Tle C/D/E/TI Cameroun**. Contexte camerounais bienvenu (villes, francs CFA, situations
  réelles) quand c'est naturel.
- LaTeX **pur et compilable**, AUCUN package en plus (tout est dans preamble.tex).
- ⚠️ pgfplots : libs `intersections`/`fillbetween` NON chargées. Pour remplir sous une courbe :
  `\addplot[...] {...} \closedcycle;`. Ne charge AUCUNE lib.
- Les corrigés (section 8) suivent EXACTEMENT la numérotation des exercices d'application (section 5).
- Sortie = **LaTeX seul**, rien d'autre.
