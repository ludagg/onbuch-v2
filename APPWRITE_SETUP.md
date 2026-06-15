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
Profil utilisateur, document keyé par l'ID Appwrite Auth.
Attributs :
- `firstName` (string, 100, **required**)
- `lastName` (string, 100)
- `email` (string, **required**)
- `password` (string, 255) — **non utilisé / optionnel** : l'authentification est
  gérée par Appwrite Auth, l'app ne stocke aucun mot de passe ici.
- `role` (string) · `phoneNumber` (string)
- `classe` (string, 50)
- `examen` (string, 50)
- `serie` (string, 40)
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

### Collection `articles` (fil OnBuch / actualités)
Attributs :
- `title` (string, 200, required)
- `category` (string, 50) — ex. `Examens`, `Bourses`, `Conseil`, `Concours`, `Alerte`
- `source` (string, 60) — défaut `OnBuch`
- `imageUrl` (string, 500) — URL de l'image (optionnel)
- `body` (string, 5000) — contenu de l'article (optionnel)
- `featured` (boolean) — `true` pour l'article mis en avant (carte vedette)
- `publishedAt` (datetime) — sinon `$createdAt` est utilisé

Permissions : Read `any` (le fil est public), Write réservé à l'admin.
Les articles sont triés du plus récent au plus ancien.

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
