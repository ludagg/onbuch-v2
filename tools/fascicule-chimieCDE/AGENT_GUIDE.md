# Guide — RÉDIGER LE COURS d'un chapitre de Chimie Tle C/D/E/TI (OnBuch)

Tu rédiges **UNIQUEMENT LE COURS** d'un chapitre de Chimie des Terminales scientifiques
(C, D, E, TI — Baccalauréat, Cameroun, programme MINESEC). Qualité « grand livre de
référence » : cours développé, mécanismes, propriétés, exemples résolus, méthodes.
Langue : **français**.

⚠️ **NE rédige PAS d'exercices, ni de sujets, ni de corrigés.** Les fiches d'exercices
type-examen et les corrigés sont écrits séparément (par un humain expert). Tu t'arrêtes
après la section « Méthodes & savoir-faire ».

## Sortie attendue
- **UNIQUEMENT du LaTeX**, à partir de `\chapter{...}`. NI `\documentclass`, NI `\usepackage`,
  NI `\begin{document}`. Pas de texte hors LaTeX, pas de ```` ``` ````.
- Tout le préambule est déjà chargé (siunitx, mhchem, chemfig, tcolorbox…). N'ajoute AUCUN package.

## Structure IMPOSÉE (dans cet ordre, et RIEN d'autre après)
1. `\chapter{Titre exact}` + court paragraphe d'intro en `\textit{...}`.
2. **Le cours** — plusieurs `\section{...}`. Utilise abondamment :
   - `\begin{definition}[Nom]...\end{definition}` (orange)
   - `\begin{loi}[Nom]...\end{loi}`, `\begin{propriete}[Nom]...\end{propriete}` (vert)
   - `\begin{experience}[Titre]...\end{experience}` (bleu — tests, manipulations)
   - `\begin{remarque}...\end{remarque}`, `\begin{exemple}...\end{exemple}` (souvent)
   - `\begin{aretenir}...\end{aretenir}` (2-3 fois)
   - **Formules et mécanismes** (voir ci-dessous) : c'est ESSENTIEL en chimie.
   - Développe les mécanismes réactionnels, les conditions, les observations.
3. `\section{L'essentiel à retenir}` : fiche de révision dans `\begin{synthese}` ...
   (formules clés, réactions, tests caractéristiques, pièges) ... `\end{synthese}`.
4. `\section{Méthodes \& savoir-faire}` : **6 à 9** `\methode{Titre}` + explication + `\begin{exemple}` résolu
   (déterminer une formule, écrire une équation, nommer un composé, calculer un pH, etc.).

➡️ **STOP après la section Méthodes.** Pas de section exercices/sujets/corrigés.

## Chimie : formules, réactions, unités (OBLIGATOIRE)
- **Réactions / espèces** : `mhchem` → `\ce{CH3COOH + C2H5OH <=> CH3COOC2H5 + H2O}`,
  `\ce{H3O+}`, `\ce{HO-}`, `\ce{Cu^2+}`, flèches `->`, `<=>`, `<-`.
- **Formules développées / topologiques** : `chemfig` →
  `\chemfig{CH_3-CH_2-OH}` (éthanol), `\chemfig{*6(-=-=-=)}` (benzène),
  `\chemfig{R-C(=[1]O)-OH}` (acide carboxylique). Encadre les schémas dans `\begin{illus}...\end{illus}`
  avec une légende `\fig{...}` PLACÉE APRÈS la formule.
- **pH, concentrations, quantités** : siunitx → `\SI{0.1}{\mol\per\litre}`, `\SI{25}{\celsius}`,
  `pH = \num{2.5}`, `\si{\mol}`, `\si{\gram\per\mol}`. (Déclare rien ; `\litre`, `\mol`, `\celsius` existent.)

## Règles ABSOLUES
- **Chimiquement EXACT** : équations équilibrées, mécanismes corrects, valeurs justes.
- **Programme Tle C/D/E/TI Cameroun**. Contexte camerounais bienvenu quand c'est naturel.
- LaTeX **pur et compilable**, AUCUN package en plus.
- `\fig{...}` APRÈS `\end{tikzpicture}`/la formule chemfig (jamais à l'intérieur).
- N'invente pas d'unités siunitx ; pas de `$` parasite après un `\SI{}{}` en texte.
- Sortie = **LaTeX du COURS seul** (chapitre → cours → essentiel → méthodes). Rien après.
