// Implémentation mobile/desktop : télécharge un fichier d'annale et l'écrit dans
// le dossier documents de l'app (consultable hors-ligne). Sélectionné via import
// conditionnel quand `dart:io` est disponible.
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Télécharge [url] et l'enregistre sous `annales/<id>.pdf`. Renvoie le chemin
/// local, ou null en cas d'échec.
Future<String?> downloadAnnaleFile(String url, String id) async {
  HttpClient? client;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/annales');
    if (!await folder.exists()) await folder.create(recursive: true);
    final file = File('${folder.path}/$id.pdf');

    client = HttpClient();
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close();
    if (resp.statusCode != 200) return null;

    final bytes = <int>[];
    await for (final chunk in resp) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return null;
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  } finally {
    client?.close(force: true);
  }
}

/// Supprime un fichier téléchargé (silencieux si absent).
Future<void> deleteAnnaleFile(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

/// Lit les octets d'un fichier local (pour le lecteur PDF hors-ligne).
Future<Uint8List?> readLocalBytes(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) return await f.readAsBytes();
  } catch (_) {}
  return null;
}
