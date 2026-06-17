import 'package:appwrite/appwrite.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_globals.dart';
import '../appwrite_config.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import 'appwrite_client.dart';

/// Handler de messages reçus quand l'app est en **arrière-plan ou tuée**.
/// Doit être une fonction de premier niveau annotée `@pragma('vm:entry-point')`.
///
/// Pour un message « notification » (titre/corps), Android affiche déjà la
/// notification dans la barre système : rien à faire ici.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Push notifications via FCM + cibles Appwrite Messaging.
///
/// - Au démarrage : initialise les handlers (premier plan / tap / lancement).
/// - À la connexion : enregistre le token FCM comme cible push de l'utilisateur
///   (`account.createPushTarget`) et, optionnellement, l'abonne à un topic.
/// - À la déconnexion : supprime la cible.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const _targetKey = 'ob_push_target_id';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _inited = false;

  /// Initialise les écouteurs (une seule fois, après `Firebase.initializeApp`).
  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    // Affiche aussi les notifications quand l'app est au premier plan (iOS).
    await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    // Premier plan : on montre une bannière in-app (pas de notif système).
    FirebaseMessaging.onMessage.listen(_onForeground);

    // Tap sur une notification alors que l'app est en arrière-plan.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _navigateFrom(m));

    // App lancée (depuis l'état tué) par un tap sur une notification.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Laisser le routeur s'initialiser avant de naviguer.
      Future.delayed(const Duration(milliseconds: 700), () => _navigateFrom(initial));
    }

    // Le token FCM peut changer : on met la cible à jour.
    _fcm.onTokenRefresh.listen(_registerTarget);
  }

  // ── Enregistrement de la cible push (après connexion) ──────────────────────

  /// À appeler après une connexion réussie (et au démarrage si déjà connecté).
  Future<void> registerForCurrentUser() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;
      await _registerTarget(token);
      await _subscribeBroadcastTopic();
    } catch (_) {
      // Best-effort : le push ne doit jamais bloquer l'UX.
    }
  }

  Future<void> _registerTarget(String token) async {
    final account = AppwriteClient.account;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_targetKey);
    final providerId =
        appwriteFcmProviderId.isEmpty ? null : appwriteFcmProviderId;

    try {
      if (existing == null) {
        final id = ID.unique();
        await account.createPushTarget(
            targetId: id, identifier: token, providerId: providerId);
        await prefs.setString(_targetKey, id);
      } else {
        await account.updatePushTarget(targetId: existing, identifier: token);
      }
    } on AppwriteException catch (e) {
      // 404 : la cible enregistrée n'existe plus côté serveur → on la recrée.
      if (e.code == 404) {
        try {
          final id = ID.unique();
          await account.createPushTarget(
              targetId: id, identifier: token, providerId: providerId);
          await prefs.setString(_targetKey, id);
        } catch (_) {}
      }
      // Autres erreurs (réseau…) : on réessaiera à la prochaine ouverture.
    } catch (_) {}
  }

  /// Abonne l'appareil au topic de diffusion (si configuré), pour permettre à
  /// l'admin d'envoyer un push « à tous » en une seule fois.
  Future<void> _subscribeBroadcastTopic() async {
    if (appwritePushTopicId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final targetId = prefs.getString(_targetKey);
    if (targetId == null) return;
    final flag = 'ob_sub_${appwritePushTopicId}_$targetId';
    if (prefs.getBool(flag) == true) return;
    try {
      await AppwriteClient.messaging.createSubscriber(
        topicId: appwritePushTopicId,
        subscriberId: ID.unique(),
        targetId: targetId,
      );
      await prefs.setBool(flag, true);
    } catch (_) {}
  }

  /// À la déconnexion : retire la cible push de ce compte.
  Future<void> unregister() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetId = prefs.getString(_targetKey);
      if (targetId != null) {
        try {
          await AppwriteClient.account.deletePushTarget(targetId: targetId);
        } catch (_) {}
        await prefs.remove(_targetKey);
        // Nettoie les drapeaux d'abonnement de cette cible.
        for (final k in prefs.getKeys().where((k) => k.contains(targetId))) {
          await prefs.remove(k);
        }
      }
      await _fcm.deleteToken();
    } catch (_) {}
  }

  // ── Réception ──────────────────────────────────────────────────────────────

  void _onForeground(RemoteMessage m) {
    final title = m.notification?.title ?? m.data['title']?.toString();
    final body = m.notification?.body ?? m.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    final route = m.data['route']?.toString();
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      backgroundColor: OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 5),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          if (body != null && body.isNotEmpty)
            Text(body,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
        ],
      ),
      action: (route != null && route.startsWith('/'))
          ? SnackBarAction(
              label: 'Voir', textColor: OC.o200, onPressed: () => _navigate(route))
          : null,
    ));
  }

  void _navigateFrom(RemoteMessage m) {
    final route = m.data['route']?.toString();
    if (route != null) _navigate(route);
  }

  void _navigate(String route) {
    if (!route.startsWith('/')) return;
    try {
      appRouter.go(route);
    } catch (_) {}
  }
}
