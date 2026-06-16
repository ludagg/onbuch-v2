// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';
import '../models/article.dart';
import '../models/exam.dart';
import '../models/calendar_event.dart';
import '../models/course.dart';
import 'appwrite_client.dart';

class DatabaseService {
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
    } on AppwriteException {
      rethrow;
    }
  }

  /// Retourne le profil d'un utilisateur sous forme de Map, ou null s'il
  /// n'existe pas.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteUsersCollectionId,
        documentId: uid,
      );
      return doc.data;
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
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
  }

  /// Vérifie si le profil d'un utilisateur existe déjà.
  Future<bool> profileExists(String uid) async {
    return await getUserProfile(uid) != null;
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
  Future<List<Article>> getArticles({int limit = 6}) async {
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
      return const [];
    }
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

  // ── Examens (carrousel d'accueil) ─────────────────────────────────────────

  /// Retourne les examens configurés, triés par `order` croissant.
  /// Liste vide en cas d'erreur (l'accueil affiche alors un repli).
  Future<List<Exam>> getExams({int limit = 20}) async {
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
      return const [];
    }
  }

  // ── Calendrier scolaire ───────────────────────────────────────────────────

  /// Retourne les événements du calendrier scolaire, du plus ancien au plus
  /// récent. Liste vide en cas d'erreur.
  Future<List<CalendarEvent>> getCalendarEvents({int limit = 100}) async {
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
      return const [];
    }
  }

  // ── Cours & fiches ───────────────────────────────────────────────────────

  /// Retourne tous les cours/fiches, triés par matière puis `order`, filtrés
  /// côté client selon la classe / série de l'élève. Sert à l'écran
  /// bibliothèque pour compter le contenu par matière. Liste vide en cas
  /// d'erreur (la bibliothèque affiche alors un repli).
  Future<List<Course>> getAllCourses({
    String? classe,
    String? serie,
    int limit = 500,
  }) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteCoursesCollectionId,
        queries: [
          Query.orderAsc('subject'),
          Query.orderAsc('order'),
          Query.limit(limit),
        ],
      );
      return res.documents
          .map((d) => Course.fromMap(d.data, id: d.$id, createdAtFallback: d.$createdAt))
          .where((c) => c.matchesProfile(profileClasse: classe, profileSerie: serie))
          .toList();
    } on AppwriteException {
      return const [];
    }
  }

  /// Retourne les cours/fiches d'une matière, triés par `order`, filtrés selon
  /// la classe / série. [kind] vide = cours + fiches confondus.
  Future<List<Course>> getCoursesBySubject(
    CourseSubject subject, {
    String? classe,
    String? serie,
    String kind = '',
    int limit = 200,
  }) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteCoursesCollectionId,
        queries: [
          Query.equal('subject', subject.key),
          if (kind.isNotEmpty) Query.equal('kind', kind),
          Query.orderAsc('order'),
          Query.limit(limit),
        ],
      );
      return res.documents
          .map((d) => Course.fromMap(d.data, id: d.$id, createdAtFallback: d.$createdAt))
          .where((c) => c.matchesProfile(profileClasse: classe, profileSerie: serie))
          .toList();
    } on AppwriteException {
      return const [];
    }
  }

  /// Retourne un cours/fiche par son ID, ou null s'il est introuvable.
  Future<Course?> getCourseById(String id) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteCoursesCollectionId,
        documentId: id,
      );
      return Course.fromMap(doc.data, id: doc.$id, createdAtFallback: doc.$createdAt);
    } on AppwriteException {
      return null;
    }
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
