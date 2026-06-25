# Fascicule d'Informatique — Terminales C, D, E (Baccalauréat, Cameroun)
## Plan — programme officiel MINESEC

> Philosophie (validée) : **cours = résumés simples et clairs**, et **énormément
> d'exercices type-examen, TOUS corrigés**. Tout (cours + exercices + corrigés) est
> généré par **DeepSeek** (NVIDIA) — c'est sa force sur l'algo/le code. Mon rôle :
> cadrer (programme + types d'épreuve), orchestrer, corriger la compilation.

## Chapitres (12)

### Module 1 — Systèmes informatiques
1. Architecture et fonctionnement de l'ordinateur
2. Systèmes d'exploitation et maintenance
3. Systèmes de numération et codage de l'information

### Module 2 — Systèmes d'information & bases de données
4. Système d'information et MCD (MERISE)
5. Du MCD au modèle relationnel
6. Le langage SQL
7. Le tableur

### Module 3 — Algorithmique & programmation
8. Algorithmique : variables et structures de contrôle
9. Tableaux et structures de données
10. Programmation en langage C

### Module 4 — Réseaux & humanités numériques
11. Les réseaux informatiques
12. Internet, le web et la citoyenneté numérique

## Structure de chaque chapitre (chXX.tex)
- `\section{L'essentiel du cours}` — résumé court (1-2 pages).
- `\section{Exercices}` — 20 à 30 exercices type-examen, classés par rubrique.
- `\section{Corrigés}` — corrigé détaillé de CHAQUE exercice.

## Fabrication
- `generate.mjs` (NVIDIA deepseek-v4-flash, direct, streaming) → chXX.tex.
- `preamble.tex` : design OnBuch + `listings` (pseudo-code `algo` / `ccode` / `sqlcode`).
- `main.tex` : couverture + avant-propos + sommaire + 12 chapitres.
- Compilation `tectonic` ; corrections de compilation à la main.
