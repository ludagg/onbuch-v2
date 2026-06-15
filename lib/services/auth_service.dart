import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Getters ──────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  // ── Connexion email / mot de passe ───────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Création de compte ───────────────────────────────────────────────────

  Future<UserCredential> createAccount(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ── Réinitialisation mot de passe ────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Mapping des erreurs Firebase → messages en français ──────────────────

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet e-mail.';
      case 'wrong-password':
        return 'Mot de passe incorrect. Réessaie.';
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet e-mail.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible. Utilise au moins 6 caractères.';
      case 'user-disabled':
        return 'Ce compte a été désactivé. Contacte le support.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 'network-request-failed':
        return 'Problème de connexion internet. Vérifie ton réseau.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n\'est pas activée.';
      default:
        return e.message ?? 'Une erreur inattendue s\'est produite.';
    }
  }
}
