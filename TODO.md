# TODO — OnBuch

Idées et chantiers à réaliser plus tard (notés pour ne pas les perdre).

---

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
