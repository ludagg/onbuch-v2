# Configuration Firebase pour OnBuch

Ce guide t'explique comment connecter ton projet Firebase à l'application OnBuch.

---

## Étape 1 — Créer un projet Firebase

1. Va sur [https://console.firebase.google.com](https://console.firebase.google.com)
2. Clique **"Créer un projet"**
3. Donne-lui un nom (ex: `onbuch-prod`)
4. Active Google Analytics si souhaité → clique **Continuer**
5. Attends la création du projet

---

## Étape 2 — Activer les services nécessaires

Dans ton projet Firebase, active :

### Firebase Auth
- Menu **Authentication** → **Commencer**
- Onglet **Méthode de connexion** → activer **E-mail/Mot de passe**

### Cloud Firestore
- Menu **Firestore Database** → **Créer une base de données**
- Choisis le mode **Production** (règles sécurisées)
- Sélectionne une région proche (ex: `europe-west1`)

### Firebase Cloud Messaging
- Activé automatiquement — rien à faire

### Firebase Analytics
- Activé si tu as coché "Activer Google Analytics" à l'étape 1

---

## Étape 3 — Ajouter l'application Android

1. Dans la vue d'ensemble du projet, clique l'icône **Android** (Ajouter une appli)
2. **Nom du package Android** : `cm.luvvix.onbuch`
3. **Surnom de l'appli** : `OnBuch` (facultatif)
4. **Certificat SHA-1** : optionnel pour l'instant (nécessaire pour Google Sign-In)
5. Clique **Enregistrer l'appli**

---

## Étape 4 — Télécharger google-services.json

1. Sur la page suivante, télécharge le fichier `google-services.json`
2. Place-le ici dans ton projet :

```
android/
  app/
    google-services.json   ← ici
    build.gradle.kts
    ...
```

> **Important** : Ne commite JAMAIS ce fichier dans un dépôt public.
> Ajoute `android/app/google-services.json` à ton `.gitignore`.

---

## Étape 5 — Remplir firebase_options.dart

Ouvre `lib/firebase_options.dart` et remplace les valeurs placeholder.

### Option A — Automatique (recommandée)

Installe FlutterFire CLI et laisse-le générer le fichier :

```bash
# Installer la CLI
dart pub global activate flutterfire_cli

# Configurer (depuis la racine du projet)
flutterfire configure
```

Sélectionne ton projet Firebase et les plateformes souhaitées.
Le fichier `lib/firebase_options.dart` sera entièrement régénéré.

### Option B — Manuelle

Dans `lib/firebase_options.dart`, section `android`, remplace :

| Clé | Où la trouver |
|-----|---------------|
| `apiKey` | `google-services.json` → `client[0].api_key[0].current_key` |
| `appId` | `google-services.json` → `client[0].client_info.mobilesdk_app_id` |
| `messagingSenderId` | `google-services.json` → `project_info.project_number` |
| `projectId` | `google-services.json` → `project_info.project_id` |
| `storageBucket` | `google-services.json` → `project_info.storage_bucket` |

---

## Étape 6 — Règles Firestore

Dans la console Firebase → Firestore → **Règles**, colle ces règles de départ :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Un utilisateur ne peut lire/écrire que son propre profil
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Ses résultats sauvegardés
      match /results/{resultId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## Étape 7 — Vérifier

```bash
cd /home/claude/onbuch
flutter pub get
flutter analyze
flutter run
```

Si tout est correct, l'application démarrera et Firebase sera initialisé au lancement.

---

## Topics FCM suggérés

Le service `FcmService` supporte les topics. Tu peux y abonner les utilisateurs :

```dart
await FcmService().subscribeToTopic('resultats-bac-2026');
await FcmService().subscribeToTopic('alertes-onbuch');
await FcmService().subscribeToTopic('annales-nouvelles');
```

Pour envoyer une notification à un topic depuis la console Firebase :
**Messaging** → **Nouvelle campagne** → **Notifications** → sélectionne un topic.

---

## Fichiers modifiés par cette intégration

| Fichier | Modification |
|---------|-------------|
| `pubspec.yaml` | Ajout des 5 packages Firebase |
| `android/settings.gradle.kts` | Plugin Google Services déclaré |
| `android/app/build.gradle.kts` | Plugin Google Services appliqué |
| `lib/main.dart` | `Firebase.initializeApp()` ajouté |
| `lib/firebase_options.dart` | Créé — à remplir avec tes valeurs |
| `lib/services/auth_service.dart` | Créé — Auth email/password |
| `lib/services/firestore_service.dart` | Créé — CRUD profils et résultats |
| `lib/services/fcm_service.dart` | Créé — Notifications push |
| `lib/services/analytics_service.dart` | Créé — Tracking événements |
| `lib/screens/onboarding/auth_phone_screen.dart` | Réécrit — Email/password UI |
| `lib/screens/onboarding/profile_setup_screen.dart` | Connecté à Firestore |
| `lib/router/app_router.dart` | Route `/auth/otp` supprimée |
