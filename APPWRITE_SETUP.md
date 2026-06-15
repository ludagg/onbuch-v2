# Configuration Appwrite — OnBuch V2

## 1. Créer un projet Appwrite
- Va sur https://cloud.appwrite.io
- Crée un compte → New Project → nom "onbuch"
- Copie le **Project ID**

## 2. Configurer `lib/appwrite_config.dart`
Remplace `YOUR_PROJECT_ID` par ton Project ID.

## 3. Créer la base de données
Dans Appwrite Console → Databases → Create database → ID: `main`

### Collection `users`
Attributs :
- `nom` (string, 100, required)
- `classe` (string, 50)
- `examen` (string, 50)
- `serie` (string, 20)
- `createdAt` (datetime)

### Collection `results`
Attributs :
- `userId` (string, 50, required)
- `exam` (string, 50)
- `year` (string, 10)
- `mention` (string, 50)
- `savedAt` (datetime)

### Collection `analytics_events`
Attributs :
- `name` (string, 100)
- `params` (string, 500)
- `timestamp` (datetime)

## 4. Permissions
Pour chaque collection, ajouter :
- Read: `user:[USER_ID]` (ou `any` pour les events)
- Write: `user:[USER_ID]`

## 5. Ajouter la plateforme Android
Appwrite Console → Settings → Platforms → Add Platform → Android
- Package Name: `cm.luvvix.onbuch`

## 6. Push Notifications (optionnel)
Appwrite Console → Messaging → Providers → Add FCM provider
Nécessite un projet Firebase juste pour FCM (pas de SDK dans l'app).

## 7. Build
```bash
git pull
flutter pub get
flutter build apk --debug
```
