/// Configuration des appels au Tuteur IA (API NVIDIA, compatible OpenAI).
///
/// La clé et le modèle sont injectés au build via --dart-define :
///   flutter build apk --dart-define=NVIDIA_API_KEY=nvapi-xxxx
///   (optionnel) --dart-define=NVIDIA_MODEL=qwen/qwen2.5-vl-72b-instruct
///
/// La clé n'est JAMAIS écrite en dur dans le code source.
class AIConfig {
  /// Endpoint chat completions (compatible OpenAI).
  static const endpoint = 'https://integrate.api.nvidia.com/v1/chat/completions';

  /// Modèle vision par défaut (surchargeable au build).
  static const model = String.fromEnvironment(
    'NVIDIA_MODEL',
    defaultValue: 'qwen/qwen2.5-vl-72b-instruct',
  );

  /// Clé API NVIDIA (commence par `nvapi-`).
  static const apiKey = String.fromEnvironment('NVIDIA_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;

  /// Limite NVIDIA pour une image base64 inline (~180 Ko). On vise un peu en
  /// dessous pour garder une marge avec le reste du payload.
  static const maxInlineImageBytes = 170 * 1024;
}
