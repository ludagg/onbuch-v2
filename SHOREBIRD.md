# Mise à jour silencieuse (Shorebird Code Push)

OnBuch reçoit les mises à jour **du code Dart** sans réinstallation et sans
repasser par le store : à l'ouverture, le correctif est téléchargé en arrière-plan
et appliqué au redémarrage suivant. **Silencieux.**

> ⚠️ Patche le **code Dart** uniquement. Un changement **natif** (nouveau plugin
> natif, permissions, AndroidManifest, montée de Flutter) demande une **nouvelle
> release** (un nouvel APK à distribuer).
>
> Exemple : l'ajout du **push (FCM)** est natif → nouvelle release requise
> (voir `PUSH.md`), pas un patch.

## ✅ Déjà fait
- App Shorebird **créée** (`app_id` dans `shorebird.yaml`, bundlé via `pubspec.yaml`).
- Workflow CI `.github/workflows/shorebird.yml` (déclenchement manuel : `release` / `patch`).

## À faire de ton côté (une fois)
1. **Régénérer ton token** Shorebird (il a transité dans le chat) sur
   https://console.shorebird.dev.
2. Ajouter le secret repo **`SHOREBIRD_TOKEN`** : GitHub → repo → Settings →
   Secrets and variables → Actions → New repository secret.
3. **Première release** (depuis ta machine, où Flutter + Android sont installés) :
   ```bash
   flutter pub get
   shorebird release android
   ```
   → distribue l'APK généré (WhatsApp, site…). C'est la version « socle ».

## Pousser une mise à jour silencieuse
Après une modif de **code Dart** (et que la release socle est installée) :
- soit en local : `shorebird patch android`
- soit via GitHub : Actions → **Shorebird** → Run workflow → `patch`.

> Important : un `patch` doit cibler une `release` faite avec la **même version
> de Flutter**. Quand tu changes de version Flutter ou du natif → refais une
> `release` (nouvel APK), puis repars en `patch`.

## Tarif
Offre gratuite pour petits volumes, puis paliers payants (voir shorebird.dev).
