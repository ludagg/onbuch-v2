import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../ai_config.dart';

/// Service du Tuteur IA : envoie la photo d'un exercice au modèle vision NVIDIA
/// et renvoie une correction pédagogique.
class TutorService {
  /// Analyse l'image d'un exercice et renvoie la correction (texte formaté).
  /// Lève une [String] lisible en cas d'erreur (affichable telle quelle).
  Future<String> analyzeExercise(Uint8List imageBytes, {String? question}) async {
    if (!AIConfig.isConfigured) {
      throw 'Tuteur IA non configuré. Compile l\'app avec '
          '--dart-define=NVIDIA_API_KEY=nvapi-…';
    }

    // Compression hors du thread UI pour éviter les saccades.
    final b64 = await compute(_compressToBase64, imageBytes);

    final userText = (question == null || question.trim().isEmpty)
        ? 'Voici la photo d\'un exercice. Corrige-le en détaillant chaque étape.'
        : question.trim();

    final payload = {
      'model': AIConfig.model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userText},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$b64'},
            },
          ],
        },
      ],
      'temperature': 0.2,
      'top_p': 0.7,
      'max_tokens': 1024,
      'stream': false,
    };

    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(AIConfig.endpoint),
            headers: {
              'Authorization': 'Bearer ${AIConfig.apiKey}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw 'Connexion impossible. Vérifie ta connexion internet et réessaie.';
    }

    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      final content = data['choices']?[0]?['message']?['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      throw 'Le Tuteur n\'a pas pu lire l\'exercice. Réessaie avec une photo plus nette.';
    }

    switch (resp.statusCode) {
      case 401:
      case 403:
        throw 'Clé API NVIDIA invalide ou non autorisée.';
      case 402:
        throw 'Crédits NVIDIA épuisés. Réessaie plus tard.';
      case 413:
        throw 'Image trop volumineuse. Reprends une photo plus petite.';
      case 429:
        throw 'Trop de requêtes. Patiente quelques secondes et réessaie.';
      default:
        throw 'Erreur du Tuteur (${resp.statusCode}). Réessaie.';
    }
  }

  static const _systemPrompt = '''
Tu es le Tuteur IA d'OnBuch, une application éducative pour les élèves camerounais (système francophone : BEPC, Probatoire, Baccalauréat).
À partir de la photo d'un exercice, tu dois :
1. Restituer brièvement l'énoncé tel que tu le lis.
2. Donner une correction pédagogique claire, étape par étape, numérotée.
3. Expliquer le raisonnement simplement et en français.
4. Terminer par la réponse finale mise en évidence, préfixée par "Réponse :".
Reste rigoureux, bienveillant et concis. Si l'image est illisible ou n'est pas un exercice scolaire, dis-le poliment et demande une meilleure photo.
''';
}

/// Décode, redimensionne et recompresse l'image en JPEG jusqu'à passer sous la
/// limite NVIDIA, puis renvoie le base64. Exécuté dans un isolate via `compute`.
String _compressToBase64(Uint8List bytes) {
  img.Image? im = img.decodeImage(bytes);
  if (im == null) {
    // Format non décodable : on tente l'envoi brut (peut dépasser la limite).
    return base64Encode(bytes);
  }

  // Limite la plus grande dimension à 1280 px.
  const maxDim = 1280;
  if (im.width >= im.height && im.width > maxDim) {
    im = img.copyResize(im, width: maxDim);
  } else if (im.height > maxDim) {
    im = img.copyResize(im, height: maxDim);
  }

  // Qualité décroissante jusqu'à passer sous la limite.
  for (final q in [80, 65, 50, 40, 30, 22]) {
    final jpg = img.encodeJpg(im, quality: q);
    if (jpg.length <= AIConfig.maxInlineImageBytes) {
      return base64Encode(jpg);
    }
  }

  // Dernier recours : réduire encore la résolution.
  final small = img.copyResize(im, width: 800);
  return base64Encode(img.encodeJpg(small, quality: 35));
}
