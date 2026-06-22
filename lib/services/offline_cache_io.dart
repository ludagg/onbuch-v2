import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<Directory> _dir() async {
  final base = await getApplicationDocumentsDirectory();
  final d = Directory('${base.path}/annales_offline');
  if (!await d.exists()) await d.create(recursive: true);
  return d;
}

File _fileFor(Directory d, String id) => File('${d.path}/$id.pdf');

Future<bool> save(String id, String url) async {
  try {
    final res = await http.get(Uri.parse(url.trim()));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return false;
    final d = await _dir();
    await _fileFor(d, id).writeAsBytes(res.bodyBytes);
    return true;
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> readBytes(String id) async {
  try {
    final d = await _dir();
    final f = _fileFor(d, id);
    if (await f.exists()) return await f.readAsBytes();
  } catch (_) {}
  return null;
}

Future<void> remove(String id) async {
  try {
    final d = await _dir();
    final f = _fileFor(d, id);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
