// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';
import '../models/article.dart';
import '../models/exam.dart';
import '../models/calendar_event.dart';
import '../models/concours.dart';
import '../models/concours_application.dart';
import '../models/prep_center.dart';
import '../models/concours_resource.dart';
import '../models/course.dart';
import '../models/quiz.dart';
import '../models/affiche.dart';
import '../models/app_notification.dart';
import '../models/exam_result.dart';
import '../models/exam_series.dart';
import '../models/social_link.dart';
import 'appwrite_client.dart';

class DatabaseService {
  // ── Cache mémoire (contenu global, partagé pour la session) ───────────────
  static final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 5);

  /// Renvoie le contenu depuis le cache (si frais) ou via [fetch]. Ne met pas
  /// en cache un résultat vide (souvent un échec réseau).
  Future<List<T>> _cachedList<T>(String key, Future<List<T>> Function() fetch,
      {bool force = false}) async {
    final e = _cache[key];
    if (!force && e != null && DateTime.now().difference(e.at) < _cacheTtl) {
      return (e.data as List).cast<T>();
    }
    final data = await fetch();
    if (data.isNotEmpty) _cache[key] = _CacheEntry(data, DateTime.now());
    return data;
  }

  /// Vide le cache (ex. rafraîchissement manuel).
  static void clearCache() => _cache.clear();

  // ── Profil utilisateur ───────────────────────────────────────────────────

  /// Découpe un nom complet en `firstName` / `lastName` pour la collection
  /// `users` (qui attend ces deux champs séparés).
  static Map<String, dynamic> splitFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return {'firstName': 'Utilisateur', 'lastName': ''};
    }
    return {
      'firstName': parts.first,
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
    };
  }

  /// Crée ou met à jour le profil d'un utilisateur dans la collection `users`.
  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      // Vérifier si le document existe déjà
      final exists = await profileExists(uid);
      if (exists) {
        await AppwriteClient.databases.updateDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteUsersCollectionId,
          documentId: uid,
          data: data,
        );
      } else {
        await AppwriteClient.databases.createDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteUsersCollectionId,
          documentId: uid,
          data: {
            ...data,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
      _cache.remove('profile:$uid');
    } on AppwriteException {
      rethrow;
    }
  }

  /// Retourne le profil d'un utilisateur sous forme de Map, ou null s'il
  /// n'existe pas.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final key = 'profile:$uid';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.data as Map<String, dynamic>?;
    }
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteUsersCollectionId,
        documentId: uid,
      );
      _cache[key] = _CacheEntry(doc.data, DateTime.now());
      return doc.data;
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      // Hors-ligne / erreur : on sert le dernier profil connu s'il existe.
      if (cached != null) return cached.data as Map<String, dynamic>?;
      rethrow;
    }
  }

  /// Met à jour certains champs du profil.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await AppwriteClient.databases.updateDocument(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteUsersCollectionId,
      documentId: uid,
      data: data,
    );
    _cache.remove('profile:$uid');
  }

  /// Vérifie si le profil d'un utilisateur existe déjà.
  Future<bool> profileExists(String uid) async {
    return await getUserProfile(uid) != null;
  }

  /// Catalogue des séries / filières (toutes confondues, filtrées par cursus
  /// côté UI). Configuré par l'admin dans la collection `exam_series`.
  /// Tolérant hors-ligne (cache mémoire) ; renvoie une liste vide en cas
  /// d'échec pour laisser l'UI basculer sur une saisie libre.
  Future<List<ExamSeries>> getExamSeries({bool force = false}) {
    return _cachedList<ExamSeries>('exam_series', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteExamSeriesCollectionId,
          queries: [Query.limit(500)],
        );
        return res.documents
            .map((d) => ExamSeries.fromMap(d.data))
            .where((s) => s.active && s.name.isNotEmpty)
            .toList();
      } on AppwriteException {
        return <ExamSeries>[];
      }
    }, force: force);
  }

  /// Liens des réseaux sociaux (configurés par l'admin dans `social_links`).
  /// Triés par `order`, actifs uniquement, tolérant (liste vide si échec).
  Future<List<SocialLink>> getSocialLinks({bool force = false}) {
    return _cachedList<SocialLink>('social_links', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteSocialLinksCollectionId,
          queries: [Query.limit(50)],
        );
        final list = res.documents
            .map((d) => SocialLink.fromMap(d.data))
            .where((s) => s.active && s.url.isNotEmpty && s.label.isNotEmpty)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return list;
      } on AppwriteException {
        return <SocialLink>[];
      }
    }, force: force);
  }

  // ── Résultats d'examens ──────────────────────────────────────────────────

  /// Sauvegarde un résultat dans la collection `results`.
  Future<void> saveResult(String uid, Map<String, dynamic> result) async {
    await AppwriteClient.databases.createDocument(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteResultsCollectionId,
      documentId: ID.unique(),
      data: {
        ...result,
        'userId': uid,
        'savedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Recherche un résultat publié par type d'examen + numéro de table.
  /// Retourne `null` si rien ne correspond (ou en cas d'erreur réseau).
  Future<ExamResult?> lookupResult({
    required String examType,
    required String tableNumber,
    String? year,
  }) async {
    final table = tableNumber.trim();
    if (table.isEmpty) return null;
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExamResultsCollectionId,
        queries: [
          Query.equal('examType', examType),
          Query.equal('tableNumber', table),
          if (year != null && year.isNotEmpty) Query.equal('year', year),
          Query.limit(1),
        ],
      );
      if (res.documents.isEmpty) return null;
      final d = res.documents.first;
      return ExamResult.fromMap(d.data, id: d.$id);
    } on AppwriteException {
      return null;
    }
  }

  /// Retourne les résultats d'un utilisateur.
  Future<List<Map<String, dynamic>>> getResults(String uid) async {
    final result = await AppwriteClient.databases.listDocuments(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteResultsCollectionId,
      queries: [Query.equal('userId', uid)],
    );
    return result.documents.map((d) => d.data).toList();
  }

  // ── Fil d'actualités ─────────────────────────────────────────────────────

  /// Retourne les articles du fil OnBuch, les plus récents d'abord.
  ///
  /// Renvoie une liste vide en cas d'erreur (collection absente, réseau…) afin
  /// que l'écran d'accueil puisse afficher un contenu de repli sans planter.
  Future<List<Article>> getArticles({int limit = 6}) {
    return _cachedList('articles:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteArticlesCollectionId,
          queries: [
            Query.orderDesc('\$createdAt'),
            Query.limit(limit),
          ],
        );
        return res.documents
            .map((d) => Article.fromMap(
                  d.data,
                  id: d.$id,
                  createdAtFallback: d.$createdAt,
                ))
            .toList();
      } on AppwriteException {
        return const <Article>[];
      }
    });
  }

  /// Retourne un article par son ID, ou null s'il est introuvable.
  Future<Article?> getArticleById(String id) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteArticlesCollectionId,
        documentId: id,
      );
      return Article.fromMap(doc.data, id: doc.$id, createdAtFallback: doc.$createdAt);
    } on AppwriteException {
      return null;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Retourne les notifications (gérées côté admin), les plus récentes d'abord.
  /// Liste vide en cas d'erreur (collection absente, réseau…), pour ne pas
  /// planter l'écran.
  Future<List<AppNotification>> getNotifications({int limit = 30}) {
    return _cachedList('notifications:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteNotificationsCollectionId,
          queries: [
            Query.orderDesc('\$createdAt'),
            Query.limit(limit),
          ],
        );
        return res.documents
            .map((d) => AppNotification.fromMap(
                  d.data,
                  id: d.$id,
                  createdAtFallback: d.$createdAt,
                ))
            .toList();
      } on AppwriteException {
        return const <AppNotification>[];
      }
    });
  }

  // ── Examens (carrousel d'accueil) ─────────────────────────────────────────

  /// Retourne les examens configurés, triés par `order` croissant.
  /// Liste vide en cas d'erreur (l'accueil affiche alors un repli).
  Future<List<Exam>> getExams({int limit = 20}) {
    return _cachedList('exams:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteExamsCollectionId,
          queries: [
            Query.orderAsc('order'),
            Query.limit(limit),
          ],
        );
        return res.documents
            .map((d) => Exam.fromMap(d.data, id: d.$id, createdAtFallback: d.$createdAt))
            .toList();
      } on AppwriteException {
        return const <Exam>[];
      }
    });
  }

  // ── Calendrier scolaire ───────────────────────────────────────────────────

  /// Retourne les événements du calendrier scolaire, du plus ancien au plus
  /// récent. Liste vide en cas d'erreur.
  Future<List<CalendarEvent>> getCalendarEvents({int limit = 100}) {
    return _cachedList('calendar:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteSchoolCalendarCollectionId,
          queries: [
            Query.orderAsc('startDate'),
            Query.limit(limit),
          ],
        );
        return res.documents
            .map((d) => CalendarEvent.fromMap(d.data, id: d.$id))
            .toList();
      } on AppwriteException {
        return const <CalendarEvent>[];
      }
    });
  }

  // ── Concours ──────────────────────────────────────────────────────────────

  /// Retourne les concours (triés par `order`). Liste vide en cas d'erreur.
  Future<List<Concours>> getConcours({int limit = 50}) {
    return _cachedList('concours:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteConcoursCollectionId,
          queries: [
            Query.orderAsc('order'),
            Query.limit(limit),
          ],
        );
        return res.documents.map((d) => Concours.fromMap(d.data, id: d.$id)).toList();
      } on AppwriteException {
        return const <Concours>[];
      }
    });
  }

  /// Centres de préparation aux concours (triés par `order`).
  Future<List<PrepCenter>> getPrepCenters({int limit = 30}) {
    return _cachedList('prep_centers:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwritePrepCentersCollectionId,
          queries: [Query.orderAsc('order'), Query.limit(limit)],
        );
        return res.documents.map((d) => PrepCenter.fromMap(d.data, id: d.$id)).toList();
      } on AppwriteException {
        return const <PrepCenter>[];
      }
    });
  }

  /// Ressources de préparation aux concours (triées par `order`).
  Future<List<ConcoursResource>> getConcoursResources({int limit = 40}) {
    return _cachedList('concours_resources:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteConcoursResourcesCollectionId,
          queries: [Query.orderAsc('order'), Query.limit(limit)],
        );
        return res.documents.map((d) => ConcoursResource.fromMap(d.data, id: d.$id)).toList();
      } on AppwriteException {
        return const <ConcoursResource>[];
      }
    });
  }

  /// Enregistre une candidature de l'utilisateur à un concours (privée).
  Future<ConcoursApplication> createApplication({
    required String uid,
    required String concoursId,
    required String concoursName,
    String? examLabel,
    String? receiptNo,
  }) async {
    final now = DateTime.now();
    final doc = await AppwriteClient.databases.createDocument(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteConcoursApplicationsCollectionId,
      documentId: ID.unique(),
      data: {
        'userId': uid,
        'concoursId': concoursId,
        'concoursName': concoursName,
        'status': 'submitted',
        if (examLabel != null) 'examLabel': examLabel,
        if (receiptNo != null) 'receiptNo': receiptNo,
        'createdAt': now.toIso8601String(),
      },
      permissions: [
        Permission.read(Role.user(uid)),
        Permission.update(Role.user(uid)),
        Permission.delete(Role.user(uid)),
      ],
    );
    return ConcoursApplication.fromMap(doc.data, id: doc.$id, createdAtFallback: doc.$createdAt);
  }

  /// Candidatures de l'utilisateur connecté (les plus récentes d'abord).
  Future<List<ConcoursApplication>> getMyApplications(String uid) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteConcoursApplicationsCollectionId,
        queries: [Query.equal('userId', uid), Query.orderDesc('\$createdAt'), Query.limit(50)],
      );
      return res.documents
          .map((d) => ConcoursApplication.fromMap(d.data, id: d.$id, createdAtFallback: d.$createdAt))
          .toList();
    } on AppwriteException {
      return const <ConcoursApplication>[];
    }
  }

  // ── Cours (matières & chapitres) ──────────────────────────────────────────

  /// Matières, triées par `order`.
  Future<List<Subject>> getSubjects({int limit = 50}) {
    return _cachedList('subjects:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteSubjectsCollectionId,
          queries: [Query.orderAsc('order'), Query.limit(limit)],
        );
        return res.documents.map((d) => Subject.fromMap(d.data, id: d.$id)).toList();
      } on AppwriteException {
        return const <Subject>[];
      }
    });
  }

  /// Tous les chapitres (filtrés côté app par matière), triés par `order`.
  Future<List<Chapter>> getChapters({int limit = 500}) {
    return _cachedList('chapters:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteChaptersCollectionId,
          queries: [Query.orderAsc('order'), Query.limit(limit)],
        );
        return res.documents.map((d) => Chapter.fromMap(d.data, id: d.$id)).toList();
      } on AppwriteException {
        return const <Chapter>[];
      }
    });
  }

  /// Fiche de cours mise en cache pour un chapitre, ou null si non générée.
  Future<String?> getLesson(String chapterId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteLessonsCollectionId,
        documentId: chapterId,
      );
      final c = doc.data['content']?.toString() ?? '';
      return c.trim().isEmpty ? null : c;
    } on AppwriteException {
      return null;
    }
  }

  /// QCM mis en cache pour un chapitre, ou null si non généré.
  Future<List<QuizQuestion>?> getQuiz(String chapterId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteQuizzesCollectionId,
        documentId: chapterId,
      );
      final c = doc.data['content']?.toString() ?? '';
      return c.trim().isEmpty ? null : parseQuiz(c);
    } on AppwriteException {
      return null;
    }
  }

  /// IDs des chapitres déjà consultés par l'utilisateur.
  Future<Set<String>> getViewedChapterIds() async {
    try {
      // La sécurité par document limite déjà aux progrès de l'utilisateur.
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteChapterProgressCollectionId,
        queries: [Query.limit(500)],
      );
      return res.documents.map((d) => d.data['chapterId']?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
    } on AppwriteException {
      return <String>{};
    }
  }

  /// Marque un chapitre comme consulté (idempotent côté UI).
  Future<void> markChapterViewed(String chapterId) async {
    try {
      final user = await AppwriteClient.account.get();
      await AppwriteClient.databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteChapterProgressCollectionId,
        documentId: ID.unique(),
        data: {
          'uid': user.$id,
          'chapterId': chapterId,
          'viewedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );
    } on AppwriteException {
      // non bloquant
    }
  }

  // ── À l'affiche (événements & partenaires) ────────────────────────────────

  /// Éléments « À l'affiche », triés par `order`. Liste vide en cas d'erreur.
  Future<List<AfficheItem>> getAffiche({int limit = 30}) {
    return _cachedList('affiche:$limit', () async {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteAfficheCollectionId,
          queries: [Query.orderAsc('order'), Query.limit(limit)],
        );
        return res.documents.map((d) => AfficheItem.fromMap(d.data, id: d.$id)).toList();
      } on AppwriteException {
        return const <AfficheItem>[];
      }
    });
  }

  // ── Analytics ────────────────────────────────────────────────────────────

  /// Loggue un événement analytics dans la collection `analytics_events`.
  /// Silencieux en cas d'erreur pour ne pas bloquer l'UX.
  Future<void> logAnalyticsEvent(
    String name,
    Map<String, dynamic> params,
  ) async {
    try {
      await AppwriteClient.databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteAnalyticsCollectionId,
        documentId: ID.unique(),
        data: {
          'name': name,
          'params': params.entries.map((e) => '${e.key}=${e.value}').join(', '),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // Silencieux — les analytics ne doivent jamais bloquer l'UX
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime at;
  _CacheEntry(this.data, this.at);
}
