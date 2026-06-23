# Publication Play Store — OnBuch

Guide du **build signé** et des **assets** pour publier sur Google Play.
Compte développeur + entrée de l'app dans la Play Console : déjà créés.

`applicationId` : `cm.luvvix.onbuch` · version actuelle : `1.0.0+1` (pubspec).

---

## 1. Vue d'ensemble (signature)

Le `build.gradle.kts` lit désormais la signature release depuis
**`android/key.properties`** (git-ignoré). Si ce fichier est absent, le build
release retombe sur la clé **debug** (pratique pour `flutter run --release` en
local, **mais un AAB signé debug est REFUSÉ par le Play Store**).

> Google **Play App Signing** : tu uploades un AAB signé avec ta clé d'**upload**,
> et Google re-signe l'app avec sa propre clé d'app pour la distribution. Le
> keystore décrit ci-dessous est donc ta **clé d'upload**.

---

## 2. Générer le keystore d'upload (une seule fois)

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- Place le fichier `upload-keystore.jks` dans le dossier **`android/`**
  (à côté de `app/`).
- Note bien le **mot de passe du store**, le **mot de passe de la clé** et
  l'**alias** (`upload`).

⚠️ **Ce keystore est irremplaçable** : sa perte = impossible de publier une
mise à jour (sauf reset de clé via le support Google). Le sauvegarder **hors
repo** (gestionnaire de mots de passe / coffre). Ne JAMAIS le committer
(`.gitignore` bloque déjà `**/*.jks`, `**/*.keystore`, `android/key.properties`).

Puis créer **`android/key.properties`** (copie de `android/key.properties.example`) :

```properties
storePassword=<mot de passe du store>
keyPassword=<mot de passe de la clé>
keyAlias=upload
storeFile=upload-keystore.jks
```

> `storeFile` est relatif au dossier `android/`.

---

## 3. Construire l'AAB (Android App Bundle)

Build sur le serveur Contabo (Flutter 3.44.2), comme le reste du projet.

```bash
# Incrémenter le build number à CHAQUE upload (versionCode unique exigé par Play).
flutter build appbundle --release --build-name=1.0.0 --build-number=1
```

→ `build/app/outputs/bundle/release/app-release.aab`

Avec **Shorebird** (cf. CLAUDE.md §6) :

```bash
shorebird release android --build-name=1.0.0 --build-number=1
```

> Rappel versions : `--build-name` = versionName (ex. `1.0.0`),
> `--build-number` = versionCode (entier **strictement croissant** à chaque
> dépôt). 1.0.0+1 → 1.0.0+2 → …

### Vérifier la signature de l'AAB

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head
# doit afficher "jar verified" et l'alias "upload" (PAS "Android Debug").
```

---

## 4. Icône de l'app

L'icône (logo squircle orange OnBuch) est **déjà générée et commitée** :
- legacy : `android/app/src/main/res/mipmap-*/ic_launcher.png`
- adaptative : `mipmap-*/ic_launcher_foreground.png` + `mipmap-anydpi-v26/ic_launcher.xml`
  (fond blanc `@color/ic_launcher_background`)

Pour la **régénérer** après modif du logo (`assets/icon/icon.png` et
`assets/icon/foreground.png`) :

```bash
dart run flutter_launcher_icons
```

Config dans `pubspec.yaml` (section `flutter_launcher_icons`).

---

## 5. Assets de la fiche Play Store

| Asset | Format | Statut |
|---|---|---|
| Icône appli | 512×512 PNG 32 bits | ✅ `docs/store-assets/play_icon_512.png` |
| Feature graphic | 1024×500 PNG/JPG | ✅ `docs/store-assets/feature_graphic.png` (v1) + `feature_graphic_v2.png` (v2) — en choisir un |
| Captures téléphone | min. 2, 16:9 ou 9:16, 320–3840 px | ⬜ à faire (Tableau, Tuteur, Cours, Résultats) |
| Captures tablette (option.) | 7" / 10" | ⬜ optionnel |

> Pour le feature graphic et les captures stylisées, on peut utiliser Léo
> (`assets/images/leo_*.png`) sur fond orange de marque.

---

## 6. Étapes Play Console (rappel)

1. **Release → Testing → Internal testing** : uploader l'AAB d'abord en test
   interne, valider l'install et le parcours sur un appareil réel.
2. **Store listing** : nom, description courte/longue, icône, feature graphic,
   captures.
3. **Data safety** : déclarer les données collectées (compte e-mail via
   Appwrite, contenu utilisateur Tuteur, jetons FCM). Caméra = traitée à l'appareil.
4. **Content rating** : remplir le questionnaire (app éducative).
5. **App access** : fournir un compte de test si du contenu est derrière login.
6. **Privacy policy** : URL **obligatoire** (à héberger, ex. page Vercel).
7. Promouvoir la release de test interne vers **Production** une fois validée.

> Les volets 2–6 (textes, data safety, privacy policy) ne sont pas couverts par
> ce commit — demander si besoin d'aide dessus.
