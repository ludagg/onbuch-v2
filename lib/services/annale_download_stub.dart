// Repli web : pas de téléchargement hors-ligne (système de fichiers absent).
// Sélectionné automatiquement quand `dart:io` n'est pas disponible.
import 'dart:typed_data';

Future<String?> downloadAnnaleFile(String url, String id) async => null;

Future<void> deleteAnnaleFile(String path) async {}

Future<Uint8List?> readLocalBytes(String path) async => null;
