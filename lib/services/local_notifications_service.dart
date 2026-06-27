import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../router/app_router.dart';
import 'auth_service.dart';

/// Rappels **locaux** « façon Duolingo » pour ramener l'élève faire sa série.
///
/// Programmés sur le téléphone (pas le serveur) : ils partent à l'heure locale,
/// fonctionnent hors-ligne, et sont **conditionnels** — dès que l'élève ouvre
/// l'app et valide sa série, on annule le rappel du jour et on (re)planifie les
/// suivants. S'il ne revient pas, les rappels pré-programmés des prochains jours
/// se déclenchent avec un ton qui s'intensifie (Léo s'ennuie → série en danger).
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  /// Heure du rappel quotidien (18 h, heure du Cameroun).
  static const int _hour = 18;
  static const int _horizonDays = 14; // nb de jours de rappels pré-programmés
  static const int _baseId = 7100; // plage d'IDs réservée à la série

  static const String _channelId = 'streak_reminders';

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      tzdata.initializeTimeZones();
      // Marché Cameroun (WAT, UTC+1, sans heure d'été) → fuseau fixe robuste.
      tz.setLocalLocation(tz.getLocation('Africa/Douala'));

      const android = AndroidInitializationSettings('@drawable/ic_stat_onbuch');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onTap,
      );

      // Canal Android (obligatoire ≥ Android 8).
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            'Rappels de série',
            description: 'Léo te rappelle de garder ta série de révision.',
            importance: Importance.high,
          ));
    } catch (e) {
      debugPrint('LocalNotifications.init: $e');
    }
  }

  /// Demande la permission de notifier (Android 13+, iOS). Best-effort.
  Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('LocalNotifications.requestPermission: $e');
    }
  }

  bool _isToday(String ymd, DateTime today) {
    String two(int v) => v.toString().padLeft(2, '0');
    return ymd == '${today.year}-${two(today.month)}-${two(today.day)}';
  }

  /// (Re)planifie les rappels de série à partir de l'état courant.
  /// [streak] = jours d'affilée, [lastActive] = 'YYYY-MM-DD' du dernier passage.
  Future<void> reschedule({required int streak, required String lastActive}) async {
    if (!_inited) await init();
    try {
      await _plugin.cancelAll();
      final now = tz.TZDateTime.now(tz.local);
      final doneToday = _isToday(lastActive, now);

      // Premier rappel : ce soir si pas encore fait et avant l'heure ; sinon demain.
      final startOffset = (!doneToday && now.hour < _hour) ? 0 : 1;

      for (var k = 0; k < _horizonDays; k++) {
        final offset = startOffset + k;
        final when = tz.TZDateTime(tz.local, now.year, now.month, now.day, _hour)
            .add(Duration(days: offset));
        if (!when.isAfter(now)) continue;
        // « gap » = nb de jours d'absence au moment où le rappel partira :
        //  - venu aujourd'hui (startOffset=1) → offsets 1,2,3… = 1,2,3 jours ;
        //  - pas encore venu, avant 18h (startOffset=0) → offset 0 = ce soir.
        final m = _messageFor(gap: offset, streak: streak);
        await _plugin.zonedSchedule(
          _baseId + offset,
          m.title,
          m.body,
          when,
          _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: m.payload,
        );
      }
    } catch (e) {
      debugPrint('LocalNotifications.reschedule: $e');
    }
  }

  /// Annule tous les rappels (ex. déconnexion).
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Rappels de série',
          channelDescription: 'Léo te rappelle de garder ta série de révision.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_onbuch',
        ),
        iOS: const DarwinNotificationDetails(),
      );

  // ── Banque de messages (ton qui s'intensifie selon l'absence) ───────────────
  _Msg _messageFor({required int gap, required int streak}) {
    final name = (AuthService.cachedFirstName ?? '').trim();
    final vocatif = name.isEmpty ? '' : ', $name';

    if (gap <= 0) {
      // Ce soir, pas encore venu aujourd'hui.
      if (streak > 0) {
        return _Msg('🔥 Ta série de $streak jour${streak > 1 ? 's' : ''} t\'attend',
            'Ne la laisse pas s\'éteindre$vocatif ! Ouvre OnBuch ce soir.', 'fire');
      }
      return _Msg('⏰ C\'est l\'heure de réviser$vocatif',
          'Quelques minutes sur OnBuch et tu démarres ta série 🔥', 'alarm');
    }
    if (gap == 1) {
      return _Msg('😴 Léo s\'ennuie sans toi',
          'Reviens réviser un peu aujourd\'hui$vocatif, il t\'attend.', 'sleepy');
    }
    if (gap == 2) {
      return _Msg('🥺 Ta série va s\'éteindre',
          'Un petit quiz suffit pour la sauver$vocatif. On y va ?', 'sad');
    }
    if (gap == 3) {
      return _Msg('🥺 Léo t\'attend depuis 3 jours',
          'Reprends ta progression quand tu veux$vocatif, à ton rythme.', 'sad');
    }
    return _Msg('🦁 OnBuch t\'attend$vocatif',
        'Reprends tes révisions aujourd\'hui — Léo serait content de te revoir.', 'sad');
  }

  void _onTap(NotificationResponse response) {
    // Au tap : on ouvre l'accueil (qui enregistre l'activité du jour).
    try {
      appRouter.go('/home');
    } catch (_) {}
  }
}

class _Msg {
  final String title;
  final String body;
  final String payload; // humeur de Léo associée (fire/alarm/sleepy/sad)
  const _Msg(this.title, this.body, this.payload);
}
