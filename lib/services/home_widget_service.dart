import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Met à jour le widget d'écran d'accueil « Ma série » (Android).
/// Les données sont écrites via home_widget puis le provider natif
/// (`StreakWidgetProvider`) les affiche. Best-effort : silencieux si le widget
/// n'est pas posé ou indisponible (iOS sans extension, web, etc.).
class HomeWidgetService {
  HomeWidgetService._();
  static const String _androidProvider = 'StreakWidgetProvider';

  /// Pousse la série courante vers le widget. [lastActive] = 'YYYY-MM-DD'
  /// (dernier jour d'activité) → sert à savoir si la série est validée du jour.
  static Future<void> updateStreak({required int streak, required String lastActive}) async {
    try {
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final today = '${now.year}-${two(now.month)}-${two(now.day)}';
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<bool>('streak_done_today', lastActive == today);
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (e) {
      debugPrint('HomeWidget.updateStreak: $e');
    }
  }
}
