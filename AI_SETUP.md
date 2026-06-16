# Tuteur IA — Configuration (API NVIDIA)

Le Tuteur IA envoie la photo d'un exercice à un modèle vision NVIDIA (API
compatible OpenAI) et renvoie une correction étape par étape.

## Clé API
La clé NVIDIA (`nvapi-…`) n'est **jamais** dans le code. Elle est injectée au
build via `--dart-define` :

```bash
flutter pub get

# Debug
flutter run --dart-define=NVIDIA_API_KEY=nvapi-XXXXXXXX

# Release APK
flutter build apk --release --dart-define=NVIDIA_API_KEY=nvapi-XXXXXXXX
```

Obtenir une clé : https://build.nvidia.com (Get API Key).

## Modèle (optionnel)
Par défaut : `qwen/qwen2.5-vl-72b-instruct` (excellent en maths/manuscrit).
Pour en changer :

```bash
--dart-define=NVIDIA_MODEL=meta/llama-3.2-90b-vision-instruct
```

## Détails techniques
- Endpoint : `https://integrate.api.nvidia.com/v1/chat/completions`
- L'image est redimensionnée/recompressée en JPEG pour rester **sous ~170 Ko**
  (limite NVIDIA de 180 Ko pour une image base64 inline), dans un isolate.
- Le prompt système cadre une correction pédagogique en français.

## ⚠️ Sécurité
Mode actuel : **appel direct depuis l'app**. La clé est injectée au build mais
reste techniquement extractible d'un APK distribué. Pour la production, prévoir
un **proxy serveur** (Appwrite Function) détenant la clé + quota — la logique
client (`TutorService`) est déjà isolée pour faciliter ce basculement.
