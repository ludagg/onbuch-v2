import 'database_service.dart';

/// Service analytics léger via Appwrite Database.
/// Les événements sont logués dans la collection `analytics_events`.
/// Toutes les méthodes sont silencieuses en cas d'erreur.
class AnalyticsService {
  static Future<void> logEvent(
    String name, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      await DatabaseService().logAnalyticsEvent(name, params ?? {});
    } catch (_) {}
  }

  static Future<void> logScreenView(String screen) =>
      logEvent('screen_view', {'screen': screen});

  static Future<void> logResultSearch(String exam) =>
      logEvent('result_search', {'exam': exam});

  static Future<void> logTutorPhotoTaken() => logEvent('tutor_photo');

  static Future<void> logAnnaleDownloaded(String subject) =>
      logEvent('annale_download', {'subject': subject});

  static Future<void> logLogin() => logEvent('login', {'method': 'email'});

  static Future<void> logSignUp() => logEvent('sign_up', {'method': 'email'});
}
