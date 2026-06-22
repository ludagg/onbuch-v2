# CLAUDE.md — OnBuch

Contexte projet pour Claude Code. **App mobile éducative camerounaise** (Flutter)
+ backend Appwrite + back-office web + version web. Objectif produit : « top 1
Afrique » — qualité flagship.

> ⚠️ **Secrets** : ce fichier est versionné sur GitHub. Les **valeurs réelles**
> des clés/tokens n'y figurent **pas** (placeholders uniquement). Voir la section
> « Secrets & accès ».

---

## 1. Présentation

OnBuch aide les élèves/étudiants camerounais : **résultats d'examens**, **Tuteur
IA (Léo)**, **cours**, **concours**, **annales**, **actus**, **agenda scolaire**.
- Package : `cm.luvvix.onbuch` · pubspec `name: onbuch` · version `1.0.0+x`.
- Marché : Cameroun (FR), programme MINESEC ; anglophone (GCE) à venir.

## 2. Stack & architecture

- **Mobile** : Flutter (Dart `^3.8.1`), Flutter **3.44.2** (Dart 3.12.2).
- **Backend** : **Appwrite Cloud** (auth, databases, functions, messaging/FCM).
- **IA** : fonction Appwrite `tutor-ai` → modèles **NVIDIA** (vision Llama 4
  Maverick + raisonnement DeepSeek). La clé NVIDIA est **uniquement serveur**.
- **Code-push** : **Shorebird** (patch pour le Dart/asset ; release pour le natif).
- **Nav** : `go_router` · **State** : StatefulWidget + services singletons · **Prefs** :
  `shared_preferences` · **Push** : `firebase_messaging` + cibles Appwrite Messaging.
- **Back-office** : SvelteKit (dossier `admin/`) déployé sur Vercel.
- **Version web** : `flutter build web` déployé sur Vercel.

## 3. Structure du repo

```
lib/
  main.dart                 # bootstrap (thème, Firebase, push) + MaterialApp
  appwrite_config.dart      # IDs Appwrite (endpoint, project, db, collections)
  ai_config.dart            # tutorFunctionId, freeDaily, limites image
  theme/app_theme.dart      # palette OC (clair+sombre), buildAppTheme(), body/display/mono
  router/app_router.dart    # routes go_router + ShellRoute (bottom nav)
  screens/main_shell.dart   # coque + bottom nav (onglets)
  models/                   # modèles (fromMap) : article, concours, exam_series, social_link…
  services/                 # database_service, auth_service, tutor_service, push_service,
                            # billing_service, analytics_service, theme_controller, …
  widgets/                  # ob_widgets (primitives), states (EmptyState/ErrorState/Appear),
                            # skeletons, leo_mascot, rich_answer, series_picker, paywall_sheet
  screens/                  # par module : home, tutor, cours, menu(concours…), results,
                            # annales, news, school(campus), profile, onboarding, search
functions/
  tutor-ai/                 # proxy NVIDIA (vision+raisonnement) → écrit tutor_jobs ; push
  verify-purchase/          # vérifie les reçus Google Play → crédite tutor_quota
tools/                      # scripts setup_*.sh (création collections Appwrite, idempotents)
admin/                      # back-office SvelteKit (déployé Vercel)
web/                        # entrée Flutter web (index.html, manifest.json)
android/ ios/               # natif (label, Info.plist, google-services.json, manifeste)
```

## 4. Modules / onglets

Bottom nav : **Tableau · Concours · Tuteur · Annales · Cours** (Campus déplacé en
carte d'accueil + menu).
- **Tuteur (Léo)** : correction photo/texte/PDF, chat de suivi, **fiche de
  révision** (mode `summary`, multi-pages, gratuit), **export PDF** (LaTeX compilé
  via rasterisation), génération en **arrière-plan + push** « c'est prêt »,
  quotas (3 gratuits/jour) + crédits Google Play.
- **Cours** : matières → chapitres → leçons + quiz (anneaux de progression).
- **Concours** : recherche live + filtres statut, fiche, inscription, prépa, blanc.
- **Résultats** : **entièrement configurable par l'admin** via `result_sources`
  (back-office « Résultats — sources »). Chaque source a un mode : `manual`
  (saisie ligne par ligne dans `exam_results`), `pdf` (l'admin charge le PDF, on
  cherche le nom/numéro dedans via la fonction `result-lookup`), ou `api` (proxy
  vers une API externe). Libellés/champ de recherche/message pilotés par l'admin.
  Repli sur une liste par défaut si aucune source n'est créée. Partage carte vérifiée.
- **Annales** : ⚠️ **encore en démo** (pas de backend/lecteur PDF réel).
- **Campus/Agenda** : calendrier scolaire (`school_calendar`) + page Agenda.
- **Accueil** : hero examens, actus, à l'affiche, communauté (liens admin).

## 5. Backend Appwrite

- **Endpoint** : `https://nyc.cloud.appwrite.io/v1`
- **Project ID** : `6a30463b00001375e229`
- **Database ID** : `6a3047f8001d11d1b3c1`
- **Region** : NYC. **Version** : 1.9.x.

**Collections** (toutes dans `lib/appwrite_config.dart`) : `users`,
`exam_series`, `social_links`, `results`, `exam_results`, `result_sources`, `analytics_events`,
`articles`, `exams`, `school_calendar`, `concours`, `prep_centers`,
`concours_resources`, `concours_applications`, `subjects`, `chapters`, `lessons`,
`chapter_progress`, `quizzes`, `affiche`, `tutor_jobs`, `tutor_quota`,
`notifications`.
- Contenu géré par l'admin = lecture `read("any")`, écriture `team:admins`.
- Données utilisateur (tutor_jobs/quota) = `read("user:<uid>")`.

**Teams** : `admins` (accès back-office + écriture contenus). Ajouter un admin =
Console → Auth → Teams → `admins` → Create membership (email).

**Messaging** : un provider **FCM** activé (push). L'app enregistre le token via
`account.createPushTarget` ; ciblage `users:[uid]`.

**Functions** :
- `tutor-ai` (node-22) : reçoit image(s)/texte, transcrit+corrige, écrit
  `tutor_jobs/{jobId}`, envoie un push si `notify`. **Variables** : `NVIDIA_API_KEY`,
  `APPWRITE_API_KEY`, `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT`, `DATABASE_ID`,
  `JOBS_COLLECTION`, `FREE_DAILY`, `VISION_MODEL`, `NVIDIA_MODEL`. Modes :
  défaut (correction), `lesson`, `quiz`, `summary` (tous gratuits sauf correction).
- `verify-purchase` : vérifie les achats Google Play et crédite `tutor_quota`.
- `result-lookup` (node-22) : résout une recherche de résultat pour les sources
  `pdf` (télécharge le PDF chargé par l'admin, extrait le texte via
  `pdf-parse`, cherche nom/numéro) et `api` (proxy vers une API externe). Le type
  `manual` est résolu côté app (lecture directe d'`exam_results`). **Variable** :
  `APPWRITE_API_KEY` (scope `databases.read`).

**Storage** : les PDF de résultats chargés par l'admin sont stockés dans le
bucket **`annales_files`** (réutilisé — le plan Appwrite limite le nombre de
buckets ; lecture publique, écriture `team:admins`, PDF autorisés).

**Web platforms déclarées** (CORS) : `onbuch-v2.vercel.app`,
`onbuch-app.vercel.app` (+ alias d'équipe), `localhost`. Tout nouveau domaine web
doit être ajouté : Console → Project → Platforms → Web, **ou** via l'API
`POST /projects/{id}/platforms` (clé serveur).

## 6. Build & déploiement

### Mobile (Shorebird)
- Build/release sur le **serveur Contabo** : `bash /root/build-onbuch.sh`
  (→ `shorebird release` / `flutter build appbundle`, Flutter 3.44.2).
- **Patch** (Dart/asset only) vs **release** (changements natifs : dépendances,
  manifeste, plist, icônes, plugins). Indiquer dans chaque PR si c'est patchable.

### Web
- **Le Flutter de Shorebird est tronqué** (pas de `dart2js`) → installer un Flutter
  stable complet pour builder le web : `git clone -b stable --depth 1 .../flutter`.
- `flutter build web --release` → `build/web/` ; ajouter `vercel.json`
  (rewrite SPA → `/index.html`) ; déployer (voir §7).

### Workflow Git (IMPÉRATIF)
- Branche de dev : **`claude/auth-database-issues-zoxpxd`**. Ne jamais pousser
  ailleurs sans accord.
- Cycle : commit → push → PR vers `main` → **squash-merge** → réaligner la branche
  (`git fetch origin main && git reset --hard origin/main && git push -f`).
- Identité commits : `git config user.email noreply@anthropic.com` / `user.name Claude`.
- Ne PAS committer : valeurs de secrets, fichiers desktop régénérés
  (`linux/ macos/ windows/` → `git checkout --` avant de commit).

## 7. Apps web (Vercel)

- **Équipe Vercel** : `Ludovic Aggaï's projects` (slug `ludovic-aggais-projects`).
- **Back-office admin** : projet `onbuch-v2` → **https://onbuch-v2.vercel.app**
  (build du sous-dossier `admin/` via `vercel.json` racine).
- **App élève (web)** : projet `onbuch-app` → **https://onbuch-app.vercel.app**
  (déploiement statique de `build/web`).
- Déploiement **manuel** (CLI) :
  `npx vercel deploy --prod --yes --scope ludovic-aggais-projects --token <VERCEL_TOKEN>`
  (depuis `admin/` pour l'admin ; depuis `build/web` pour le web — pas encore
  d'auto-deploy Git).
- **Admin** : piloté par `admin/src/lib/schema.ts` (ajouter une collection = une
  entrée `Resource`, CRUD générique). Connexion = compte Appwrite membre `admins`.

## 8. Conventions de code

- **Couleurs** : classe `OC` (`lib/theme/app_theme.dart`). Les **neutres**
  (`bg/paper/panel/ink/ink2/muted/faint/line/line2`) sont **mutables** (dark mode,
  via `OC.applyBrightness`) ⇒ **ne pas les utiliser dans un contexte `const`**.
  L'orange/accents (`o50…o700`, `good/bad/blue/warn`, gradients) restent `const`.
- **Typo** : `display()`, `body()`, `mono()` (Google Fonts) — pas de `TextStyle` brut.
- **Widgets réutilisables** : `EmptyState`, `ErrorState`, `Appear`, `Skeleton`,
  `OBRing`, `OBCard`, `obBackAppBar`, `LeoMascot`, `RichAnswer`, `SeriesPicker`.
- **Données** : passer par `DatabaseService` (cache mémoire 5 min, tolérant
  hors-ligne → liste vide). Nouveaux modèles : factory `fromMap` (cf. `exam_series.dart`).
- **Thème sombre** : géré par `ThemeController` (Système/Clair/Sombre, persisté).

## 9. Secrets & accès  ⚠️ (valeurs hors-repo)

| Secret | Où | Rôle / scope | Note |
|---|---|---|---|
| **Clé API Appwrite serveur** `standard_…` | env `APPWRITE_API_KEY` des scripts `tools/` **et** variable de la fonction `tutor-ai` | `databases.write`, `messages.write`, gestion `platforms` | **Exposée en chat → À RÉGÉNÉRER.** Si régénérée, mettre à jour la fonction `tutor-ai` + relancer les scripts avec la nouvelle. |
| **Clé NVIDIA** | variable `NVIDIA_API_KEY` de la fonction `tutor-ai` | accès modèles vision/raisonnement | Jamais côté client. |
| **Token Vercel** `vcp_…` | utilisé en CLI pour déployer | déploiement projets Vercel de l'équipe | À révoquer après usage (vercel.com/account/tokens). |
| **Firebase** `google-services.json` | `android/app/` (dans le repo) | config FCM Android | Restreindre la clé Android côté Google Cloud. |
| **Compte admin** | `admin@onbuch.cm` | accès back-office (team `admins`) | Mot de passe à changer ; le conserver hors repo. |

> Pour garder une copie perso des valeurs : un fichier **git-ignored** local
> (ex. `.secrets.local`) ou un gestionnaire de mots de passe — **jamais** committé.

## 10. Tâches courantes

- **Créer/mettre à jour une collection** : script `tools/setup_*.sh` (idempotent),
  lancé avec `APPWRITE_API_KEY=… ./tools/setup_xxx.sh`.
- **Ajouter un contenu gérable par l'admin** : créer la collection (script) +
  ajouter une `Resource` dans `admin/src/lib/schema.ts` + redéployer l'admin.
- **Lire une nouvelle collection dans l'app** : modèle `fromMap` + méthode
  `DatabaseService.getXxx()` (patron `getExamSeries`/`getSocialLinks`).
- **Vérifier** : `flutter analyze` (via le Flutter de Shorebird en local).

## 11. État & chantiers restants

- ✅ Faits récemment : dark mode, fiche de révision Tuteur, PDF LaTeX compilé,
  push « c'est prêt », séries configurables, liens réseaux pilotés par l'admin,
  Concours fonctionnel, page Agenda, back-office + web déployés.
- 🔴 **Annales** : encore 100 % démo (à faire : collection + vrai lecteur PDF →
  release car plugins natifs).
- ⬜ **Gamification** (streak/XP/badges) : absente — fort levier de rétention.
- ⬜ **i18n FR/EN** : absente (sélecteur de langue Paramètres = informatif).
- ⬜ **Auto-deploy** Vercel (git) ; **crashlytics** ; **cache disque** ; teintes
  pastel du dark mode à affiner ; **app icon** Léo.
- 🔐 **Sécurité** : régénérer la clé Appwrite exposée ; restreindre la clé Firebase.
