import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_globals.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/theme_controller.dart';
import 'services/exam_structure_service.dart';
import 'services/local_notifications_service.dart';
import 'services/gamification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  // Amorce le prénom mis en cache pour l'afficher dès la première frame.
  await AuthService.primeNameCache();

  // Structure des examens : on restaure la dernière connue (cache disque) avant
  // le 1ᵉʳ build (offline-first), puis on rafraîchit en arrière-plan si réseau.
  await ExamStructureService.instance.loadFromCache();
  ExamStructureService.instance.refresh();

  // Thème : charge le mode choisi et applique la bonne palette AVANT le 1er build.
  await ThemeController.instance.load();
  final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  OC.applyBrightness(ThemeController.instance.resolve(platform));

  // Push (FCM). Tolérant : si Firebase n'est pas configuré (google-services.json
  // absent), l'app démarre quand même, simplement sans push.
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushService.instance.init();
  } catch (_) {
    firebaseReady = false;
  }

  // Rappels locaux de série (« façon Duolingo ») : init + planification depuis
  // l'état connu. Lancé sans bloquer le 1ᵉʳ frame ; best-effort.
  () async {
    try {
      await LocalNotificationsService.instance.init();
      await LocalNotificationsService.instance.requestPermission();
      await GamificationService.instance.load();
      final g = GamificationService.instance.state.value;
      await LocalNotificationsService.instance
          .reschedule(streak: g.streak, lastActive: g.lastActive);
    } catch (_) {/* sans notifications locales si indisponible */}
  }();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Liens de partage / deep links (onbuch://annale/{id} ou …/a/{id}) : gérés
  // directement par go_router (redirect → /annales/open/{id}).
  runApp(const OnBuchApp());
}

class OnBuchApp extends StatefulWidget {
  const OnBuchApp({super.key});

  @override
  State<OnBuchApp> createState() => _OnBuchAppState();
}

class _OnBuchAppState extends State<OnBuchApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.addListener(_onThemeChanged);
    _applyOverlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(_applyBrightness);

  // La luminosité système a changé (mode « système »).
  @override
  void didChangePlatformBrightness() => setState(_applyBrightness);

  void _applyBrightness() {
    final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    OC.applyBrightness(ThemeController.instance.resolve(platform));
    _applyOverlay();
  }

  void _applyOverlay() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: OC.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: OC.isDark ? Brightness.dark : Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OnBuch',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
