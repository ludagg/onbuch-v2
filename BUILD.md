# BUILD.md — Compiler & publier OnBuch (mobile)

> Depuis la perte du VPS Contabo, **les builds/patches se font dans
> l'environnement d'exécution Claude Code** (remote, **éphémère** : tout est
> réinitialisé après inactivité → la chaîne doit être réinstallée à chaque
> nouvelle session). Ce fichier décrit le process de bout en bout pour ne rien
> oublier.

---

## 0. TL;DR

```bash
# 1) Installer la chaîne (Shorebird + Flutter + SDK Android) — ~10–15 min
bash tools/setup_build_env.sh

# 2) Exporter l'environnement (le script affiche les lignes exactes à la fin)
export ANDROID_SDK_ROOT=/root/android-sdk ANDROID_HOME=/root/android-sdk
export GIT_CONFIG_GLOBAL=/tmp/onbuch-build/build.gitconfig GIT_CONFIG_SYSTEM=/dev/null
export PATH="$HOME/.shorebird/bin:$HOME/.shorebird/bin/cache/flutter/<rev>/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
export SHOREBIRD_TOKEN="<token>"           # jamais commité

# 3) Déposer la signature (cf. §3) : android/key.properties + android/app/onbuch-release.keystore

# 4) Choisir le numéro de version (cf. §4), puis :
#    - changement DART/ASSET seulement  -> PATCH (silencieux, pas de store)
shorebird patch android --release-version=<x.y.z+n> -- --no-tree-shake-icons
#    - changement NATIF (plugin, gradle, manifeste, icône native) -> RELEASE
shorebird release android -- --no-tree-shake-icons
```

---

## 1. Pré-requis de l'environnement

La machine Claude Code a déjà : **Java**, **Gradle**, `git`, `curl`, `unzip`.
Manquent (installés par `tools/setup_build_env.sh`) : **Shorebird CLI**,
**Flutter** (embarqué par Shorebird), **SDK Android + NDK 26.3.11579264 +
build-tools 35/36 + platforms 35/36**.

### Particularité réseau (IMPORTANT)
- La sortie HTTPS passe par un **proxy** (`$HTTPS_PROXY`), CA à
  `/root/.ccr/ca-bundle.crt`.
- Le **Git est restreint au repo en scope** (`ludagg/onbuch-v2`) : tout
  `git clone` externe (Shorebird, Flutter) renvoie **403** via l'endpoint
  GitHub scoped.
- **Contournement légitime** : router les clones externes par le **proxy de
  sortie** avec un gitconfig dédié (sans l'`insteadOf` qui pointe vers
  l'endpoint scoped). C'est ce que fait `tools/setup_build_env.sh` :

  ```ini
  # /tmp/onbuch-build/build.gitconfig
  [http]
      proxy = http://127.0.0.1:38575      # = $HTTPS_PROXY (le port peut varier)
      sslCAInfo = /root/.ccr/ca-bundle.crt
  ```
  On l'active **uniquement** pour les commandes de build via
  `GIT_CONFIG_GLOBAL=…/build.gitconfig GIT_CONFIG_SYSTEM=/dev/null`.
  ⚠️ Ne **jamais** le mettre en global permanent : les `git push` vers
  `ludagg/onbuch-v2` doivent garder l'endpoint scoped (auth injectée).

---

## 2. Secrets nécessaires (jamais commités)

| Secret | Rôle | Où il vit |
|---|---|---|
| **Keystore** `onbuch-release.keystore` (alias `onbuch`) | signe l'AAB/APK pour le store | sauvegarde chiffrée sur **Cloudflare R2** (`r2:onbuch/keystore-backup/…enc`) + 3 copies |
| **Mots de passe** (storePassword, keyPassword) | ouvrent le keystore | archive chiffrée + gestionnaire de mots de passe |
| **Phrase de passe** de l'archive `.enc` | déchiffre la sauvegarde keystore | **gestionnaire de mots de passe** (ne vit pas dans le repo) |
| **Token Shorebird** `SHOREBIRD_TOKEN` | publie release/patch | gestionnaire de mots de passe ; passé en env à la session |

### Récupérer & déchiffrer le keystore
```bash
# depuis n'importe quel rclone configuré sur le bucket R2 "onbuch"
rclone copy r2:onbuch/keystore-backup/onbuch-keystore-backup-<id>.tar.gz.enc .
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in onbuch-keystore-backup-<id>.tar.gz.enc \
  -pass pass:'<PHRASE_DE_PASSE>' | tar xzv
# -> onbuch-release.keystore, onbuch-release.credentials.txt, shorebird-token.txt
```

> ⚠️ Si un secret est passé en clair dans un chat, le **régénérer** ensuite
> (token Shorebird ; re-chiffrer l'archive avec une nouvelle phrase de passe).
> Le **keystore lui-même ne se change pas** (c'est la clé d'upload Play).

---

## 3. Configurer la signature de release

`android/app/build.gradle.kts` lit `android/key.properties` (gitignoré ;
repli sur la clé debug s'il est absent). À déposer avant de builder :

```properties
# android/key.properties   (NE PAS committer — déjà gitignoré)
storePassword=<…>
keyPassword=<…>
keyAlias=onbuch
storeFile=onbuch-release.keystore
```
…et copier le keystore : `cp onbuch-release.keystore android/app/`
(`**/*.keystore` est gitignoré).

Vérifier la signature d'un artefact :
```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA256
# APK (signature v2+) :
$ANDROID_SDK_ROOT/build-tools/35.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
# doit afficher : SHA-256 b4d15092184b790f2f21e1d01ccbbc36afa5ea47b9b269569bdc030dd01f6165
```

---

## 4. Versioning

- `version:` dans `pubspec.yaml` = `1.0.0+<buildNumber>`.
- Le `+buildNumber` = **versionCode** Android : doit être **strictement
  supérieur** au dernier publié.
- **Toujours** vérifier le dernier numéro pris sur Shorebird avant de choisir :
  ```bash
  shorebird releases list        # prendre max(+n) puis +1
  ```
  (Historique : releases +1 … +33 ; +33 = build du 2026-06-27 incluant les
  notifications, le leaderboard, etc.)

---

## 5. Release vs Patch (quand choisir quoi)

| Type de changement | Action | Effet |
|---|---|---|
| Dart, assets, images, textes, logique UI | **`shorebird patch`** | livré **silencieusement** aux utilisateurs de la release ciblée, sans store |
| Nouveau plugin / dépendance native, `AndroidManifest`, `build.gradle`, NDK, icône d'app native, permission | **`shorebird release`** (nouvel AAB) | nécessite **upload Play Store** |

```bash
# PATCH (sur une release existante)
shorebird patch android --release-version=1.0.0+33 -- --no-tree-shake-icons

# RELEASE (nouvelle version)
shorebird release android -- --no-tree-shake-icons
# -> build/app/outputs/bundle/release/app-release.aab  (à uploader sur la Play Console)
```

> `--no-tree-shake-icons` : garde la **police d'icônes complète** pour que de
> nouvelles icônes Material puissent arriver par **patch** sans release.

### APK de release (installation directe / GitHub)
```bash
flutter build apk --release --no-tree-shake-icons
# -> build/app/outputs/flutter-apk/app-release.apk  (signé clé d'upload, non patchable)
```

---

## 6. Livraison des artefacts

- Le MCP GitHub **ne crée pas** de Release avec binaires → on **livre les
  fichiers directement** (outil d'envoi de fichiers de la session) ; l'humain
  uploade ensuite l'AAB sur la Play Console (et/ou attache l'APK à une Release
  GitHub à la main).
- Web : `flutter build web --release` (Flutter stable complet requis), déployé
  sur Vercel (cf. `CLAUDE.md` §6/§7).

---

## 7. Checklist release

1. `bash tools/setup_build_env.sh` (si nouvelle session)  
2. exporter env + `SHOREBIRD_TOKEN`  
3. déposer `android/key.properties` + keystore (§3)  
4. `flutter pub get` && `flutter analyze` (0 erreur attendu)  
5. choisir le numéro (`shorebird releases list` → +1), bumper `pubspec.yaml`  
6. `shorebird release android -- --no-tree-shake-icons`  
7. vérifier la signature (§3), construire l'APK  
8. livrer AAB + APK, committer le bump de version  
9. uploader l'AAB sur la Play Console
