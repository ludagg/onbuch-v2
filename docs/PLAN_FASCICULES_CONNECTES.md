# Plan — Les fascicules connectés OnBuch 📚📱

> **La promesse** : le premier fascicule au Cameroun (et, à notre connaissance, au
> monde pour ce format) où **le papier et l'application ne font qu'un**. Chaque
> chapitre, chaque exercice du livre imprimé porte un code qui ouvre, dans OnBuch,
> son corrigé détaillé, son quiz, sa fiche de révision et l'aide de Léo —
> instantanément, sans photo, sans recherche.

---

## 1. Le concept : qu'est-ce qu'un « fascicule connecté » ?

Un fascicule OnBuch (livre papier ou PDF) dont **chaque unité de contenu est
adressable depuis l'app** :

- **1 QR code par chapitre** (page d'ouverture du chapitre) → ouvre le
  « **compagnon du chapitre** » dans l'app : essentiel, méthodes, quiz, corrigés,
  aide de Léo.
- **1 code court imprimé par exercice** (ex. `PHY05·E17`) → l'élève le tape (ou le
  touche depuis le compagnon) et obtient le corrigé / l'aide correspondante.
  Le code court fonctionne **sans caméra et sans QR** — essentiel au Cameroun où
  beaucoup d'élèves partagent un téléphone d'entrée de gamme.
- **1 code d'activation unique par exemplaire imprimé** (sous la couverture) →
  déverrouille le contenu premium du compagnon et crédite des bonus Léo.

### La boucle produit (le génie du système)

Nos fascicules ont déjà, par conception, une section **« Exercices
d'entraînement » volontairement NON corrigée dans le livre** (structure E des
`AGENT_GUIDE.md`). C'est le moteur de la connexion :

```
Le livre donne l'énoncé  ──►  le code ouvre l'app  ──►  l'app donne le corrigé,
le quiz, Léo, la progression  ──►  l'app vend les autres fascicules  ──►  🔁
```

- Le **livre vend l'app** (chaque exercice non corrigé est une porte d'entrée).
- L'**app vend le livre** (bibliothèque, aperçu 10 pages, précommande WhatsApp —
  déjà en production).
- Personne d'autre au Cameroun ne peut copier ça : il faut le livre **et**
  l'infrastructure (Appwrite, Léo, quiz, push, gamification) **et** le pipeline
  de production LaTeX. Nous avons déjà les trois.

---

## 2. État des lieux (recherche dans le dépôt)

### 2.1 Les fascicules produits (`tools/fascicule-*`)

| Fascicule | Dossier | État | PDF compilé |
|---|---|---|---|
| **Maths — Tle C** | `fascicule-mathsC` | ✅ Complet (24 ch. + annales 2021-23 + mégafiche + méthodo) | ✅ |
| **Physique — Tle C/D/E/TI** | `fascicule-physiqueCDE` | ✅ Complet (10 ch., 3 thèmes, images externes) | ✅ |
| **Informatique — Tle C/D/E** | `fascicule-infoCDE` | ✅ Complet (12 ch.) | ✅ |
| **Algorithmique — Tle TI** | `fascicule-algo-tlec-ti` | ✅ Complet (12 ch. + 5 sujets + annale Vogt) | ✅ |
| **1000 exercices Maths — Tle C** | `fascicule-exos-tlec` | ✅ Complet | ✅ |
| **Maths — 1ère C** | `fascicule-maths1` | 🟡 16 ch. rédigés (cours + exos) | ❌ à compiler |
| **Chimie — Tle C/D/E** | `fascicule-chimieCDE` | 🟡 13 ch. générés | ❌ à compiler |

Pipeline de production en place : `main.tex` + `preamble.tex` (encadrés OnBuch :
définition/loi/méthode/exo/corrigé, compteurs d'exercices par chapitre),
génération déléguée à l'API NVIDIA (`generate.mjs`), images libres
(`fetch_images.mjs`), compilation **tectonic**.

### 2.2 Ce qui existe déjà dans l'app (à réutiliser tel quel)

| Brique | Où | Rôle dans le fascicule connecté |
|---|---|---|
| Collection `fascicules` + modèle | `lib/models/fascicule.dart`, `tools/setup_fascicules.sh` | Catalogue, prix/promo, avantages |
| Bibliothèque + fiche produit | `lib/screens/fascicules/…` | Vente : aperçu 10 p., précommande WhatsApp |
| Lecteur PDF avec mode aperçu | `lib/screens/annales/pdf_reader_screen.dart` (`previewPages`, `orderUrl`) | Aperçu verrouillé |
| Deep links | `lib/services/deep_link_service.dart` (`onbuch://`, `onbuch-go.vercel.app/a/…`) + page `share/index.html` | À étendre aux codes fascicule |
| Tuteur Léo | fonction `tutor-ai` (modes correction/lesson/quiz/summary) | Aide contextualisée par exercice |
| Quiz + progression | `quizzes`, `chapter_progress` | Quiz de chapitre |
| Fiches d'exercices + statut | `exercise_sheets`, `exercise_progress` | Patron du suivi « fait / trouvé / pas trouvé » |
| Push ciblé | Appwrite Messaging + FCM | Relances « ton corrigé est prêt », défis |
| Gamification | Ligue/classement (PR #201-202), parrainage + crédits (PR #203) | Défis par fascicule |
| Numéro WhatsApp commandes | `order_settings` (`tools/setup_order_settings.sh`) | Canal de vente |
| Fonctions serverless Vercel | `api/*.js` (projet `onbuch-v2`) | Héberger l'API d'activation (le plan Appwrite est au max de fonctions) |

**Conclusion de la recherche** : ~70 % de l'infrastructure existe. Le chantier,
c'est la **couche de connexion** (codes → contenus) et le **contenu compagnon**
(corrigés d'entraînement, quiz par chapitre).

---

## 3. L'expérience cible (parcours élève)

### Scénario A — l'élève a le livre, pas l'app
1. Il bloque sur l'exercice 17 du chapitre 5 de Physique. Sous l'énoncé :
   « 📱 Corrigé + aide : code **PHY05·E17** sur OnBuch » + QR en tête de section.
2. Il scanne le QR avec l'appareil photo → `https://onbuch-go.vercel.app/f/PHY05/E17`
   → page élégante (déjà stylée charte OnBuch) → « Ouvrir dans OnBuch » ou
   bouton Play Store. **Le livre devient notre premier canal d'acquisition.**

### Scénario B — l'élève a le livre et l'app
1. Il scanne (ou tape le code court dans l'onglet Fascicules → « J'ai le livre »).
2. Écran **compagnon d'exercice** : ① le corrigé rédigé (rendu `RichAnswer`,
   LaTeX/maths) ② « Je n'ai pas compris → demander à Léo » (chat pré-contextualisé
   avec l'énoncé, **sans photo**) ③ marquer « trouvé / pas trouvé » (progression).
3. En fin de chapitre : **quiz de validation** (10 questions) → anneau de
   progression du fascicule, XP ligue, streak.

### Scénario C — l'élève a acheté l'exemplaire imprimé
1. Sous la couverture : code d'activation unique (ex. `OB-PHYS-7K3M-92QD`).
2. Menu Fascicules → « Activer mon livre » → tous les corrigés + quiz
   déverrouillés **+ 30 crédits Léo offerts**. L'activation lie l'exemplaire au
   compte (anti-photocopie : 1 code = 2 comptes max).

### Scénario D — l'élève n'a pas le livre
Le compagnon montre l'essentiel + 3 corrigés gratuits par chapitre, puis la fiche
produit avec précommande WhatsApp (écran déjà existant). **L'app vend le livre.**

---

## 4. Architecture technique

### 4.1 Le système de codes (la colonne vertébrale)

Format **court, lisible, déterministe** (pas de base de données de codes à
maintenir pour l'adressage) :

```
 <FASC>  <CH>  ·  <UNITÉ>
 PHY05·E17  = Physique CDE/TI, chapitre 05, exercice d'entraînement 17
 PHY05·A03  = … exercice d'application 3      PHY05·S01 = … sujet type bac 1
 PHY05      = … compagnon du chapitre 5       PHY       = … accueil du fascicule
```

- Registre des préfixes (attribut `code` sur la collection `fascicules`) :
  `MTC` (Maths Tle C), `PHY`, `INF`, `ALG`, `MXC` (1000 exos), `MP1` (Maths 1ère), `CHM`.
- **Deep link** : `onbuch://f/PHY05/E17` (schéma déjà déclaré, **sans restriction
  de chemin** → fonctionne en simple **patch Shorebird**).
- **Lien web/QR** : `https://onbuch-go.vercel.app/f/PHY05/E17` → page de
  redirection (patron `share/index.html`) : tente `onbuch://`, sinon Play Store.
  L'App Link Android (`pathPrefix="/f"`) sera ajouté au manifeste **à la
  prochaine release native** — d'ici là, la page web fait le pont.

### 4.2 Côté LaTeX (réédition « connectée » des PDF)

Modifications **dans le préambule uniquement** — aucun chapitre à retoucher :

1. `\usepackage{qrcode}` (supporté par tectonic) + macro `\obqr{PHY05}` posée sur
   la page d'ouverture de chapitre (via `\chaptermark`/titlesec hook) et en tête
   de la section Entraînement.
2. Les compteurs d'exercices existent déjà (`preamble.tex` : « Compteurs
   d'exercices par chapitre ») → on **enrichit `\exo{}`** pour imprimer
   automatiquement le badge du code court (`PHY05·E17`) dans la marge de chaque
   énoncé, avec la mention « Corrigé & aide dans l'app OnBuch ».
3. 4e de couverture + page 2 : encart « **Ce livre est connecté** » (mode
   d'emploi, QR de téléchargement de l'app, emplacement du code d'activation).
4. Recompiler avec tectonic → nouveaux PDF v2 « édition connectée ».

> Un script `tools/connect_fascicule.py` générera aussi le **manifeste JSON** du
> fascicule (liste chapitres/exercices/codes) à partir des `.tex`, pour peupler
> les collections sans saisie manuelle.

### 4.3 Côté Appwrite (2 collections nouvelles + 2 attributs)

- `fascicules` : + `code` (préfixe, ex. `PHY`), + `connected` (bool).
- **`fascicule_units`** *(nouvelle, lecture `any`, écriture `team:admins`)* :
  une entrée par unité adressable.
  `fasciculeCode, chapter (int), unit (ex. E17, vide = chapitre), title,
  statement (énoncé, texte), solution (corrigé, markdown/LaTeX), essential
  (fiche), quizId, free (bool), order`.
  → Résout `PHY05·E17` en **une requête indexée** (`fasciculeCode + chapter + unit`).
- **`fascicule_activations`** *(nouvelle, documentSecurity)* :
  `codeHash, fasciculeCode, userId, activatedAt, deviceCount`.
  Les codes imprimés sont générés par lot (script) et stockés **hachés** (SHA-256).
- L'activation passe par **`api/fascicule-activate.js` sur Vercel** (patron
  `api/referral.js`, clé serveur en env) — le plan Appwrite est au max de
  fonctions, exactement comme pour `result-lookup`. Elle vérifie le hash,
  applique la limite de comptes, écrit l'activation et crédite `tutor_quota`
  (patron `addCredits` de `review-nudge`).

### 4.4 Le contenu compagnon : d'où viennent les corrigés ?

- **Exercices d'application & sujets bac** : les corrigés existent déjà dans les
  `.tex` (sections G) → extraction automatique par `connect_fascicule.py`.
- **Exercices d'entraînement** (non corrigés dans le livre — le cœur de l'offre) :
  **pré-génération hors-ligne** par le pipeline NVIDIA existant (`generate.mjs`
  adapté : entrée = énoncé extrait du `.tex`, sortie = corrigé détaillé), relus
  par échantillonnage, uploadés dans `fascicule_units`. Coût ≈ 0 (API NVIDIA),
  qualité contrôlée **avant** publication, réponse **instantanée** pour l'élève
  (pas d'attente de génération), et **aucune consommation de quota Léo**.
- **Léo en second niveau** : « Je n'ai pas compris » → chat tutor pré-rempli avec
  l'énoncé + le corrigé en contexte (mode gratuit type `lesson`) → Léo explique
  pas à pas. C'est là que Léo brille, sans supporter la charge de la correction.

### 4.5 Côté Flutter (le gros du travail app)

| Élément | Détail |
|---|---|
| Route `/f/:code` | Parse `PHY05·E17` / segments d'URL ; extension de `DeepLinkService._extractId` (préfixe `/f/`) |
| `FasciculeCompanionScreen` | Compagnon de chapitre : essentiel, liste des unités (statut ✓/✗), quiz, progression |
| `FasciculeUnitScreen` | Énoncé + corrigé (`RichAnswer`), bouton Léo, boutons « trouvé / pas trouvé » (patron `exercise_progress`) |
| Saisie code court | Bouton « 📖 J'ai le livre » (bibliothèque + accueil) : champ code + (plus tard) scanner in-app |
| Écran d'activation | Saisie du code d'activation → appel `api/fascicule-activate` → confetti + crédits |
| Verrouillage | `free`/activation : 3 corrigés gratuits/chapitre, le reste flouté avec CTA activation ou précommande |
| `DatabaseService` | `getFasciculeUnits(code, chapter)`, `resolveFasciculeCode(code)` (cache 5 min existant) |
| Analytics | Événements `fascicule_scan`, `fascicule_code_entry`, `unit_solved`, `activation` dans `analytics_events` |

**Patch vs release** : tout ce qui précède est **patchable Shorebird** (Dart pur).
Nécessiteront une **release native** (à grouper) : App Link `pathPrefix="/f"` dans
le manifeste, et le scanner QR in-app (`mobile_scanner`) — tous deux optionnels
pour le lancement grâce à la page web `onbuch-go` et à la saisie du code court.

### 4.6 Back-office (admin)

- 2 `Resource` dans `admin/src/lib/schema.ts` : `fascicule_units` (édition des
  corrigés/énoncés, toggle `free`) et vue `fascicule_activations` (lecture).
- Générateur de lots de codes d'activation (page outillage admin existante ou
  script `tools/gen_activation_codes.py` → CSV pour l'imprimeur + hashs uploadés).

---

## 5. Monétisation

| Offre | Contenu | Prix (indicatif, à valider) |
|---|---|---|
| **Gratuit** | Essentiel du chapitre + 3 corrigés/chapitre + quiz du ch. 1 | 0 F |
| **Livre imprimé** (précommande WhatsApp, existant) | Le fascicule + activation complète + 30 crédits Léo | 3 500–5 000 F |
| **Édition numérique** (phase 2) | PDF complet dans le lecteur + compagnon complet | ~60-70 % du papier, via crédits Google Play (`verify-purchase` existant) |

L'activation offerte avec le papier protège le circuit de distribution physique
(un livre photocopié n'a pas de code → pas de corrigés, pas de crédits) tout en
créant un argument de vente unique : *« le seul fascicule qui répond quand tu le
scannes »*.

---

## 6. Phasage

### Phase 0 — Décisions & fondations (2-3 jours)
- [ ] Choisir le **pilote** → recommandation : **Physique Tle C/D/E/TI**
  (4 séries = le plus grand marché, PDF complet, structure la plus régulière),
  avec **Maths Tle C** en second train immédiat.
- [ ] Figer le registre des préfixes + le format de code (ci-dessus).
- [ ] Valider prix / nb de corrigés gratuits / bonus crédits.

### Phase 1 — MVP connecté sur le pilote (~2 semaines)
- [ ] `tools/setup_fascicule_units.sh` + attributs `code`/`connected` (idempotents).
- [ ] `tools/connect_fascicule.py` : parse les `.tex` du pilote → manifeste JSON
  → upload `fascicule_units` (énoncés + corrigés d'application/sujets).
- [ ] Pré-génération NVIDIA des corrigés d'entraînement du pilote + relecture
  d'échantillons (1 exercice sur 10).
- [ ] App : route `/f`, compagnon chapitre, écran unité, saisie code court,
  intégration Léo contextuel, progression → **patch Shorebird**.
- [ ] Page web `onbuch-go/f/…` (clone adapté de `share/index.html`).
- [ ] Préambule LaTeX : QR chapitre + badges codes courts → **PDF v2 du pilote**.
- [ ] Admin : resource `fascicule_units`.
- 🎯 *Livrable : on scanne le QR du chapitre 7 (chapitre pilote « Oscillateurs
  électriques ») et tout fonctionne de bout en bout.*

### Phase 2 — Activation & monétisation (~1 semaine)
- [ ] Génération des lots de codes + `api/fascicule-activate.js` (Vercel).
- [ ] Écran d'activation + verrouillage/CTA + crédits offerts.
- [ ] Analytics + tableau de bord admin (scans, activations, conversion).

### Phase 3 — Engagement (~1 semaine, parallélisable)
- [ ] Quiz par chapitre (collection `quizzes` existante) + anneaux de progression.
- [ ] Défis hebdo push (« 3 exercices du ch. 5 cette semaine ») via `review-nudge`.
- [ ] Classement par fascicule (brancher la ligue existante).

### Phase 4 — Généralisation (en continu)
- [ ] Dérouler le pipeline sur Maths Tle C, Info, Algo TI, 1000 exos, puis
  compiler et connecter Maths 1ère C et Chimie.
- [ ] Release native groupée : App Link `/f` + scanner in-app.
- [ ] Impression du premier tirage avec codes d'activation ; kit distributeurs
  (librairies, répétiteurs) avec code parrain (système parrainage existant).

---

## 7. Risques & parades

| Risque | Parade |
|---|---|
| Limite de fonctions Appwrite atteinte | Activation sur Vercel `api/` (patron `result-lookup`/`referral`) ✅ prévu |
| Limite de buckets | Réutiliser `annales_files` (PDF v2, couvertures) — pratique déjà établie |
| Qualité des corrigés générés | Pré-génération hors-ligne + relecture par échantillon **avant** publication ; bouton « Signaler une erreur » dans l'écran unité |
| Élèves sans data au moment du scan | Code court imprimé (utilisable plus tard) + cache 5 min + page compagnon légère |
| Photocopie du livre | Corrigés verrouillés sans activation ; 1 code = 2 comptes ; codes hachés côté serveur |
| QR → app non installée | Page `onbuch-go/f` = redirection + argumentaire + lien Play Store (acquisition) |
| Ajout du `pathPrefix` manifeste | Non bloquant : schéma `onbuch://` + page web couvrent le lancement ; à grouper dans la prochaine release |
| 100 déploiements Vercel/jour | Astuce preview + alias déjà documentée (CLAUDE.md §7) |

## 8. KPIs de succès (à 60 jours du lancement pilote)

- **Acquisition** : ≥ 15 % des scans proviennent d'appareils sans l'app (installs attribuées au livre).
- **Activation** : ≥ 60 % des exemplaires vendus activés dans les 7 jours.
- **Engagement** : ≥ 5 unités consultées / élève activé / semaine ; ≥ 30 % font le quiz de chapitre.
- **Monétisation** : ≥ 10 % des utilisateurs gratuits du compagnon précommandent un fascicule.
- **Qualité** : < 2 % d'unités signalées « corrigé erroné ».

---

*Document de travail — branche `claude/fascicules-integration-plan-pr919e`.
Prochaine étape proposée : valider la Phase 0 (pilote + format de codes + prix),
puis lancer la Phase 1.*
