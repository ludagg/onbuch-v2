# Bibliothèque d'annales — branchement

La section **Annales** consomme directement l'API REST de l'application NextJS
`ol` (table `Document` sur Neon, ~37k épreuves), catégorisée par
matière / classe / série / examen / type / année.

## Configurer l'URL de l'API

L'URL de base est définie dans [`lib/api_config.dart`](lib/api_config.dart) et
surchargeable au build :

```bash
flutter run --dart-define=ONBUCH_API_BASE_URL=https://VOTRE-DEPLOIEMENT-OL
flutter build apk --dart-define=ONBUCH_API_BASE_URL=https://VOTRE-DEPLOIEMENT-OL
```

À défaut, la valeur par défaut de `api_config.dart` est utilisée — **remplacez-la
par l'URL de production de `ol`** (ou passez toujours `--dart-define`).

> Prérequis côté `ol` : avoir lancé le backfill de catégorisation
> (voir `CATEGORIZATION_GUIDE.md` dans le dépôt `ol`). Sans lui, les filtres
> par matière/classe renverront des listes vides.

## Architecture

```
Flutter (onbuch-v2)
  api_config.dart            URL de base (dart-define)
  models/                    Annale, AnnalesFilter, FacetSet
  services/annales_service.dart   GET /api/documents  ·  GET /api/facets
  screens/annales/
    annales_library_screen   dossiers par classe + examens + recherche  (facettes)
    annales_folder_screen    AnnalesBrowseScreen : matières + filtres série/année
    annales_list_screen      liste paginée (scroll infini)
    annale_detail_screen     métadonnées + ouvrir/télécharger le PDF
    pdf_reader_screen        lecteur PDF plein écran (SfPdfViewer.network)
```

Flux : **Bibliothèque** → (classe ou examen) → **Parcourir** → (matière) →
**Liste** → **Détail** → **Lecteur PDF**.

## Dépendances ajoutées

- `http` — appels REST
- `syncfusion_flutter_pdfviewer` — rendu des PDF distants
- `url_launcher` — téléchargement / ouverture externe

Après `git pull` : `flutter pub get`.
