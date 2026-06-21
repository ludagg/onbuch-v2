import 'package:flutter/material.dart';

/// Clé globale du ScaffoldMessenger : permet d'afficher une bannière in-app
/// (ex. notification reçue pendant que l'app est au premier plan) depuis
/// n'importe où, sans `BuildContext`.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Vrai uniquement si `Firebase.initializeApp()` a réussi (faux sur le web sans
/// config Firebase). Garde tout accès à FirebaseMessaging pour éviter le crash
/// « No Firebase app has been created ».
bool firebaseReady = false;
