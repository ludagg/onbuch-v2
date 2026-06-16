import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image/image.dart' as img;
import '../ai_config.dart';
import 'appwrite_client.dart';

/// Service du Tuteur IA. La photo d'un exercice est compressée puis envoyée à
/// la fonction Appwrite `tutor-ai`, qui appelle le modèle vision NVIDIA côté
/// serveur (la clé NVIDIA n'est jamais sur le téléphone).
class TutorService {
  /// Analyse l'image d'un exercice et renvoie la correction (texte formaté).
  /// Lève une [String] lisible en cas d'erreur (affichable telle quelle).
  Future<String> analyzeExercise(Uint8List imageBytes, {String? question}) async {
    // Compression hors du thread UI (et sous la limite NVIDIA) avant l'envoi.
    final b64 = await compute(_compressToBase64, imageBytes);

    final payload = <String, dynamic>{
      'image': b64,
      if (question != null && question.trim().isNotEmpty) 'question': question.trim(),
    };

    final exec = await () async {
      try {
        return await AppwriteClient.functions.createExecution(
          functionId: AIConfig.tutorFunctionId,
          body: jsonEncode(payload),
        );
      } on AppwriteException catch (e) {
        if (e.code == 401) {
          throw 'Connecte-toi pour utiliser le Tuteur IA.';
        }
        throw 'Connexion au Tuteur impossible. Vérifie ta connexion et réessaie.';
      }
    }();

    final raw = exec.responseBody;
    if (raw.isEmpty) {
      throw 'Le Tuteur n\'a pas répondu. Réessaie dans un instant.';
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw 'Réponse inattendue du Tuteur. Réessaie.';
    }

    final correction = data['correction'];
    if (correction is String && correction.trim().isNotEmpty) {
      return correction.trim();
    }
    final err = data['error'];
    throw (err is String && err.isNotEmpty) ? err : 'Le Tuteur a rencontré un problème.';
  }
}

/// Décode, redimensionne et recompresse l'image en JPEG jusqu'à passer sous la
/// limite NVIDIA, puis renvoie le base64. Exécuté dans un isolate via `compute`.
String _compressToBase64(Uint8List bytes) {
  img.Image? im = img.decodeImage(bytes);
  if (im == null) {
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
