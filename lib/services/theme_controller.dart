import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilote le thème de l'app (clair / sombre / système), persisté localement.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'ob_theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Charge le mode sauvegardé (à appeler au démarrage, avant le 1er build).
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      switch (p.getString(_key)) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
        default:
          _mode = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, m.name);
    } catch (_) {}
  }

  /// Luminosité effective selon le mode choisi + la luminosité système.
  Brightness resolve(Brightness platform) => switch (_mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => platform,
      };
}
