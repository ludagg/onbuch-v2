// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';
import '../models/article.dart';
import 'appwrite_client.dart';

class DatabaseService {
  // ── Profil utilisateur ───────────────────────────────────────────────────

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
