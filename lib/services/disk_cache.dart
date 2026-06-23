import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache **disque** (JSON via SharedPreferences) — rend le contenu disponible
/// **hors-ligne, même après un redémarrage** de l'app. On y stocke les données
/// brutes (maps Appwrite) par clé de cache ; les modèles sont reconstruits à la
/// lecture. Le cache mémoire (5 min) reste la 1re couche ; le disque est le
/// repli quand le réseau échoue.
class DiskCache {
  static const _prefix = 'ob_cache_';

  /// Enregistre une liste de documents bruts pour [key].
  static Future<void> writeList(String key, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode(data));
    } catch (_) {
      // Données non sérialisables / disque plein : on ignore (cache best-effort).
    }
  }

  /// Lit la liste de documents bruts mise en cache pour [key], ou null.
  static Future<List<Map<String, dynamic>>?> readList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Enregistre un document unique (ex. profil utilisateur).
  static Future<void> writeMap(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode(data));
    } catch (_) {}
  }

  /// Lit un document unique mis en cache pour [key], ou null.
  static Future<Map<String, dynamic>?> readMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Vide tout le cache disque (à la déconnexion).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
