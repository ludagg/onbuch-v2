# Fascicule de Physique — Terminales C, D, E, TI (Baccalauréat, Cameroun)
## Plan détaillé — programme officiel MINESEC (tronc commun aux 4 séries)

> Référence : programme officiel en vigueur (Thèmes I–III, 10 chapitres). Tronc
> commun C/D/E/TI ; la série TI suit le programme de la D. Conventions : énoncés en
> contexte camerounais, unités SI (`siunitx`), progression Facile→Bac, design OnBuch.
>
> Structure de CHAQUE chapitre (identique au fascicule de maths) :
> **A. Le cours** (définitions, lois, propriétés, expériences — encadrés + figures)
> **B. L'essentiel** (fiche de révision `synthese`)
> **C. Méthodes & savoir-faire** (chacune avec un exemple résolu)
> **D. Exercices d'application corrigés** (par rubrique, ★→★★★)
> **E. Exercices d'entraînement** (gros banc, NON corrigés)
> **F. Sujets type Baccalauréat** (corrigés) → **G. Corrigés**
>
> COLONNE « Schémas » — mode de production de chaque figure :
> `TikZ` (vecteurs, trajectoires, géométrie) · `pgfplots` (courbes/graphes) ·
> `circuitikz` (circuits électriques) · **`IMG`** = trop complexe/réaliste →
> le modèle pose `\imgph{cle}{description}` (image téléchargée ensuite par un agent).

---

# THÈME I — LES MOUVEMENTS DANS LES CHAMPS DE FORCES

## Chapitre 1 — Forces et champs
**Cours.** Notion de champ (scalaire/vectoriel) ; champ de gravitation `g`, champ
électrostatique `E` (loi de Coulomb, champ d'une charge ponctuelle, de plusieurs
charges, condensateur plan), champ magnétique `B` (aimants, champ terrestre,
champ créé par un courant — fil, spire, solénoïde ; règle de la main droite) ;
lignes de champ, spectres ; superposition.
**Méthodes.** Calcul de `E`/`g`, champ résultant, caractéristiques d'un vecteur champ ; sens de `B`.
**Schémas.** Vecteurs champ & lignes de champ (`TikZ`) · condensateur plan (`TikZ`) ·
solénoïde + lignes de B (`TikZ`) · **spectres réels de limaille de fer (`IMG`)**.

## Chapitre 2 — Les lois de Newton
**Cours.** Vecteurs position/vitesse/accélération ; référentiels (galiléens), repère
de Frenet ; quantité de mouvement ; 1re, 2e, 3e lois de Newton ; bilan des forces ;
théorème du centre d'inertie.
**Méthodes.** Bilan des forces & 2e loi ; choix du référentiel/repère ; projection.
**Schémas.** Bilan de forces (`TikZ`) · plan incliné (`TikZ`) · repère de Frenet (`TikZ`).

## Chapitre 3 — Mouvements dans un champ uniforme
**Cours.** Mouvement d'un projectile dans le champ de pesanteur (équations horaires,
trajectoire parabolique, portée, flèche) ; mouvement d'une particule chargée dans un
champ `E` uniforme (déviation dans un condensateur, oscilloscope) ; énergie.
**Méthodes.** Établir les équations horaires ; équation de trajectoire ; déviation.
**Schémas.** Trajectoire parabolique (`pgfplots`) · déviation d'une charge entre
armatures (`TikZ`) · canon à électrons/oscilloscope (`TikZ`, ou `IMG` si réaliste).

## Chapitre 4 — Mouvements circulaires uniformes
**Cours.** Accélération centripète ; particule chargée dans un champ `B` uniforme
(force de Lorentz, rayon, période, déflexion magnétique, spectrographe de masse,
cyclotron) ; satellites & planètes (gravitation, lois de Kepler, satellite
géostationnaire, vitesses cosmiques).
**Méthodes.** Application de la 2e loi en circulaire ; rayon dans `B` ; paramètres d'orbite.
**Schémas.** Charge décrivant un cercle dans `B` (`TikZ`) · orbite satellite (`TikZ`) ·
spectrographe de masse / cyclotron (`TikZ` simple, sinon `IMG`).

# THÈME II — LES SYSTÈMES OSCILLANTS

## Chapitre 5 — Généralités sur les systèmes oscillants
**Cours.** Phénomènes périodiques ; période, fréquence, pulsation ; grandeur
sinusoïdale, amplitude, phase, déphasage ; représentation de Fresnel ; oscillations
libres/forcées, amorties ; résonance (intro).
**Méthodes.** Lire amplitude/période/déphasage ; construction de Fresnel.
**Schémas.** Signaux sinusoïdaux & déphasage (`pgfplots`) · diagramme de Fresnel (`TikZ`) ·
oscillations amorties (`pgfplots`).

## Chapitre 6 — Les oscillateurs mécaniques
**Cours.** Pendule élastique (masse-ressort, horizontal/vertical) ; pendule simple ;
pendule de torsion ; équation différentielle `x'' + ω₀²x = 0`, solution, période propre ;
énergie mécanique (conservation, amortissement) ; oscillations forcées, résonance.
**Méthodes.** Établir l'équation différentielle (2e loi / énergie) ; période propre ;
bilan énergétique.
**Schémas.** Masse-ressort horizontal & vertical (`TikZ`) · pendule simple (`TikZ`) ·
pendule de torsion (`TikZ`) · énergie en fonction du temps (`pgfplots`) ·
courbe de résonance (`pgfplots`).

## Chapitre 7 — Les oscillateurs électriques  ★ CHAPITRE PILOTE
**Cours.** Condensateur (charge, capacité, énergie) ; dipôle RC (charge/décharge,
constante de temps) ; bobine, auto-induction, dipôle RL ; oscillations libres du
circuit LC puis RLC (équation différentielle, pseudo-période, amortissement) ;
oscillations forcées en régime sinusoïdal, résonance d'intensité ; analogie
électromécanique.
**Méthodes.** Établir l'équation différentielle d'un circuit ; exploiter `τ=RC`/`τ=L/R` ;
période propre LC ; lire un oscillogramme.
**Schémas.** Circuits RC, RL, LC, RLC série (`circuitikz`) · montage charge/décharge
avec interrupteur (`circuitikz`) · oscillogrammes u(t)/i(t) (`pgfplots`) ·
courbe de résonance d'intensité (`pgfplots`).

# THÈME III — PHÉNOMÈNES CORPUSCULAIRES ET ONDULATOIRES

## Chapitre 8 — Les ondes mécaniques
**Cours.** Onde progressive (transversale/longitudinale) ; célérité, double
périodicité, longueur d'onde ; onde le long d'une corde, le long d'un ressort ;
ondes à la surface de l'eau (cuve à ondes) ; réflexion, réfraction, diffraction ;
interférences mécaniques.
**Méthodes.** Relation `λ = vT` ; retard ; états vibratoires ; conditions d'interférence.
**Schémas.** Onde sur une corde (`pgfplots`) · cuve à ondes / rides circulaires (`TikZ`,
sinon `IMG`) · diffraction par une fente (`TikZ`) · interférences à deux sources (`TikZ`).

## Chapitre 9 — La lumière
**Cours.** Nature de la lumière (modèle ondulatoire) ; interférences lumineuses
(fentes de Young, interfrange, conditions) ; diffraction ; aspect corpusculaire :
effet photoélectrique (Einstein, travail d'extraction, seuil), photon, dualité ;
spectres (émission/absorption), niveaux d'énergie de l'atome, transitions.
**Méthodes.** Calcul d'interfrange ; bilan photoélectrique (`hν = W₀ + Ec`) ;
transitions et longueurs d'onde émises.
**Schémas.** Dispositif des fentes de Young (`TikZ` + **`IMG` pour le montage réel**) ·
**figure d'interférences/franges (`IMG`)** · cellule photoélectrique (`TikZ`, sinon `IMG`) ·
diagramme de niveaux d'énergie (`TikZ`) · **spectres de raies (`IMG`)**.

## Chapitre 10 — La radioactivité
**Cours.** Noyau, nucléons, isotopes ; stabilité, diagramme (N,Z) ; radioactivité α,
β⁻, β⁺, γ ; lois de conservation (Soddy) ; familles radioactives ; décroissance
radioactive (loi, constante λ, demi-vie, activité, datation) ; réactions nucléaires
provoquées : fission, fusion ; énergie de liaison, défaut de masse (Einstein).
**Méthodes.** Équations de désintégration (Soddy) ; loi de décroissance `N=N₀e^{-λt}` ;
demi-vie, datation ; bilan d'énergie (`E=Δm·c²`).
**Schémas.** Courbe de décroissance (`pgfplots`) · diagramme (N,Z) de stabilité (`pgfplots`) ·
courbe d'Aston (énergie de liaison/nucléon) (`pgfplots`) · familles radioactives (`TikZ`).

---

## Annexes prévues
- **Formulaire** (constantes physiques, relations clés par thème, unités SI).
- **Constantes & données** (g, G, c, e, mₑ, mₚ, ε₀, μ₀, h, N_A…).
- Index des **méthodes** par chapitre.

## Format de production
- Un seul PDF (classe `book`), compilé par **tectonic** (XeLaTeX), design OnBuch.
- Préambule : `tools/fascicule-physiqueCDE/preamble.tex` (siunitx + circuitikz +
  encadrés Définition/Loi/Propriété/Expérience/Exemple/À retenir/Méthode/Exercice/Corrigé,
  placeholder image `\imgph`).
- **Génération déléguée à NVIDIA** (économie budget Claude) : `generate.mjs` appelle
  l'API NVIDIA chapitre par chapitre selon `AGENT_GUIDE.md`, compile et reboucle sur erreur.
- **Images externes** : `fetch_images.mjs` collecte les `\imgph`, télécharge une image
  libre (Wikimedia Commons) dans `images/<cle>` et remplace par `\imgreal`.
