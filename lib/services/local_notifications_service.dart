import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const int _welcomeId = 7000; // notif de bienvenue (une fois)
  static const _welcomeKey = 'notif_welcome_v1';
  static const List<int> _milestones = [3, 7, 30, 100];

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

  /// Notification de **bienvenue**, envoyée **une seule fois** (1ʳᵉ ouverture
  /// après installation). 100% locale — sert aussi de test « ça marche sans
  /// serveur ». Affichée immédiatement.
  Future<void> maybeSendWelcome() async {
    if (!_inited) await init();
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_welcomeKey) == true) return;
      final name = (AuthService.cachedFirstName ?? '').trim();
      final title = name.isEmpty ? 'Bienvenue sur OnBuch 🎓' : 'Bienvenue $name 🎓';
      await _plugin.show(
        _welcomeId,
        title,
        'Ravis de t\'accueillir ! Reviens chaque jour pour garder ta série, gagner de l\'XP et grimper au classement. — L\'équipe OnBuch',
        _details(),
        payload: 'welcome',
      );
      await p.setBool(_welcomeKey, true);
    } catch (e) {
      debugPrint('LocalNotifications.welcome: $e');
    }
  }

  /// (Re)planifie les rappels (1 par jour, à 18 h — dans les heures « calmes »
  /// 7 h–22 h). Messages contextuels : série, objectif du jour, anticipation de
  /// palier, et **alerte ligue / récap le dimanche soir**.
  /// [streak] = jours d'affilée, [lastActive] = 'YYYY-MM-DD', [weeklyXp] = XP de
  /// la semaine (pour le récap du dimanche).
  Future<void> reschedule({required int streak, required String lastActive, int weeklyXp = 0}) async {
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
        final m = _messageFor(
          gap: offset, // jours d'absence au moment du rappel
          streak: streak,
          weekday: when.weekday, // 7 = dimanche
          weeklyXp: weeklyXp,
        );
        await _plugin.zonedSchedule(
          _baseId + offset,
          m.title,
          m.body,
          when,
          _details(),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
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

  // ── Banque de messages contextuels (variés, 1/jour) ─────────────────────────
  _Msg _messageFor({required int gap, required int streak, required int weekday, required int weeklyXp}) {
    final name = (AuthService.cachedFirstName ?? '').trim();
    final v = name.isEmpty ? '' : ', $name';

    // Dimanche soir → alerte ligue + récap de la semaine (la semaine se termine).
    if (weekday == DateTime.sunday) {
      if (weeklyXp > 0) {
        return _Msg('🏆 Dernier jour de classement !',
            '$weeklyXp XP cette semaine$v. Un dernier effort ce soir pour bien finir et viser la promotion !', 'fire');
      }
      return _Msg('🏆 La semaine de classement se termine',
          'Gagne quelques XP ce soir$v pour ne pas te faire reléguer dans ta ligue.', 'alarm');
    }

    // Ce soir / aujourd'hui : pas encore venu.
    if (gap <= 0) {
      // Anticipation d'un palier : si revenir aujourd'hui atteint 3/7/30/100 j.
      if (streak > 0 && _milestones.contains(streak + 1)) {
        return _Msg('⚡ Plus qu\'un jour pour ${streak + 1} d\'affilée !',
            'Reviens aujourd\'hui$v et décroche ${streak + 1} jours de série. Ne lâche pas si près du but !', 'fire');
      }
      if (streak > 0) {
        return _Msg('🔥 Ta série de $streak jour${streak > 1 ? 's' : ''} t\'attend',
            'Ne la laisse pas s\'éteindre$v ! Un petit quiz suffit ce soir.', 'fire');
      }
      // Pas de série en cours → objectif du jour.
      return _Msg('🎯 Ton objectif du jour$v',
          'Fais 1 quiz sur OnBuch aujourd\'hui et lance ta série 🔥', 'alarm');
    }
    if (gap == 1) {
      return _Msg('😴 Léo s\'ennuie sans toi',
          'Reviens réviser un peu aujourd\'hui$v, il t\'attend.', 'sleepy');
    }
    if (gap == 2) {
      return _Msg('🥺 Ta série va s\'éteindre',
          'Un petit quiz suffit pour la sauver$v. On y va ?', 'sad');
    }
    if (gap == 3) {
      return _Msg('🥺 Léo t\'attend depuis 3 jours',
          'Reprends ta progression quand tu veux$v, à ton rythme.', 'sad');
    }
    if (gap >= 7) {
      return _Msg('🦁 Tu nous manques$v',
          'Ça fait une semaine… Reviens, on t\'a gardé ta place et plein de quiz t\'attendent.', 'sad');
    }
    return _Msg('🦁 OnBuch t\'attend$v',
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
