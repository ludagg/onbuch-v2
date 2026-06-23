# ROADMAP — OnBuch v2 → qualité « flagship »

> Feuille de route pour amener OnBuch à une qualité professionnelle (« top 1
> Afrique »). Chaque chantier indique s'il est **patch** (Shorebird, Dart/asset)
> ou **release** (plugin natif), cf. `CLAUDE.md §6`. À exécuter en sessions/PR
> dédiées après accord.

## État réel (audit du 2026-06-23)

Le codebase est **plus mature** que ne le laissait croire l'ancien `CLAUDE.md` :

| Module / brique | État |
|---|---|
| Annales (PDF Syncfusion + vidéo YouTube/MP4/HLS, favoris, offline) | ✅ réel, pas démo |
| Gamification (XP/streak/badges/niveaux) câblée (accueil, quiz, tuteur, écran Progrès) | ✅ fait |
| Tuteur IA (vision+raisonnement async), Cours, Concours, Résultats, Actus, Agenda | ✅ fonctionnels |
| Cache offline 3 niveaux (mémoire 5 min → disque → réseau) | ✅ en place |
| Fonctions serveur (`tutor-ai`, `verify-purchase`, `review-nudge`) | ✅ en place |

**Baseline qualité (Flutter 3.44.2)**
- `flutter analyze` : **40 issues** — 0 erreur, 3 warning, 37 info
  (dépréciations Appwrite `TablesDB`, imports `dart:typed_data` inutiles,
  `Share`/`share` → `SharePlus`, `avoid_print` dans `tools/`).
- `flutter test` : **1 test** (smoke) — vert. Couverture réelle ≈ 0.

**Vrais déficits « pro » :** observabilité (crash reporting absent), tests/CI,
cache images disque, accessibilité (0 `Semantics`), quelques TODO non câblés,
i18n FR/EN, durcissement sécurité.

---

## Phase 1 — Stabilité & qualité *(priorité haute)*

1. **Crash reporting / observabilité** — *release (natif)*
   - Intégrer **`firebase_crashlytics`** (réutilise Firebase déjà présent,
     `pubspec.yaml` l.47-48 ; évite d'ajouter Sentry).
   - Câbler dans `lib/main.dart` : `FlutterError.onError`,
     `PlatformDispatcher.instance.onError`, `runZonedGuarded`.
   - Helper `reportError()` pour remplacer les `catch (_) {}` muets des chemins
     critiques (`auth_service`, `billing_service`, `tutor_service`,
     `database_service`) — **log + report** sans casser l'UX offline (214+
     try-catch silencieux aujourd'hui).

2. **CI gates** — *infra*
   - Workflow `.github/workflows/ci.yml` sur PR/push → `flutter analyze`
     (--fatal-warnings une fois la dette résorbée) + `flutter test`, SDK Flutter
     complet (pas Shorebird). `shorebird.yml` reste pour les builds.

3. **Cache images disque** — *release (`flutter_cache_manager` ⇒ sqflite natif)*
   - Ajouter `cached_network_image` ; remplacer les **8** `Image.network`
     (news, article_detail, home, affiche) par `CachedNetworkImage` +
     cacheManager 7 j. Gain bande passante 2G/3G Cameroun.

4. **Tests** — *patch*
   - Unitaires sur logique pure : `GamificationState` (niveaux/XP, formule
     50·L·(L+1)), `exam_structure_service` (fallback 3 niveaux), `disk_cache`,
     quota tuteur, `fromMap` des modèles.
   - Widget tests des écrans à fort trafic (accueil, tuteur, résultats).

5. **Hygiène analyze** — *patch*
   - Résorber les 40 issues : migrer Appwrite `*Document` → `TablesDB.*Row`
     (`tutor_service`, `gamification_service`), `Share` → `SharePlus`
     (`annale_actions.dart`), imports inutiles, `avoid_print` (`tools/`).

## Phase 2 — Fonctionnalités & bugs *(priorité haute)*

- **TODO non câblés** — *patch* :
  `cours_catalogue_screen.dart:58-59` (recherche + filtre non branchés) ;
  `home_screen.dart:236` (header). Câbler ou retirer.
- **Placeholders** : statuer sur l'écran OTP (non utilisé) et le bouton Google
  « bientôt » (`auth_phone_screen.dart`) — finir ou masquer proprement.
- **Audit bugs récurrent** : trier la sortie `analyze` à chaque PR (via la CI
  Phase 1) ; tests de non-régression sur les bugs corrigés.

## Phase 3 — Accessibilité & polish *(priorité moyenne-haute)*

- **Accessibilité** — *patch* : passe `Semantics` sur les éléments interactifs
  (`lib/widgets/ob_widgets.dart` : nav, cartes, icon-buttons), labels d'images
  (mascotte Léo), cibles tactiles ≥ 48dp, contraste. Tester TalkBack / VoiceOver.
  0 `Semantics` aujourd'hui.
- **Icône app Léo** — *release* : `flutter_launcher_icons` (dev dep) → générer
  android/ios depuis le visuel Léo (remplace l'icône générique).
- **Polish** : finitions UI, teintes pastel du dark mode (`theme/app_theme.dart`).

## Phase 4 — Sécurité *(ops, en parallèle — priorité basse côté code)*

- Régénérer la **clé Appwrite serveur** exposée → MAJ variables de `tutor-ai` +
  scripts `tools/setup_*.sh`.
- Restreindre la **clé Firebase Android** (filtre SHA-1) côté Google Cloud.
- (Tâches majoritairement hors repo.)

## Phase 5 — Expansion anglophone / i18n FR-EN *(gros effort, plus tard)*

- `l10n.yaml` + `lib/l10n/app_fr.arb` / `app_en.arb` (`generate: true`),
  extraction des ~300 chaînes vers `AppLocalizations`, sélecteur de langue câblé
  (aujourd'hui informatif dans `profile_screen.dart`), persistance de la locale.
  Ouvre le marché GCE anglophone.

---

## Outillage de vérification

Le Flutter de Shorebird est tronqué (pas de `dart2js`). Pour `analyze`/`test`/web,
SDK complet aligné sur le projet :

```bash
git clone https://github.com/flutter/flutter.git -b 3.44.2 --depth 1 /opt/flutter
export PATH="$PATH:/opt/flutter/bin"
flutter pub get && flutter analyze && flutter test
```
Container éphémère → ré-exécuter à chaque session.

## Séquencement conseillé

Phase 1 (observabilité + CI d'abord : on voit enfin les bugs en prod et on
verrouille la qualité) → Phase 2 (bugs/TODO) → Phase 3 (a11y/polish) →
Phase 4 (sécurité, en continu) → Phase 5 (i18n, quand l'anglophone est priorisé).
