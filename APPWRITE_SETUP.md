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

### Collection `exam_results` (résultats publiés — recherche)
Attributs :
- `examType` (string, 60, required) — ex. `Baccalauréat`, `Probatoire`, `BEPC`,
  `GCE O Level`, `GCE A Level`, `BTS`, `Université` (doit matcher le sélecteur app)
- `serie` (string, 10) — ex. `D` (optionnel)
- `year` (string, 10) — ex. `2026`
- `tableNumber` (string, 40, required) — n° de table / candidat (clé de recherche)
- `candidateName` (string, 160, required)
- `center` (string, 160) · `city` (string, 80)
- `admitted` (boolean, required)
- `mention` (string, 40) · `average` (string, 20) — cas admis
- `threshold` (string, 20) — moyenne d'admissibilité (cas non admis)

Index **`idx_lookup`** (type key) sur `examType` + `tableNumber` pour la recherche.
Permissions : Read `any`, Write admin. La recherche se fait par `examType` +
`tableNumber`. Script de création : `tools/setup_exam_results_collection.sh`.

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

### Collection `notifications` (centre de notifications)
Attributs :
- `title` (string, 200, required)
- `body` (string, 1000) — texte de la notification (optionnel)
- `type` (string, 30) — `result` · `exam` · `credit` · `course` · `promo` · `info`
  (détermine l'icône et la couleur ; défaut `info`)
- `route` (string, 200) — lien interne ouvert au tap, ex. `/results` (optionnel)
- `imageUrl` (string, 500) — optionnel
- `publishedAt` (datetime) — sinon `$createdAt` est utilisé

Permissions : Read `any`, Write réservé à l'admin. Triées du plus récent au plus
ancien. L'état « lu / non lu » est géré **localement** sur l'appareil (aucune
écriture côté serveur n'est nécessaire).

## 4. Permissions
Pour chaque collection, ajouter :
- Read: `user:[USER_ID]` (ou `any` pour les events)
- Write: `user:[USER_ID]`

## 5. Ajouter la plateforme Android
Appwrite Console → Settings → Platforms → Add Platform → Android
- Package Name: `cm.luvvix.onbuch`

## 6. Push Notifications (FCM)
Le code push est implémenté (FCM + Appwrite Messaging). La configuration pas à
pas (projet Firebase, `google-services.json`, provider FCM Appwrite, topic,
envoi d'un message) est décrite dans **`PUSH.md`**.
⚠️ C'est une fonctionnalité **native** → nécessite une **nouvelle release APK**
(non patchable par Shorebird).

## 7. Build
```bash
git pull
flutter pub get
flutter build apk --debug
```
