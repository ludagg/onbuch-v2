import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import 'database_service.dart';

/// Récupère les notifications et gère l'état « lu / non lu » **localement**
/// (les IDs lus sont stockés dans `shared_preferences`).
class NotificationsService {
  static const _readKey = 'ob_notifs_read';

  final _db = DatabaseService();

  Future<List<AppNotification>> fetch({int limit = 30}) =>
      _db.getNotifications(limit: limit);

  Future<Set<String>> readIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_readKey) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _saveRead(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey, ids.toList());
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final ids = await readIds();
    if (ids.add(id)) await _saveRead(ids);
  }

  Future<void> markAllRead(Iterable<String> allIds) async {
    final ids = await readIds();
    ids.addAll(allIds);
    await _saveRead(ids);
  }

  /// Y a-t-il au moins une notification non lue ? (pour la pastille de la cloche)
  Future<bool> hasUnread() async {
    final list = await fetch();
    if (list.isEmpty) return false;
    final read = await readIds();
    return list.any((n) => !read.contains(n.id));
  }
}
