import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Profil utilisateur ───────────────────────────────────────────────────

  /// Crée ou écrase le profil d'un utilisateur dans `users/{uid}`.
  Future<void> createUserProfile(
    String uid, {
    String? nom,
    String? classe,
    String? examen,
    String? serie,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'nom': nom ?? '',
      'classe': classe ?? '',
      'examen': examen ?? '',
      'serie': serie ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Retourne le profil d'un utilisateur sous forme de Map, ou null s'il
  /// n'existe pas.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Met à jour certains champs du profil sans écraser le document entier.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Vérifie si le profil d'un utilisateur existe déjà dans Firestore.
  Future<bool> profileExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ── Résultats d'examens ──────────────────────────────────────────────────

  /// Sauvegarde un résultat dans `users/{uid}/results`.
  Future<void> saveResult(String uid, Map<String, dynamic> resultData) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('results')
        .add({
          ...resultData,
          'savedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Retourne un Stream de résultats pour l'utilisateur, triés du plus récent.
  Stream<List<Map<String, dynamic>>> getResults(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('results')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Supprime un résultat sauvegardé.
  Future<void> deleteResult(String uid, String resultId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('results')
        .doc(resultId)
        .delete();
  }
}
