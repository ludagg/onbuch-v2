// FICHIER GÉNÉRÉ — À COMPLÉTER AVEC VOS VRAIES VALEURS FIREBASE
//
// Instructions :
//   1. Créez votre projet sur https://console.firebase.google.com
//   2. Ajoutez une application Android avec le package ID : cm.luvvix.onbuch
//   3. Téléchargez google-services.json → placez-le dans android/app/
//   4. Installez FlutterFire CLI : dart pub global activate flutterfire_cli
//   5. Exécutez : flutterfire configure
//      OU remplacez manuellement les valeurs ci-dessous.
//
// Voir FIREBASE_SETUP.md pour les instructions complètes.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions non configuré pour cette plateforme : $defaultTargetPlatform',
        );
    }
  }

  // ── ANDROID ────────────────────────────────────────────────────────────────
  // Remplacez ces valeurs avec celles de votre google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'VOTRE_API_KEY_ANDROID',
    appId: '1:VOTRE_SENDER_ID:android:VOTRE_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
  );

  // ── iOS ────────────────────────────────────────────────────────────────────
  // Remplissez si vous ciblez iOS. Sinon, vous pouvez laisser tel quel.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'VOTRE_API_KEY_IOS',
    appId: '1:VOTRE_SENDER_ID:ios:VOTRE_APP_ID_IOS',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
    iosBundleId: 'cm.luvvix.onbuch',
  );

  // ── macOS ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'VOTRE_API_KEY_MACOS',
    appId: '1:VOTRE_SENDER_ID:ios:VOTRE_APP_ID_MACOS',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
    iosBundleId: 'cm.luvvix.onbuch',
  );

  // ── Web ────────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'VOTRE_API_KEY_WEB',
    appId: '1:VOTRE_SENDER_ID:web:VOTRE_APP_ID_WEB',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
    authDomain: 'VOTRE_PROJECT_ID.firebaseapp.com',
  );
}
