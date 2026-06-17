# Notifications push (FCM + Appwrite Messaging)

OnBuch reçoit de vraies notifications push — **même app fermée** — via **FCM**
(gratuit, illimité) relayé par **Appwrite Messaging**.

- App **fermée / arrière-plan** → Android affiche la notif dans la barre système.
- App **au premier plan** → bannière in-app (avec bouton « Voir »).
- Un **tap** ouvre l'écran indiqué par le champ `route` du message (ex. `/results`).

> ⚠️ Le push est une fonctionnalité **native** (plugins `firebase_core` /
> `firebase_messaging` + plugin Gradle Google Services). Elle n'est **pas**
> livrable en patch Shorebird silencieux : il faut **rebâtir et redistribuer
> une nouvelle release APK**.

---

## ✅ Déjà fait (côté code)
- Dépendances `firebase_core` + `firebase_messaging` (pubspec).
- `PushService` : permission, récupération du token FCM, enregistrement de la
  cible push Appwrite à la connexion (`account.createPushTarget`), mise à jour au
  refresh du token, suppression à la déconnexion, abonnement optionnel à un topic.
- Handlers premier plan / tap / lancement depuis une notif + navigation `route`.
- `AndroidManifest` : permission `POST_NOTIFICATIONS`.
- Gradle : plugin `com.google.gms.google-services` ajouté.

## À faire de ton côté (une fois)

### 1. Créer un projet Firebase (gratuit)
1. https://console.firebase.google.com → **Add project** (désactive Analytics si
   tu veux, pas nécessaire).
2. **Add app → Android**. Package name : **`cm.luvvix.onbuch`** (exactement).
3. Télécharge **`google-services.json`** et place-le dans **`android/app/google-services.json`**.

> Sans ce fichier, le build Android échoue (le plugin Google Services l'exige).

### 2. Donner les credentials FCM à Appwrite
Appwrite a besoin d'envoyer via FCM en ton nom :
1. Firebase Console → ⚙️ **Project settings → Service accounts** → **Generate new
   private key** → télécharge le JSON.
2. Appwrite Console → **Messaging → Providers → Create provider → FCM (Push)**.
3. Colle le contenu du JSON de service (Service Account) dans le champ demandé.
   Note l'**ID du provider** si tu veux le fixer dans `lib/appwrite_config.dart`
   (`appwriteFcmProviderId`) — sinon laisse vide, ça marche avec un seul provider.

### 3. (Optionnel) Topic « tous » pour diffuser à tout le monde
Pour pouvoir envoyer un push « à tous » en un clic :
1. Appwrite Console → **Messaging → Topics → Create topic** → note l'ID.
2. Renseigne cet ID dans `lib/appwrite_config.dart` → `appwritePushTopicId`.
   Chaque appareil connecté s'y abonnera automatiquement.

Sans topic, tu peux quand même cibler **Users** (sélection) à l'envoi : chaque
utilisateur connecté possède déjà une cible push enregistrée.

### 4. Rebâtir et redistribuer la release
Native = nouvelle release (pas de patch) :
```bash
flutter pub get
shorebird release android --artifact=apk   # ou aab pour le Play Store
```
Distribue le nouvel APK. Les futures montées **de code Dart** repartiront en
`shorebird patch`.

---

## Envoyer une notification
Appwrite Console → **Messaging → Messages → Create message → Push** :
- **Title** / **Body**.
- **Data (key/value)** : ajoute `route` = `/results` (ou `/notifications`,
  `/annales`…) pour que le tap ouvre directement le bon écran.
- **Cible** : le **Topic** (si configuré) ou des **Users**.

> Astuce : crée aussi un document dans la collection `notifications` (même titre
> / corps / route) pour que l'alerte reste consultable dans le **centre de
> notifications** in-app, pas seulement dans la barre système.

## Dépannage
- **Rien ne s'affiche, app fermée** : vérifie que `google-services.json` est bien
  celui du package `cm.luvvix.onbuch`, et que le provider FCM Appwrite utilise la
  clé de **service account** du **même** projet Firebase.
- **Premier plan seulement** : normal côté Android que la notif système
  n'apparaisse pas au premier plan — on montre une bannière in-app à la place.
- **Android 13+** : l'utilisateur doit accepter la permission notifications
  (demandée au 1er lancement).
