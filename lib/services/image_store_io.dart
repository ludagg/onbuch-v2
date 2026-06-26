// Cache disque d'images — implémentation mobile/desktop (dart:io).
// Télécharge une image une fois, la stocke dans le dossier de support de l'app,
// et la ressert depuis le disque ensuite (disponible HORS-LIGNE, même après
// redémarrage). 100 % Dart (http + path_provider) → patchable Shorebird.
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Directory? _dir;
final Map<String, Future<Uint8List?>> _inflight = {};

Future<Directory> _cacheDir() async {
  if (_dir != null) return _dir!;
  final base = await getApplicationSupportDirectory();
  final d = Directory('${base.path}/img_cache');
  if (!await d.exists()) await d.create(recursive: true);
  _dir = d;
  return d;
}

// Nom de fichier déterministe (FNV-1a 64 bits, ramené positif) + longueur d'URL.
String _key(String url) {
  var h = 0xcbf29ce484222325;
  for (final b in url.codeUnits) {
    h = (h ^ b) * 0x100000001b3;
  }
  return '${h.toUnsigned(63).toRadixString(16)}_${url.length}';
}

/// Renvoie les octets de l'image (depuis le disque si déjà en cache, sinon
/// télécharge et met en cache). `null` si URL vide, hors-ligne sans cache, ou
/// échec — l'appelant retombe alors sur le réseau / un widget d'erreur.
Future<Uint8List?> loadCachedImageBytes(String url) async {
  if (url.trim().isEmpty) return null;
  try {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_key(url)}');
    if (await file.exists()) {
      final len = await file.length();
      if (len > 0) return await file.readAsBytes();
    }
    // Déduplique les téléchargements concurrents de la même URL.
    return await _inflight.putIfAbsent(url, () => _download(url, file));
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _download(String url, File file) async {
  try {
    final resp =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      return resp.bodyBytes;
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    _inflight.remove(url);
  }
}

/// Vide le cache disque d'images (ex. à la déconnexion). Best-effort.
Future<void> clearImageCache() async {
  try {
    final dir = await _cacheDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    _dir = null;
  } catch (_) {}
}
