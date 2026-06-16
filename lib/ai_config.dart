/// Configuration du Tuteur IA.
///
/// Les appels au modèle vision NVIDIA passent par une **fonction Appwrite**
/// (`tutor-ai`) qui détient la clé côté serveur. L'app n'a donc plus aucune
/// clé NVIDIA : elle envoie seulement l'image et reçoit la correction.
class AIConfig {
  /// ID de la fonction Appwrite qui relaie les requêtes vers NVIDIA.
  static const tutorFunctionId = 'tutor-ai';

  /// Limite NVIDIA pour une image base64 inline (~180 Ko). On vise un peu en
  /// dessous pour garder une marge avec le reste du payload.
  static const maxInlineImageBytes = 170 * 1024;
}
