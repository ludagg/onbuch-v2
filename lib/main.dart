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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  // Amorce le prénom mis en cache pour l'afficher dès la première frame.
  await AuthService.primeNameCache();

  // Push (FCM). Tolérant : si Firebase n'est pas configuré (google-services.json
  // absent), l'app démarre quand même, simplement sans push.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushService.instance.init();
  } catch (_) {}

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const OnBuchApp());
}

class OnBuchApp extends StatelessWidget {
  const OnBuchApp({super.key});

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
