import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appwrite_client.dart';
import 'database_service.dart';
import 'push_service.dart';
import 'analytics_service.dart';

class AuthService extends ChangeNotifier {
  static const _loggedInKey = 'ob_logged_in';
  static const _nameKey = 'ob_user_name';

  // ── Cache utilisateur (mémoire) ────────────────────────────────────────────
  // Conserve l'utilisateur courant et son prénom le temps de la session, pour
  // un affichage **instantané** (le nom ne « recharge » plus à chaque retour
  // sur l'accueil ou le profil).
  static models.User? _userCache;

  /// Prénom de l'utilisateur, lisible **de façon synchrone** pour afficher le
  /// nom dès la première frame, sans clignotement « Bonjour 👋 ».
  static String? cachedFirstName;
  static String? cachedFullName;

  /// Amorce le cache du nom depuis le stockage local (à appeler au démarrage).
  /// Permet d'afficher le prénom dès l'ouverture, même hors-ligne.
  static Future<void> primeNameCache() async {
    if (cachedFullName != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_nameKey);
      if (name != null && name.trim().isNotEmpty) _setNameCache(name);
    } catch (_) {}
  }

  static void _setNameCache(String fullName) {
    final name = fullName.trim();
    if (name.isEmpty) return;
    cachedFullName = name;
    cachedFirstName = DatabaseService.splitFullName(name)['firstName'] as String?;
  }

  Future<void> _persistName(String fullName) async {
    _setNameCache(fullName);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, fullName.trim());
    } catch (_) {}
  }

  Future<void> _clearNameCache() async {
    _userCache = null;
    cachedFirstName = null;
    cachedFullName = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nameKey);
    } catch (_) {}
  }

  Future<void> _setLoggedIn(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, v);
    } catch (_) {}
  }

  Future<bool> _cachedLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loggedInKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Utilisateur courant ──────────────────────────────────────────────────

  Future<models.User?> getCurrentUser() async {
    // Sert immédiatement le dernier utilisateur connu et rafraîchit en
    // arrière-plan : l'UI ne reconstruit pas (donc ne clignote pas) à chaque
    // navigation, mais reste à jour.
    if (_userCache != null) {
      unawaited(_refreshUser()); // rafraîchit sans bloquer l'affichage
      return _userCache;
    }
    return _refreshUser();
  }

  Future<models.User?> _refreshUser() async {
    try {
      final user = await AppwriteClient.account.get();
      _userCache = user;
      if (user.name.trim().isNotEmpty) {
        await _persistName(user.name);
      }
      return user;
    } catch (_) {
      // Hors-ligne / erreur réseau : on garde le dernier utilisateur connu.
      return _userCache;
    }
  }

  /// Met à jour le nom affiché du compte (et le cache local du prénom).
  Future<void> updateName(String name) async {
    await AppwriteClient.account.updateName(name: name.trim());
    _userCache = null;
    await _persistName(name);
    notifyListeners();
  }

  /// Change le mot de passe (nécessite l'ancien).
  Future<void> updatePassword(String newPassword, String oldPassword) async {
    try {
      await AppwriteClient.account.updatePassword(password: newPassword, oldPassword: oldPassword);
    } on AppwriteException catch (e) {
      throw _mapError(e, action: _AuthAction.login);
    }
  }

  /// Désactive (supprime) le compte courant puis déconnecte. Irréversible côté
  /// utilisateur (le compte est bloqué côté Appwrite).
  Future<void> deleteAccount() async {
    try {
      await AppwriteClient.account.updateStatus();
    } on AppwriteException catch (e) {
      throw _mapError(e, action: _AuthAction.login);
    } finally {
      await signOut();
    }
  }

  /// Connecté ? Tolérant au hors-ligne : un échec **réseau** ne déconnecte pas
  /// l'utilisateur (on garde le dernier état connu) ; seul un vrai 401 le fait.
  Future<bool> isLoggedIn() async {
    try {
      await AppwriteClient.account.get();
      await _setLoggedIn(true);
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        await _setLoggedIn(false);
        return false;
      }
      return _cachedLoggedIn(); // erreur serveur/réseau → tolérance hors-ligne
    } catch (_) {
      return _cachedLoggedIn(); // pas de réseau → on garde l'état connu
    }
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
      // Supprimer toute session résiduelle avant d'en créer une nouvelle,
      // sinon Appwrite renvoie une erreur « session already active ».
      await _deleteExistingSession();
      final session = await AppwriteClient.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      await _setLoggedIn(true);
      _userCache = null; // forcer un rafraîchissement du nom au prochain accès
      await _refreshUser();
      unawaited(PushService.instance.registerForCurrentUser());
      AnalyticsService.logLogin();
      notifyListeners();
      return session.userId;
    } on AppwriteException catch (e) {
      throw _mapError(e, action: _AuthAction.login);
    }
  }

  // ── Création de compte ───────────────────────────────────────────────────

  /// Retourne l'ID utilisateur si la création réussit.
  Future<String> register(String email, String password, String name) async {
    try {
      // Repartir d'un état propre : aucune session ne doit être active avant
      // de créer le compte puis sa session.
      await _deleteExistingSession();

      final user = await AppwriteClient.account.create(
        userId: ID.unique(),
        email: email.trim(),
        password: password,
        name: name.trim(),
      );

      // Créer la session immédiatement après la création du compte.
      // Si une session existe déjà (cas de course), le compte est tout de même
      // créé et l'utilisateur est connecté : on ne traite pas ça comme un échec.
      try {
        await AppwriteClient.account.createEmailPasswordSession(
          email: email.trim(),
          password: password,
        );
      } on AppwriteException catch (e) {
        if (e.type != 'user_session_already_exists') rethrow;
      }

      await _setLoggedIn(true);
      _userCache = user;
      if (name.trim().isNotEmpty) await _persistName(name);
      unawaited(PushService.instance.registerForCurrentUser());
      AnalyticsService.logSignUp();
      notifyListeners();
      return user.$id;
    } on AppwriteException catch (e) {
      throw _mapError(e, action: _AuthAction.register);
    }
  }

  /// Supprime la session courante si elle existe. Silencieux si aucune session
  /// n'est active (utilisateur invité).
  Future<void> _deleteExistingSession() async {
    try {
      await AppwriteClient.account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // Pas de session active — rien à faire.
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await AppwriteClient.account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw _mapError(e, action: _AuthAction.login);
    } finally {
      await _setLoggedIn(false);
      await _clearNameCache();
      DatabaseService.clearCache();
      await PushService.instance.unregister();
      notifyListeners();
    }
  }

  // ── Mapping des erreurs Appwrite → messages en français ──────────────────

  String _mapError(AppwriteException e, {required _AuthAction action}) {
    // On se base d'abord sur le type d'erreur Appwrite (plus précis que le
    // simple code HTTP, qui est partagé par plusieurs situations).
    switch (e.type) {
      case 'user_already_exists':
        return 'Un compte existe déjà avec cet email.';
      case 'user_invalid_credentials':
        return 'Email ou mot de passe incorrect.';
      case 'user_session_already_exists':
        return 'Une session est déjà active. Déconnecte-toi puis réessaie.';
      case 'user_password_mismatch':
      case 'password_personal_data':
      case 'general_argument_invalid':
        return 'Mot de passe invalide (8 caractères minimum).';
      case 'user_blocked':
      case 'user_email_not_whitelisted':
        return 'Ce compte n\'est pas autorisé à se connecter.';
      case 'database_not_found':
      case 'collection_not_found':
        return 'Service indisponible : base de données non configurée.';
      case 'general_rate_limit_exceeded':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
    }

    // Repli sur le code HTTP si le type n'est pas reconnu.
    switch (e.code) {
      case 401:
        // Pendant l'inscription, un 401 ne veut pas dire « identifiants
        // incorrects » : le compte vient d'être saisi par l'utilisateur.
        return action == _AuthAction.register
            ? 'Impossible de finaliser l\'inscription. Réessaie.'
            : 'Email ou mot de passe incorrect.';
      case 409:
        return 'Un compte existe déjà avec cet email.';
      case 400:
        return 'Données invalides. Vérifie ton email et ton mot de passe.';
      case 404:
        return 'Service indisponible. Réessaie plus tard.';
      case 429:
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 503:
        return 'Service temporairement indisponible. Réessaie plus tard.';
      default:
        return e.message ?? 'Erreur réseau, réessaie.';
    }
  }
}

/// Contexte de l'action d'authentification, pour produire des messages
/// d'erreur adaptés (connexion vs inscription).
enum _AuthAction { login, register }
