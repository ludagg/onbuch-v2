import 'dart:typed_data';
// Implémentation conditionnelle : fichier réel sur mobile/desktop (dart:io),
// stub no-op sur le web (qui est de toute façon en ligne).
import 'offline_cache_stub.dart' if (dart.library.io) 'offline_cache_io.dart' as impl;

/// Cache local des fichiers d'annales pour la consultation **hors-ligne dans
/// l'app** (on ne télécharge rien dans l'espace de stockage de l'utilisateur).
class OfflineCache {
  /// Télécharge et stocke le PDF (clé = id du document). `true` si réussi.
  static Future<bool> save(String id, String url) => impl.save(id, url);

  /// Octets du PDF mis en cache (ou `null` si absent) — pour l'afficher offline.
  static Future<Uint8List?> readBytes(String id) => impl.readBytes(id);

  /// Supprime le fichier mis en cache.
  static Future<void> remove(String id) => impl.remove(id);
}
