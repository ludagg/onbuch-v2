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

### Collection `courses` (cours & fiches de révision)
Une seule collection pour les **cours** et les **fiches** : l'attribut `kind` fait
la distinction. Le corps `body` accepte la **même syntaxe que le Tuteur** (Markdown,
LaTeX `\( \)` / `\[ \]`, tableaux, blocs `onbuch-plot`) car il est rendu par le même
widget `RichAnswer`.

Attributs :
- `title` (string, 200, **required**) — titre du chapitre / de la fiche
- `subject` (string, 40, **required**) — clé matière, **exactement** l'une de :
  `maths`, `pc`, `svt`, `francais`, `philo`, `anglais`, `histgeo`
- `kind` (string, 20) — `cours` (défaut) ou `fiche`
- `body` (string, 100000) — contenu riche (Markdown / LaTeX / `onbuch-plot`)
- `summary` (string, 500) — court teaser affiché dans les listes
- `classe` (string, 50) — = `users.classe` ; **laisser vide = visible par toutes les classes**
- `examen` (string, 50) — = `users.examen` ; vide = tous les examens
- `serie` (string, 40) — = `users.serie` ; vide = toutes les séries
- `order` (integer) — ordre dans la matière (défaut 0)
- `chapter` (string, 60) — regroupement optionnel (en-têtes de section)
- `premium` (boolean) — `true` affiche le badge PREMIUM

Index (nécessaires aux requêtes) : `subject` (ASC), `order` (ASC), composite
`subject`+`order`, et un index sur `classe` / `serie` si tu filtres côté serveur.

Permissions : **collection-level** Read `any` (les cours sont publics), Write réservé
aux équipes `admins` / `editors` — identique à `articles`. Le filtrage par classe /
série se fait côté app : un contenu à `classe`/`serie` vide s'applique à tout le monde.

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
