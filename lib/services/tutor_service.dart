import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image/image.dart' as img;
import '../ai_config.dart';
import '../appwrite_config.dart';
import 'appwrite_client.dart';

/// Service du Tuteur IA.
///
/// La photo d'un exercice est compressée puis envoyée à la fonction Appwrite
/// `tutor-ai` (en **asynchrone** : la correction prend 15-30 s, au-delà de la
/// limite des exécutions synchrones). La fonction transcrit l'énoncé (vision)
/// puis le corrige (raisonnement) et écrit le résultat dans `tutor_jobs/{jobId}`.
/// L'app interroge ce document jusqu'à complétion. La clé NVIDIA n'est jamais
/// sur le téléphone.
class TutorService {
  /// Analyse l'image d'un exercice et renvoie la correction (Markdown + LaTeX
  /// + éventuels blocs `onbuch-plot`). Lève une [String] lisible en cas d'erreur.
  Future<String> analyzeExercise(Uint8List imageBytes, {String? question}) async {
    final b64 = await compute(_compressToBase64, imageBytes);
    final jobId = ID.unique();

    final payload = <String, dynamic>{
      'image': b64,
      'jobId': jobId,
      if (question != null && question.trim().isNotEmpty) 'question': question.trim(),
    };

    // 1) Lancer l'exécution en asynchrone (le résultat sera écrit dans la base).
    try {
      await AppwriteClient.functions.createExecution(
        functionId: AIConfig.tutorFunctionId,
        body: jsonEncode(payload),
        xasync: true,
      );
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw 'Connecte-toi pour utiliser le Tuteur IA.';
      }
      throw 'Connexion au Tuteur impossible. Vérifie ta connexion et réessaie.';
    }

    // 2) Interroger le document `tutor_jobs/{jobId}` jusqu'à complétion.
    final deadline = DateTime.now().add(const Duration(seconds: 110));
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw 'Le Tuteur met trop de temps à répondre. Réessaie.';
      }
      await Future.delayed(const Duration(milliseconds: 1800));

      try {
        final doc = await AppwriteClient.databases.getDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTutorJobsCollectionId,
          documentId: jobId,
        );
        final status = doc.data['status']?.toString();
        if (status == 'done') {
          final c = doc.data['correction']?.toString() ?? '';
          if (c.trim().isNotEmpty) return c.trim();
          throw 'Le Tuteur n\'a pas pu rédiger la correction. Réessaie.';
        }
        if (status == 'error') {
          final err = doc.data['error']?.toString();
          throw (err != null && err.isNotEmpty) ? err : 'Le Tuteur a rencontré un problème.';
        }
        // status pending/null → on continue d'interroger.
      } on AppwriteException catch (_) {
        // 404 (job pas encore écrit) ou erreur transitoire → on retente.
        continue;
      }
    }
  }
}

/// Décode, redimensionne et recompresse l'image en JPEG jusqu'à passer sous la
/// limite NVIDIA, puis renvoie le base64. Exécuté dans un isolate via `compute`.
String _compressToBase64(Uint8List bytes) {
  img.Image? im = img.decodeImage(bytes);
  if (im == null) {
    return base64Encode(bytes);
  }

  const maxDim = 1280;
  if (im.width >= im.height && im.width > maxDim) {
    im = img.copyResize(im, width: maxDim);
  } else if (im.height > maxDim) {
    im = img.copyResize(im, height: maxDim);
  }

  for (final q in [80, 65, 50, 40, 30, 22]) {
    final jpg = img.encodeJpg(im, quality: q);
    if (jpg.length <= AIConfig.maxInlineImageBytes) {
      return base64Encode(jpg);
    }
  }

  final small = img.copyResize(im, width: 800);
  return base64Encode(img.encodeJpg(small, quality: 35));
}
