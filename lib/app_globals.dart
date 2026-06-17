import 'package:flutter/material.dart';

/// Clé globale du ScaffoldMessenger : permet d'afficher une bannière in-app
/// (ex. notification reçue pendant que l'app est au premier plan) depuis
/// n'importe où, sans `BuildContext`.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
