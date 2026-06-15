import 'package:appwrite/appwrite.dart';
import 'appwrite_client.dart';

/// Service de push notifications via Appwrite Messaging.
///
/// IMPORTANT : Les push notifications Appwrite nécessitent une configuration
/// côté console (Appwrite Console → Messaging → Providers → FCM).
/// Un projet Firebase est requis UNIQUEMENT pour les credentials FCM —
/// aucun SDK Firebase n'est intégré dans cette app.
class MessagingService {
  /// Abonne l'appareil à un topic Appwrite Messaging.
  ///
  /// [topic] : ID du topic dans la console Appwrite.
  /// [targetId] : ID de la cible (device token) configurée côté console.
  static Future<void> subscribeToTopic(String topic,
      {String targetId = 'YOUR_TARGET_ID'}) async {
    try {
      await AppwriteClient.messaging.createSubscriber(
        topicId: topic,
        subscriberId: ID.unique(),
        targetId: targetId,
      );
    } catch (_) {
      // Silencieux — les notifications ne doivent pas bloquer l'UX
    }
  }
}
