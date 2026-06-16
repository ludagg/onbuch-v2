# Mise à jour silencieuse (Shorebird Code Push)

OnBuch peut recevoir des mises à jour **du code Dart** sans réinstallation et
sans repasser par le store : à l'ouverture de l'app, le correctif est téléchargé
en arrière-plan et appliqué au redémarrage suivant. C'est **silencieux**.

> ⚠️ Shorebird met à jour le **code Dart** (écrans, logique, UI). Les changements
> **natifs** (nouveau plugin natif, permissions, AndroidManifest, montée de
> version Flutter) nécessitent une **nouvelle release** (un nouvel APK).

## 1. Créer le compte (une fois — à faire par toi)
```bash
# Installer le CLI
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sS | bash

shorebird login        # crée/associe ton compte Shorebird
shorebird init         # génère shorebird.yaml (contient l'app_id) à la racine
```
`shorebird init` crée le fichier **`shorebird.yaml`** avec ton `app_id`.
➡️ **Commits ce fichier** (ou donne-le-moi pour que je le commite).

## 2. Publier la version socle (release)
À chaque version « de base » distribuée (APK à partager) :
```bash
shorebird release android \
  --dart-define=... (si besoin)
# -> produit l'APK à distribuer (WhatsApp, site…)
```

## 3. Pousser une mise à jour silencieuse (patch)
Après une modif de **code Dart** (corrections, UI, logique) :
```bash
shorebird patch android
```
Tous les téléphones ayant la release reçoivent le patch automatiquement.

## Notes
- Le **CI** peut automatiser `shorebird patch` à chaque merge sur `main` (je peux
  préparer le workflow une fois l'`app_id` connu).
- Tarif : offre gratuite pour petits volumes, puis paliers payants (voir
  shorebird.dev au moment de t'inscrire).
- Côté app : **rien à coder** — Shorebird agit au niveau du moteur Flutter.

## Ce qu'il me faut de toi
- Lance `shorebird init` et donne-moi le `shorebird.yaml` (ou commits-le), et je
  finalise (doc de build, CI de patch automatique).
