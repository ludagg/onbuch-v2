import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image/image.dart' as img;
import '../ai_config.dart';
import '../appwrite_config.dart';
import 'appwrite_client.dart';
import 'disk_cache.dart';

/// Retire le raisonnement `<think>…</think>` éventuel (filet de sécurité côté
/// app : le serveur ne devrait plus jamais l'émettre, mais une ancienne version
/// déployée pourrait encore le faire). Gère aussi un `<think>` non fermé.
String _stripThink(String s) {
  if (s.isEmpty) return s;
  var out = s.replaceAll(RegExp(r'<think>[\s\S]*?</think>', multiLine: true), '');
  final i = out.indexOf('<think>');
  if (i >= 0) out = out.substring(0, i);
  return out.trim();
}

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
    var tries = 0;
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw 'Le Tuteur met trop de temps à répondre. Réessaie.';
      }
      // Sondage adaptatif : rapide au début (réponses courtes affichées sans
      // délai), puis on espace pour ménager le réseau sur les réponses longues.
      final waitMs = tries < 10 ? 600 : 1600;
      tries++;
      await Future.delayed(Duration(milliseconds: waitMs));
      try {
        final doc = await AppwriteClient.databases.getDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTutorJobsCollectionId,
          documentId: jobId,
        );
        final status = doc.data['status']?.toString();
        if (status == 'done') {
          final c = _stripThink(doc.data['correction']?.toString() ?? '');
          if (c.isNotEmpty) return c;
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

  // ── Variantes STREAMING ─────────────────────────────────────────────────────
  // Émettent le texte PARTIEL (qui grandit) au fil de l'eau, puis le texte final.
  // La fonction `tutor-ai` écrit `tutor_jobs.correction` incrémentalement
  // (status 'streaming') puis 'done' ; on relit le doc et on émet ce qui a grandi.

  Stream<String> analyzeExerciseStream({
    Uint8List? image,
    String? text,
    String? subject,
    String? mode,
    String? chapterId,
    bool notify = false,
  }) async* {
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
    yield* _runStream(payload, jobId);
  }

  Stream<String> analyzeExamStream({
    String examUrl = '',
    Uint8List? image,
    required String question,
    String? subject,
  }) async* {
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
    yield* _runStream(payload, jobId);
  }

  Stream<String> continueConversationStream(List<Map<String, String>> messages) async* {
    final jobId = ID.unique();
    yield* _runStream({'jobId': jobId, 'messages': messages}, jobId);
  }

  /// Lance l'exécution async puis suit le job EN TEMPS RÉEL (Appwrite Realtime) :
  /// dès que la fonction écrit `correction` dans `tutor_jobs`, l'app reçoit la
  /// mise à jour poussée (pas de sondage permanent → fluide même sur connexion
  /// lente). Un sondage espacé sert de filet de sécurité (le Realtime peut rater
  /// la toute première écriture ou être bloqué par certains réseaux).
  Stream<String> _runStream(Map<String, dynamic> payload, String jobId) async* {
    try {
      await AppwriteClient.functions.createExecution(
        functionId: AIConfig.tutorFunctionId,
        body: jsonEncode(payload),
        xasync: true,
      );
    } on AppwriteException catch (e) {
      if (e.code == 401) throw 'Connecte-toi pour utiliser le Tuteur IA.';
      throw 'Connexion au Tuteur impossible. Vérifie ta connexion et réessaie.';
    }

    final channel =
        'databases.$appwriteDatabaseId.collections.$appwriteTutorJobsCollectionId.documents.$jobId';
    final out = StreamController<String>();
    final deadline = DateTime.now().add(const Duration(seconds: 110));
    var last = '';
    Object? failure;
    RealtimeSubscription? sub;
    StreamSubscription<RealtimeMessage>? rtSub;
    Timer? poll;

    void finish([Object? err]) {
      if (out.isClosed) return;
      failure = err;
      rtSub?.cancel();
      poll?.cancel();
      try {
        sub?.close();
      } catch (_) {}
      out.close();
    }

    void apply(Map<String, dynamic> data) {
      if (out.isClosed) return;
      final status = data['status']?.toString();
      final c = _stripThink((data['correction'] ?? '').toString());
      if (c.isNotEmpty && c != last) {
        last = c;
        out.add(c); // texte partiel (ou final) qui grandit
      }
      if (status == 'done') {
        finish(last.isEmpty ? 'Le Tuteur n\'a pas pu répondre. Réessaie.' : null);
      } else if (status == 'error') {
        final err = data['error']?.toString();
        finish((err != null && err.isNotEmpty)
            ? err
            : 'Le Tuteur a rencontré un problème.');
      }
    }

    // 1) Temps réel : mises à jour poussées par Appwrite.
    try {
      sub = AppwriteClient.realtime.subscribe([channel]);
      rtSub = sub.stream.listen(
        (msg) => apply(Map<String, dynamic>.from(msg.payload)),
        onError: (_) {/* on garde le sondage de secours */},
      );
    } catch (_) {
      sub = null; // Realtime indisponible → on s'appuie sur le sondage.
    }

    // 2) Filet de sécurité : sondage espacé (coût réseau minimal).
    Future<void> pollOnce() async {
      if (out.isClosed) return;
      if (DateTime.now().isAfter(deadline)) {
        finish('Le Tuteur met trop de temps à répondre. Réessaie.');
        return;
      }
      try {
        final doc = await AppwriteClient.databases.getDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTutorJobsCollectionId,
          documentId: jobId,
        );
        apply(Map<String, dynamic>.from(doc.data));
      } on AppwriteException catch (_) {
        // 404 (pas encore créé) ou erreur transitoire → on retentera.
      }
    }

    // Premier coup d'œil rapide (au cas où l'écriture précède l'abonnement),
    // puis un rythme lent — le Realtime fait l'essentiel du travail.
    Future.delayed(const Duration(milliseconds: 700), pollOnce);
    poll = Timer.periodic(const Duration(seconds: 3), (_) => pollOnce());

    try {
      yield* out.stream;
    } finally {
      rtSub?.cancel();
      poll?.cancel();
      try {
        sub?.close();
      } catch (_) {}
    }
    if (failure != null) throw failure!;
  }

  /// Renvoie la correction déjà calculée d'un job (réouverture).
  Future<String> getJobCorrection(String jobId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTutorJobsCollectionId,
        documentId: jobId,
      );
      final c = _stripThink(doc.data['correction']?.toString() ?? '');
      if (c.isEmpty) throw 'Correction introuvable.';
      return c;
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
        // Cache disque : les crédits restent visibles hors-ligne.
        unawaited(DiskCache.writeMap('tutor_quota_last', {'credits': credits, 'remaining': remaining}));
        return TutorQuota(freeRemaining: remaining, credits: credits);
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          return const TutorQuota(freeRemaining: AIConfig.freeDaily, credits: 0);
        }
        rethrow;
      }
    } catch (_) {
      // Hors-ligne / erreur : dernière valeur connue (crédits notamment).
      final disk = await DiskCache.readMap('tutor_quota_last');
      if (disk != null) {
        return TutorQuota(
          freeRemaining: (disk['remaining'] as num?)?.toInt() ?? AIConfig.freeDaily,
          credits: (disk['credits'] as num?)?.toInt() ?? 0,
        );
      }
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
          .map((m) {
            final out = <String, String>{
              'role': (m['role'] ?? '').toString(),
              'content': (m['content'] ?? '').toString(),
            };
            final img = (m['image'] ?? '').toString();
            if (img.isNotEmpty) out['image'] = img; // image persistée (base64)
            return out;
          })
          // On garde un message s'il a du texte OU une image.
          .where((m) => m['content']!.isNotEmpty || (m['image']?.isNotEmpty ?? false))
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
