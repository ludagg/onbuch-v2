/// Configuration de l'API OnBuch Library (le dépôt NextJS « ol »).
///
/// La bibliothèque d'annales du mobile consomme directement l'API REST de
/// l'application NextJS (table `Document` sur Neon Postgres, ~37k épreuves).
///
/// L'URL de base est surchargeable au build sans toucher au code :
///   flutter run --dart-define=ONBUCH_API_BASE_URL=https://mon-deploiement.vercel.app
///
/// À défaut, la valeur par défaut ci-dessous est utilisée — REMPLACEZ-LA par
/// l'URL de production de `ol`.
const String onbuchApiBaseUrl = String.fromEnvironment(
  'ONBUCH_API_BASE_URL',
  defaultValue: 'https://onbuchlib.vercel.app',
);
