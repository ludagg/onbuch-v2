import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Navigation ───────────────────────────────────────────────────────────

  /// Loggue une vue d'écran. Appeler depuis chaque écran ou depuis le router.
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // ── Résultats d'examens ──────────────────────────────────────────────────

  /// Loggue une recherche de résultat d'examen.
  Future<void> logResultSearch(String exam, String year) async {
    await _analytics.logEvent(
      name: 'result_search',
      parameters: {
        'exam': exam,
        'year': year,
      },
    );
  }

  // ── Tuteur IA ────────────────────────────────────────────────────────────

  /// Loggue une photo prise dans le tuteur IA.
  Future<void> logTutorPhotoTaken() async {
    await _analytics.logEvent(name: 'tutor_photo_taken');
  }

  // ── Annales ──────────────────────────────────────────────────────────────

  /// Loggue le téléchargement ou l'ouverture d'une annale.
  Future<void> logAnnaleDownloaded(String subject, String exam) async {
    await _analytics.logEvent(
      name: 'annale_downloaded',
      parameters: {
        'subject': subject,
        'exam': exam,
      },
    );
  }

  // ── Crédits / Paiements ──────────────────────────────────────────────────

  /// Loggue le démarrage d'un achat de crédits.
  Future<void> logCreditPurchaseStarted(String pack, double amount) async {
    await _analytics.logEvent(
      name: 'credit_purchase_started',
      parameters: {
        'pack': pack,
        'amount': amount,
        'currency': 'XAF',
      },
    );
  }

  // ── Authentification ─────────────────────────────────────────────────────

  /// Loggue une connexion réussie.
  Future<void> logLogin({String method = 'email'}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Loggue la création d'un nouveau compte.
  Future<void> logSignUp({String method = 'email'}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // ── Profil utilisateur ───────────────────────────────────────────────────

  /// Définit l'identifiant utilisateur pour les rapports Analytics.
  Future<void> setUserId(String uid) async {
    await _analytics.setUserId(id: uid);
  }

  /// Définit une propriété utilisateur (ex: classe, examen).
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
