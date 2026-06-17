/// Notification affichée dans le centre de notifications.
///
/// Les notifications sont gérées côté admin (collection `notifications`).
/// L'état « lu / non lu » est, lui, conservé **localement** sur l'appareil.
class AppNotification {
  final String id;
  final String type; // result · exam · credit · course · promo · info
  final String title;
  final String body;
  final String? route; // lien profond optionnel (ex. /results)
  final String? imageUrl;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
    this.imageUrl,
  });

  factory AppNotification.fromMap(
    Map<String, dynamic> data, {
    required String id,
    required String createdAtFallback,
  }) {
    final created = (data['publishedAt'] ?? createdAtFallback).toString();
    return AppNotification(
      id: id,
      type: (data['type'] ?? 'info').toString().trim().toLowerCase(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      route: _nullableString(data['route']),
      imageUrl: _nullableString(data['imageUrl']),
      createdAt: DateTime.tryParse(created) ?? DateTime.now(),
    );
  }

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
