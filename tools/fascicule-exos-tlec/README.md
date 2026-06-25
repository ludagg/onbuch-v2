# Fascicule — 1000 exercices Maths Tle C (OnBuch)

Banque de 930 exercices corrigés, 23 chapitres, mise en page **deux colonnes** dense.

## Fichiers
- `maitre.tex` — document (contenu déjà préparé par `format.py`). Compilé avec **tectonic**.
- `preamble.tex` — design + densité + auto-réduction (displays/tableaux/figures/maths inline) à la largeur de colonne.
- `cover.tex` — inclut `couverture.pdf` (couverture officielle).
- `format.py` — réapplique les 3 transformations mécaniques au contenu brut si tu réédites
  (`$$`→`\[\]`, fix `\tag`, enveloppe `\fitmath` des longues maths inline).
- `1000-Exercices-Maths-TleC-OnBuch.pdf` — PDF compilé (475 p.).

## Compiler
```
tectonic maitre.tex
```

## Rééditer le contenu
Édite ta source brute, puis :
```
python3 format.py contenu_brut.tex maitre.tex && tectonic maitre.tex
```
