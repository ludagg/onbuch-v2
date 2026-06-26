// Cache disque d'images — repli pour le Web (pas de dart:io ni de système de
// fichiers). Sur le Web, le navigateur gère déjà son cache HTTP : on renvoie
// toujours `null` pour que le widget retombe sur Image.network.
import 'dart:typed_data';

Future<Uint8List?> loadCachedImageBytes(String url) async => null;

Future<void> clearImageCache() async {}
