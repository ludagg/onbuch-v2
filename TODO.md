# TODO — OnBuch

Idées et chantiers à réaliser plus tard (notés pour ne pas les perdre).

---

## 🧩 Exercices — génération IA → PDF (admin) (à faire)

Le module Exercices (collections `exercise_chapters`/`exercise_sheets`/`exercise_progress`,
écrans app `/exercices`, ressources back-office) est **en place**. L'admin saisit
aujourd'hui les **URLs de PDF** (énoncé + correction) à la main dans le back-office.

À construire : l'**atelier de génération** côté admin —
- une **fonction Vercel** `api/generate-exercises` (clé NVIDIA côté serveur) qui appelle
  **Nemotron Ultra** pour produire 5 énoncés + corrections d'un chapitre ;
- rendu **HTML (template OnBuch) → PDF** (Puppeteer/Chromium sur un service, ou API HTML→PDF) ;
- upload des PDF dans Storage Appwrite (bucket `annales_files`) + écriture des `exercise_sheets`
  (statementPdfUrl / correctionPdfUrl) ;
- bouton « Générer avec l'IA » dans le back-office (relecture/édition avant publication).

## 📅 Emploi du temps des élèves + alertes (à faire)

Fonctionnalité : chaque élève a sa grille hebdomadaire de cours, avec rappels
avant chaque cours.

### Modèle de données
`TimetableSlot { jour (lun→sam), heureDébut (HH:mm), heureFin, matière, salle?, prof?, couleur }`
— récurrent chaque semaine. (Option v2 : semaine A / semaine B.)

### Saisie (comment la grille entre dans l'app)
1. **Éditeur manuel** : l'élève ajoute ses créneaux (jour, heure, matière, salle). Base fiable, hors-ligne.
2. ⭐ **Import photo → Léo** : l'élève photographie son emploi du temps papier ; le modèle
   vision (Nemotron Omni, déjà utilisé dans `functions/tutor-ai`) en extrait la grille
   structurée → remplissage auto, l'élève corrige. **C'est l'angle signature** (réutilise la vision existante).
   → côté serveur : nouveau mode (ex. `mode: 'timetable'`) dans `tutor-ai` qui renvoie un JSON de créneaux.

### Stockage
- **Local d'abord** (JSON sur disque via le DiskCache / shared_preferences) : instantané, hors-ligne,
  privé, zéro coût backend.
- Sync Appwrite multi-appareils plus tard (collection `timetable` en `read("user:<uid>")`).

### Alertes (⚠️ nécessite une RELEASE, pas un patch)
- Mécanisme = **notifications locales programmées** (`flutter_local_notifications` + `timezone`),
  récurrentes chaque semaine, **fonctionnent hors-ligne**. Le push FCM n'est PAS adapté
  (il faudrait un cron minute par minute).
- Plugins natifs → **release Shorebird** + permissions : Android 13 (POST_NOTIFICATIONS),
  Android 12+ (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM), iOS (autorisation notifications).
- Logique : rappel X min avant chaque cours (5/10/15, réglable).
- **Intelligent** : couper les alertes pendant congés/examens en s'appuyant sur la collection
  `school_calendar` (déjà remplie avec les vraies dates) + un mode « vacances ».
- Attention iOS : limite ~64 notifications locales en attente → utiliser la répétition
  hebdomadaire (peu d'entrées) plutôt que programmer chaque occurrence.

### Placement dans l'app
- Onglet **Campus/Agenda** → section « Mon emploi du temps ».
- Carte **« Prochain cours »** sur l'accueil.

### Bonus / extensions
- Chaque matière liée à son pack de Cours / à Léo (« réviser cette matière »).
- Devoirs attachés à un créneau (échéance + rappel).
- Couleur par matière, vue jour / semaine.

### Plan de livraison suggéré
- **V1 (patchable)** : éditeur manuel + affichage grille + carte « prochain cours ». Pas d'alertes.
- **V2 (release)** : alertes locales + permissions.
- **V3** : import photo Léo + sync cloud + liens vers Cours.
