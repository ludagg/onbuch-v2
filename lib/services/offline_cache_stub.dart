import 'dart:typed_data';

// Web : pas de système de fichiers — le hors-ligne « in-app » n'est pas requis
// (le web est en ligne). No-op.
Future<bool> save(String id, String url) async => false;
Future<Uint8List?> readBytes(String id) async => null;
Future<void> remove(String id) async {}
