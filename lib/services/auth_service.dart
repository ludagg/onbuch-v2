import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  // ── Utilisateur courant ──────────────────────────────────────────────────

  Future<models.User?> getCurrentUser() async {
    try {
      return await AppwriteClient.account.get();
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    return await getCurrentUser() != null;
  }

  Future<bool> hasProfile() async {
    final user = await getCurrentUser();
    if (user == null) return false;
    return DatabaseService().profileExists(user.$id);
  }

  // ── Connexion email / mot de passe ───────────────────────────────────────

  /// Retourne l'ID utilisateur si la connexion réussit.
  Future<String> signIn(String email, String password) async {
    try {
      final session = await AppwriteClient.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return session.userId;
    } on AppwriteException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Création de compte ───────────────────────────────────────────────────

  /// Retourne l'ID utilisateur si la création réussit.
  Future<String> register(String email, String password, String name) async {
    try {
      final user = await AppwriteClient.account.create(
        userId: ID.unique(),
        email: email.trim(),
        password: password,
        name: name.trim(),
      );
      // Créer la session immédiatement après la création du compte
      await AppwriteClient.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return user.$id;
    } on AppwriteException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await AppwriteClient.account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw _mapError(e);
    } finally {
      notifyListeners();
    }
  }

  // ── Mapping des erreurs Appwrite → messages en français ──────────────────

  String _mapError(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Email ou mot de passe incorrect.';
      case 409:
        return 'Un compte existe déjà avec cet email.';
      case 400:
        return 'Données invalides. Vérifie ton email et mot de passe.';
      case 429:
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 503:
        return 'Service temporairement indisponible. Réessaie plus tard.';
      default:
        return e.message ?? 'Erreur réseau, réessaie.';
    }
  }
}
