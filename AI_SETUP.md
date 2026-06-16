# Tuteur IA — Architecture

Photo d'un exercice → correction pédagogique riche (Markdown + LaTeX + tableaux
+ graphiques), via les modèles NVIDIA, derrière un proxy serveur.

## Flux
```
App ─(image, jobId, async)─► Fonction Appwrite "tutor-ai" ─► NVIDIA
 │                              1) VISION  : transcrit la photo (Llama 4 Maverick)
 │                              2) RAISONNE: corrige (DeepSeek V4)
 │                              puis écrit le résultat dans tutor_jobs/{jobId}
 └─(poll getDocument tutor_jobs/{jobId})──────────────────────────┘
```
- **Asynchrone + base** : une correction prend 15-30 s (au-delà de la limite des
  exécutions *synchrones* d'Appwrite). La fonction écrit `{status, correction|error}`
  dans `tutor_jobs/{jobId}` ; l'app interroge ce document jusqu'à `done`/`error`.
- La clé NVIDIA **n'est jamais sur le téléphone** (variable serveur de la fonction).
- L'app **ne contient aucune clé** : build standard `flutter pub get && flutter build apk --release`.
- ⚠️ Build natif complet requis (dépendances natives `image_picker`).

## Rendu riche (app)
`RichAnswer` (lib/widgets/rich_answer.dart) rend :
- Markdown + **LaTeX** + tableaux (`gpt_markdown`).
- Graphiques via blocs ```onbuch-plot { ...json... }``` → `fl_chart` (courbes/barres).

## Fonction Appwrite `tutor-ai`
- Code : `functions/tutor-ai/` (runtime `node-22`, entrypoint `src/main.js`, timeout 120 s).
- Exécutable par les utilisateurs connectés (`execute: ["users"]`).
- Variables d'environnement :
  - `NVIDIA_API_KEY` = `nvapi-…` (**secret**).
  - `VISION_MODEL` = `meta/llama-4-maverick-17b-128e-instruct` (transcription photo).
  - `NVIDIA_MODEL` = `deepseek-ai/deepseek-v4-flash` (raisonnement ; `-pro` = +qualité/-vitesse).
  - `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT`, `APPWRITE_API_KEY` (**secret**), `DATABASE_ID`,
    `JOBS_COLLECTION` → pour écrire le résultat dans `tutor_jobs`.

> ⚠️ Les variables sont injectées **au build** : après modification, **redéployer**.

### Redéployer
Console (Function → Deployments → Create) ou CLI Appwrite, en pointant sur
`functions/tutor-ai/` (entrypoint `src/main.js`, commande `npm install`).

## Collection `tutor_jobs`
`status` (pending/done/error), `correction`, `error`, `createdAt`.
`documentSecurity: true` — chaque job n'est lisible que par l'utilisateur qui l'a lancé.

## Détails NVIDIA
- Endpoint : `https://integrate.api.nvidia.com/v1/chat/completions` (compatible OpenAI).
- L'app recompresse l'image en JPEG **sous ~170 Ko** (limite NVIDIA de 180 Ko) avant l'envoi.
