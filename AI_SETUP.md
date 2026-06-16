# Tuteur IA — Architecture (proxy Appwrite + API NVIDIA)

Le Tuteur IA envoie la photo d'un exercice à un modèle vision NVIDIA (API
compatible OpenAI) et renvoie une correction étape par étape.

## Architecture sécurisée (proxy)
```
App Flutter  ──(image base64)──►  Fonction Appwrite "tutor-ai"  ──►  NVIDIA
   (session utilisateur)              (détient NVIDIA_API_KEY)
```
La clé NVIDIA **n'est jamais sur le téléphone** : elle vit dans les variables
d'environnement de la fonction Appwrite. L'app appelle la fonction via le SDK
Appwrite (authentifiée), envoie l'image, reçoit `{ "correction": "…" }`.

- L'app **ne contient aucune clé** et n'a pas besoin de `--dart-define`.
- Build standard : `flutter pub get && flutter build apk --release`.
- ⚠️ Build natif complet requis (dépendance native `image_picker`).

## Fonction Appwrite `tutor-ai`
- Code versionné dans `functions/tutor-ai/` (runtime `node-22`, entrypoint `src/main.js`).
- Exécutable par les utilisateurs connectés (`execute: ["users"]`).
- Variables d'environnement (Console → Functions → tutor-ai → Settings → Variables) :
  - `NVIDIA_API_KEY` = `nvapi-…` (**secret**, défini).
  - `NVIDIA_MODEL` = `meta/llama-4-maverick-17b-128e-instruct` (multimodal, testé et validé ; modifiable).

> ⚠️ Les variables sont injectées **au build** : après modification d'une variable, **redéployer** la fonction pour qu'elle prenne effet.

### Redéployer après modification du code
Depuis la Console (Function → Deployments → Create) ou via le CLI Appwrite, en
pointant sur `functions/tutor-ai/` (entrypoint `src/main.js`, commande `npm install`).

## Détails techniques
- Endpoint NVIDIA : `https://integrate.api.nvidia.com/v1/chat/completions`.
- L'app redimensionne/recompresse l'image en JPEG **sous ~170 Ko** (limite NVIDIA
  de 180 Ko pour une image base64 inline) dans un isolate, avant l'envoi.
