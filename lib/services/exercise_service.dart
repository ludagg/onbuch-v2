import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';
import '../models/exercise.dart';
import 'appwrite_client.dart';

/// Accès au module Exercices : chapitres, fiches, progression (trouvé/pas trouvé).
class ExerciseService {
  static final ExerciseService _i = ExerciseService._();
  factory ExerciseService() => _i;
  ExerciseService._();

  // Caches mémoire (session) pour la progression : sheetId → statut / docId.
  final Map<String, ExerciseStatus> _status = {};
  final Map<String, String> _docId = {};
  bool _progressLoaded = false;

  /// Tous les chapitres (filtrage par classe fait côté écran).
  Future<List<ExerciseChapter>> getChapters() async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExerciseChaptersCollectionId,
        queries: [Query.orderAsc('order'), Query.limit(300)],
      );
      return res.documents
          .map((d) => ExerciseChapter.fromMap(d.data, id: d.$id))
          .toList();
    } on AppwriteException {
      return const [];
    }
  }

  /// Les fiches d'un chapitre, triées.
  Future<List<ExerciseSheet>> getSheets(String chapterId) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExerciseSheetsCollectionId,
        queries: [
          Query.equal('chapterId', chapterId),
          Query.orderAsc('order'),
          Query.limit(100),
        ],
      );
      return res.documents
          .map((d) => ExerciseSheet.fromMap(d.data, id: d.$id))
          .toList();
    } on AppwriteException {
      return const [];
    }
  }

  /// Charge la progression de l'élève (sheetId → statut). Tolérant hors-ligne.
  Future<Map<String, ExerciseStatus>> loadProgress({bool force = false}) async {
    if (_progressLoaded && !force) return Map.of(_status);
    try {
      final user = await AppwriteClient.account.get();
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExerciseProgressCollectionId,
        queries: [Query.equal('userId', user.$id), Query.limit(500)],
      );
      _status.clear();
      _docId.clear();
      for (final d in res.documents) {
        final sid = (d.data['sheetId'] ?? '').toString();
        if (sid.isEmpty) continue;
        _status[sid] = exerciseStatusFrom((d.data['status'] ?? '').toString());
        _docId[sid] = d.$id;
      }
      _progressLoaded = true;
    } on AppwriteException {
      // hors-ligne / non connecté → on garde ce qu'on a
    }
    return Map.of(_status);
  }

  ExerciseStatus statusOf(String sheetId) => _status[sheetId] ?? ExerciseStatus.none;

  /// Enregistre le statut d'une fiche (upsert). Met à jour le cache.
  Future<void> setStatus(ExerciseSheet sheet, ExerciseStatus status) async {
    _status[sheet.id] = status; // optimiste
    try {
      final user = await AppwriteClient.account.get();
      final data = {
        'userId': user.$id,
        'sheetId': sheet.id,
        'subject': sheet.subject,
        'chapterId': sheet.chapterId,
        'status': exerciseStatusKey(status),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final perms = [
        Permission.read(Role.user(user.$id)),
        Permission.update(Role.user(user.$id)),
        Permission.delete(Role.user(user.$id)),
      ];
      var docId = _docId[sheet.id];
      if (docId == null) {
        // Cherche un doc existant (cache froid) avant de créer.
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteExerciseProgressCollectionId,
          queries: [
            Query.equal('userId', user.$id),
            Query.equal('sheetId', sheet.id),
            Query.limit(1),
          ],
        );
        if (res.documents.isNotEmpty) docId = res.documents.first.$id;
      }
      if (docId == null) {
        final created = await AppwriteClient.databases.createDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteExerciseProgressCollectionId,
          documentId: ID.unique(),
          data: data,
          permissions: perms,
        );
        _docId[sheet.id] = created.$id;
      } else {
        await AppwriteClient.databases.updateDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteExerciseProgressCollectionId,
          documentId: docId,
          data: data,
        );
        _docId[sheet.id] = docId;
      }
    } on AppwriteException {
      // non bloquant : le cache optimiste reste, on retentera plus tard
    }
  }
}
