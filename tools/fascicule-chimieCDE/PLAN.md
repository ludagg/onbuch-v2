# Fascicule de Chimie — Terminales C, D, E, TI (Baccalauréat, Cameroun)
## Plan — programme officiel MINESEC (tronc commun séries scientifiques)

> Répartition du travail (validée) :
> - **Cours** de chaque chapitre → généré par **DeepSeek** (NVIDIA), via `AGENT_GUIDE.md`
>   (cours développé + L'essentiel + Méthodes ; **PAS d'exercices**).
> - **Fiches d'exercices type-examen** après chaque chapitre → **rédigées à la main (Claude)** :
>   **15 à 20 exercices type Bac/examen** par chapitre, costauds, énoncés seuls (`exoXX.tex`).
> - **Corrigés** → **rédigés à la main (Claude)**, regroupés **en fin de livre** (`corriges.tex`) :
>   corrigés détaillés des exercices les plus importants/durs (sélection, pas tous).

## Chapitres (13)

### Partie A — Chimie organique
1. Généralités sur la chimie organique
2. Les alcanes
3. Les alcènes et les alcynes
4. Les hydrocarbures aromatiques — le benzène
5. Les alcools et les phénols
6. Les composés carbonylés — aldéhydes et cétones
7. Les acides carboxyliques et leurs dérivés
8. Les amines
9. Les acides α-aminés et les protéines

### Partie B — Chimie en solution
10. La cinétique chimique
11. Acides et bases — pH, couples acide/base, pKa
12. Réactions acido-basiques : dosages et solutions tampons
13. Les réactions d'oxydoréduction — piles et électrolyse

## Architecture de fabrication
- `chXX.tex` : COURS (DeepSeek) — `generate.mjs` (NVIDIA direct, streaming, deepseek-v4-flash).
- `exoXX.tex` : FICHE D'EXERCICES type-examen (Claude) — incluse juste après `chXX`.
- `corriges.tex` : CORRIGÉS en fin de livre (Claude).
- `preamble.tex` : design OnBuch + siunitx + mhchem + **chemfig** (formules organiques).
- `main.tex` : couverture + avant-propos + sommaire + (chXX + exoXX)×13 + corriges.
- Compilation `tectonic` ; corrections de compilation à la main.
