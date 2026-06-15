import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handler exécuté en background (doit être une fonction top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé dans main(). Pas besoin de le refaire.
  debugPrint('[FCM] Notification reçue en arrière-plan : ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Clé globale pour afficher des SnackBars depuis n'importe quel endroit.
  // À fournir depuis main.dart ou MaterialApp si vous souhaitez les SnackBars.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // ── Initialisation ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Enregistrer le handler background (appelé avant initialize()).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Demander la permission (iOS / Android 13+).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      '[FCM] Permission : ${settings.authorizationStatus.name}',
    );

    // 3. Configurer la présentation des notifications en foreground (iOS).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Handler pour les notifications reçues en foreground.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handler quand l'utilisateur tape sur une notification (app en fond).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Notification initiale (app était fermée).
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleMessageOpenedApp(initial);
    }
  }

  // ── Token ────────────────────────────────────────────────────────────────

  /// Retourne le FCM token de l'appareil, ou null si non disponible.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Erreur getToken : $e');
      return null;
    }
  }

  // ── Topics ───────────────────────────────────────────────────────────────

  /// Abonne l'appareil à un topic FCM (ex: 'resultats-bac-2026').
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Abonné au topic : $topic');
  }

  /// Désabonne l'appareil d'un topic FCM.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Désabonné du topic : $topic');
  }

  // ── Handlers internes ────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Notification foreground : ${message.notification?.title}');

    final title = message.notification?.title ?? 'OnBuch';
    final body = message.notification?.body ?? '';

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6A13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] App ouverte depuis notification : ${message.data}');
    // TODO: naviguer vers l'écran approprié en fonction de message.data
    // Exemple : if (message.data['type'] == 'results') context.go('/results');
  }
}
