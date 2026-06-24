# Fabrique de fiches d'exercices OnBuch (énoncé + correction PDF)

Chaîne de production des **fiches d'exercices** (PDF aux couleurs OnBuch) publiées
dans le module Exercices (collections `exercise_chapters` / `exercise_sheets`).

## Principe

1. Le **corps LaTeX** d'un énoncé et d'une correction est écrit (à la main, ou
   généré par un modèle), SANS préambule ni `\begin{document}` — juste le contenu,
   avec la commande `\exo{Exercice 1 -- titre}` et des `enumerate[label=\alph*)]`.
2. `build_pdf.py` enveloppe ce corps dans `preamble.tex` (préambule OnBuch :
   couleurs orange/vert, bandeau titre, en-tête/pied de page, amorce « Correction
   détaillée »), compile avec **tectonic** (XeLaTeX), et **répare automatiquement**
   les erreurs LaTeX via un modèle (détecte les erreurs « récupérables » que
   tectonic ignore, ex. `Extra alignment tab`).
3. `upload.py` envoie les PDF dans le bucket Storage `annales_files`
   (`read("any")`) et crée/maj le document `exercise_sheets`.
4. `pub.py <chapter_id> <idx> <difficulty> "<titre>"` enchaîne meta + build + upload
   (récupère matière + titre du chapitre depuis Appwrite). C'est l'outil principal
   pour publier une fiche rédigée à la main.

## Pré-requis

- `tectonic` (moteur LaTeX, télécharge les packages tout seul) — voir installation.
- `python3` + `requests`.
- Variables d'env : `APPWRITE_API_KEY` (toujours), et pour la réparation auto
  `NVIDIA_API_KEY` + `REPAIR_MODEL` (ex. `meta/llama-3.3-70b-instruct`).
- Le préambule utilise `fontspec` (XeTeX) — gère nativement l'UTF-8, `·`, `—`, etc.
  **Ne PAS** réintroduire inputenc/fontenc/lmodern (tectonic = XeTeX).

## Rédiger une fiche à la main (physique / chimie)

Dans un dossier de travail `<outdir>` :
- écrire `enonce<idx>.body.tex` et `corr<idx>.body.tex` (corps LaTeX, maths en
  `$...$` / `\[...\]`, tableaux en `array` ou `tabular` — **PAS de tikz/pgfplots**) ;
- `python3 pub.py <chapter_id> <idx> <difficulty> "<titre fiche>"`.

## Génération en masse par IA (maths)

`run_all.py` (parallèle, reprise sur erreur via `state.json`) lit `math_plan.json`
(19 chapitres × 5 fiches) et appelle `gen.py` (NVIDIA Nemotron) → build → upload.
Clés réparties round-robin via `NVIDIA_API_KEYS` (séparées par virgule) pour
contourner le rate-limit 429. `gen.py` interdit les graphes (cause n°1 d'échec).

## Taxonomie des chapitres (Appwrite `exercise_chapters`)

- **Maths Tle C** : `exch_mathc_01..19`, `subject=Mathématiques`, `track=C`.
- **Physique Tle ESG** : `exch_phys_01..18`, `subject=Physique`, `track=C,D,E,TI`.
- **Chimie Tle ESG** : `exch_chim_01..15`, `subject=Chimie`, `track=C,D,E,TI`.

`track` accepte une **liste** de séries (`C,D,E,TI`) — voir `appliesToClass`
dans `lib/models/exercise.dart` (nécessite un patch Shorebird pour les élèves).

## Avancement (à mettre à jour)

- **Maths : 94/95** publiées. Restent 3 fiches coriaces à RÉDIGER À LA MAIN
  (le pipeline IA échoue) : `exch_mathc_07_f4` (énoncé), `exch_mathc_08_f2`
  (énoncé), `exch_mathc_03_f4` (corrigé manquant).
- **Physique : ch.1 à ch.5 COMPLETS** (Cinématique, Lois de Newton, Énergie,
  Champ de pesanteur, Champ électrique). Restent ch.6 à ch.18.
- **Chimie : ch.1 à ch.3 COMPLETS** (Cinétique, pH/acides-bases, Couples Ka/pKa).
  Restent ch.4 à ch.15.

> ⚠️ TEMPORAIRE : les chapitres physique/chimie ont `track=""` (visibles par
> toutes les séries) en attendant le patch Shorebird du modèle multi-séries.
> À rebasculer en `track="C,D,E,TI"` une fois le patch déployé.

## Reprise rapide (nouvelle session)

```
cd /tmp && mkdir -p exo/out && cd exo
# (réinstaller tectonic si absent)
cp /home/user/onbuch-v2/tools/exercices-fiches/{preamble.tex,build_pdf.py,upload.py,pub.py} build/
# écrire build/../out/<cid>/enonce<i>.body.tex et corr<i>.body.tex, puis :
export APPWRITE_API_KEY=...  NVIDIA_API_KEY=...  REPAIR_MODEL=meta/llama-3.3-70b-instruct
python3 build/pub.py <chapter_id> <i> "<Difficulté>" "<titre fiche>"
```
Conventions : g=10 N/kg, contexte camerounais, 3–5 exercices Facile→Difficile,
maths/chimie en `$...$` et tableaux `array`, PAS de tikz.

> Les conventions de contenu (programme MINESEC Tle C/D/E/TI, g=10 N/kg, contexte
> camerounais, énoncés Facile→Difficile, 4–6 exercices/fiche) sont à respecter.
