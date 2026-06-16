import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image/image.dart' as img;
import '../ai_config.dart';
import '../appwrite_config.dart';
import 'appwrite_client.dart';

/// Une correction du Tuteur (entrée de l'historique « Corrections récentes »).
class TutorJob {
  final String id;
  final String title;
  final String subject;
  const TutorJob({required this.id, required this.title, required this.subject});

  factory TutorJob.fromDoc(String id, Map<String, dynamic> data) => TutorJob(
        id: id,
        title: (data['title'] ?? 'Exercice').toString(),
        subject: (data['subject'] ?? '').toString(),
      );
}

/// Quota du Tuteur : corrections gratuites restantes aujourd'hui + crédits.
class TutorQuota {
  final int freeRemaining;
  final int credits;
  const TutorQuota({required this.freeRemaining, required this.credits});

  bool get canAsk => freeRemaining > 0 || credits > 0;
  int get freeDaily => AIConfig.freeDaily;
}

/// Service du Tuteur IA.
///
/// La photo (ou le texte) d'un exercice est envoyé à la fonction Appwrite
/// `tutor-ai` (en **asynchrone**). La fonction transcrit l'énoncé si besoin
/// (vision) puis le corrige (raisonnement) et écrit le résultat dans
/// `tutor_jobs/{jobId}`. L'app interroge ce document jusqu'à complétion. La clé
/// NVIDIA n'est jamais sur le téléphone.
class TutorService {
  /// Lance une correction depuis une [image] et/ou un [text], et renvoie la
  /// correction (Markdown + LaTeX + éventuels blocs `onbuch-plot`).
  /// Lève une [String] lisible en cas d'erreur.
  Future<String> analyzeExercise({
    Uint8List? image,
    String? text,
    String? subject,
  }) async {
    if (image == null && (text == null || text.trim().isEmpty)) {
      throw 'Fournis une photo ou écris ton exercice.';
    }

    final b64 = image != null ? await compute(_compressToBase64, image) : null;
    final jobId = ID.unique();

    final payload = <String, dynamic>{
      'jobId': jobId,
      if (b64 != null) 'image': b64,
      if (text != null && text.trim().isNotEmpty) 'question': text.trim(),
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
    };

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
      } on AppwriteException catch (_) {
        continue; // 404 (pas encore écrit) ou erreur transitoire → on retente.
      }
    }
  }

  /// Renvoie la correction déjà calculée d'un job (réouverture).
  Future<String> getJobCorrection(String jobId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorJobsCollectionId,
        documentId: jobId,
      );
      final c = doc.data['correction']?.toString() ?? '';
      if (c.trim().isEmpty) throw 'Correction introuvable.';
      return c.trim();
    } on AppwriteException catch (_) {
      throw 'Correction introuvable.';
    }
  }

  /// Renvoie le quota courant de l'utilisateur (gratuites restantes + crédits).
  /// En cas d'erreur (hors-ligne, non connecté), suppose le quota plein pour ne
  /// pas bloquer l'UI — l'enforcement réel reste côté serveur.
  Future<TutorQuota> getQuota() async {
    try {
      final user = await AppwriteClient.account.get();
      try {
        final doc = await AppwriteClient.databases.getDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTutorQuotaCollectionId,
          documentId: user.$id,
        );
        final used = (doc.data['freeUsedToday'] as num?)?.toInt() ?? 0;
        final resetDate = doc.data['freeResetDate']?.toString() ?? '';
        final credits = (doc.data['credits'] as num?)?.toInt() ?? 0;
        final remaining = resetDate == _todayStr()
            ? (AIConfig.freeDaily - used).clamp(0, AIConfig.freeDaily)
            : AIConfig.freeDaily;
        return TutorQuota(freeRemaining: remaining, credits: credits);
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          return const TutorQuota(freeRemaining: AIConfig.freeDaily, credits: 0);
        }
        rethrow;
      }
    } catch (_) {
      return const TutorQuota(freeRemaining: AIConfig.freeDaily, credits: 0);
    }
  }

  String _todayStr() {
    final n = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  /// Nombre total de corrections de l'utilisateur (pour le profil).
  Future<int> correctionsCount() async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorJobsCollectionId,
        queries: [Query.limit(1)],
      );
      return res.total;
    } on AppwriteException {
      return 0;
    }
  }

  /// Liste les corrections récentes de l'utilisateur (les plus récentes d'abord).
  Future<List<TutorJob>> recentJobs({int limit = 8}) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorJobsCollectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(limit),
        ],
      );
      return res.documents
          .where((d) => d.data['status'] == 'done')
          .map((d) => TutorJob.fromDoc(d.$id, d.data))
          .toList();
    } on AppwriteException {
      return const [];
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
