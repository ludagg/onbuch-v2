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

/// Un fil de conversation persisté avec le Tuteur (mémoire des échanges).
class TutorThread {
  final String id;
  final String title;
  final String subject;
  final DateTime updatedAt;
  const TutorThread({required this.id, required this.title, required this.subject, required this.updatedAt});

  factory TutorThread.fromDoc(String id, Map<String, dynamic> d) => TutorThread(
        id: id,
        title: (d['title'] ?? 'Discussion').toString(),
        subject: (d['subject'] ?? '').toString(),
        updatedAt: DateTime.tryParse((d['updatedAt'] ?? d['\$updatedAt'] ?? '').toString()) ?? DateTime.now(),
      );
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
    String? mode,
    String? chapterId,
    bool notify = false,
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
      if (mode != null && mode.isNotEmpty) 'mode': mode,
      if (chapterId != null && chapterId.isNotEmpty) 'chapterId': chapterId,
      if (notify) 'notify': true,
    };

    return _run(payload, jobId);
  }

  /// Aide sur une **épreuve** (mode `exam_help`) : la fonction télécharge le PDF
  /// ([examUrl]) côté serveur (pas de CORS) et en extrait le texte ; repli sur la
  /// vision si une [image] (1ʳᵉ page rendue sur mobile) est jointe. [question] =
  /// l'exercice précisé par l'élève. Renvoie la correction (Markdown + LaTeX).
  Future<String> analyzeExam({
    String examUrl = '',
    Uint8List? image,
    required String question,
    String? subject,
  }) async {
    final b64 = image != null ? await compute(_compressToBase64, image) : null;
    final jobId = ID.unique();
    final payload = <String, dynamic>{
      'jobId': jobId,
      'mode': 'exam_help',
      if (examUrl.trim().isNotEmpty) 'examUrl': examUrl.trim(),
      if (b64 != null) 'image': b64,
      if (question.trim().isNotEmpty) 'question': question.trim(),
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
    };
    return _run(payload, jobId);
  }

  /// Résume un cours (plusieurs pages photo et/ou texte) en **fiche de
  /// révision**. Mode `summary` (gratuit, hors quota). Renvoie la fiche en
  /// Markdown. Lève une [String] lisible en cas d'erreur.
  Future<String> summarizeCourse({
    List<Uint8List> images = const [],
    String? text,
    String? subject,
    bool notify = true,
  }) async {
    if (images.isEmpty && (text == null || text.trim().isEmpty)) {
      throw 'Ajoute au moins une page de cours (photo ou PDF).';
    }
    final b64s = <String>[];
    for (final im in images.take(8)) {
      b64s.add(await compute(_compressToBase64, im));
    }
    final jobId = ID.unique();
    final payload = <String, dynamic>{
      'jobId': jobId,
      if (b64s.isNotEmpty) 'images': b64s,
      if (text != null && text.trim().isNotEmpty) 'question': text.trim(),
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
      'mode': 'summary',
      if (notify) 'notify': true,
    };
    return _run(payload, jobId);
  }

  /// Question de suivi dans une conversation. [messages] = historique
  /// [{role:'user'|'assistant', content}]. Renvoie la réponse de l'assistant.
  Future<String> continueConversation(List<Map<String, String>> messages) async {
    final jobId = ID.unique();
    return _run({'jobId': jobId, 'messages': messages}, jobId);
  }

  /// Lance l'exécution async et interroge le document jusqu'à complétion.
  Future<String> _run(Map<String, dynamic> payload, String jobId) async {
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
          throw 'Le Tuteur n\'a pas pu répondre. Réessaie.';
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

  // ── Mémoire conversationnelle (tutor_threads) ───────────────────────────────

  /// Crée ou met à jour un fil de conversation (mémoire). Renvoie l'id du fil
  /// (ou l'id reçu en cas d'échec). Non bloquant.
  Future<String?> saveThread({
    String? threadId,
    required List<Map<String, String>> messages,
    String? title,
    String? subject,
  }) async {
    if (messages.isEmpty) return threadId;
    try {
      final user = await AppwriteClient.account.get();
      final uid = user.$id;
      final t = (title ?? '').trim();
      final data = {
        'userId': uid,
        'title': t.isEmpty ? 'Discussion' : (t.length > 200 ? t.substring(0, 200) : t),
        'subject': subject ?? '',
        'messages': jsonEncode(messages),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (threadId == null) {
        final doc = await AppwriteClient.databases.createDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTutorThreadsCollectionId,
          documentId: ID.unique(),
          data: data,
          permissions: [
            Permission.read(Role.user(uid)),
            Permission.update(Role.user(uid)),
            Permission.delete(Role.user(uid)),
          ],
        );
        return doc.$id;
      }
      await AppwriteClient.databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorThreadsCollectionId,
        documentId: threadId,
        data: data,
      );
      return threadId;
    } on AppwriteException {
      return threadId;
    }
  }

  /// Fils récents (mémoire) — les plus récents d'abord.
  Future<List<TutorThread>> recentThreads({int limit = 20}) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorThreadsCollectionId,
        queries: [Query.orderDesc('\$updatedAt'), Query.limit(limit)],
      );
      return res.documents.map((d) => TutorThread.fromDoc(d.$id, d.data)).toList();
    } on AppwriteException {
      return const [];
    }
  }

  /// Charge les messages d'un fil pour le reprendre.
  Future<List<Map<String, String>>> getThreadMessages(String threadId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorThreadsCollectionId,
        documentId: threadId,
      );
      final raw = (doc.data['messages'] ?? '[]').toString();
      final list = (jsonDecode(raw) as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((m) => {'role': (m['role'] ?? '').toString(), 'content': (m['content'] ?? '').toString()})
          .where((m) => m['content']!.isNotEmpty)
          .toList();
    } catch (_) {
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
