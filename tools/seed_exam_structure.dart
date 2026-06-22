// Persiste la TAXONOMIE des annales dans la collection `exam_series` afin que
// l'admin gère exactement le même schéma que l'app cliente :
//   examen → subdivision (category) → série/filière (name + code) → matières.
// La source reste `lib/data/exam_taxonomy.dart` (zéro duplication) ; ce script
// l'aplatit et synchronise la base (upsert + suppression des entrées obsolètes).
//
// Usage :
//   APPWRITE_API_KEY="standard_xxx" \
//   /root/flutter-stable/bin/dart run tools/seed_exam_structure.dart
//
// Idempotent : IDs déterministes (hash du couple examen|filière).

import 'dart:convert';
import 'dart:io';

import 'package:onbuch/data/exam_taxonomy.dart';

const endpoint = 'https://nyc.cloud.appwrite.io/v1';
const project = '6a30463b00001375e229';
const database = '6a3047f8001d11d1b3c1';
const collection = 'exam_series';

late final String apiKey;

class Row {
  final String exam, category, name, code;
  final List<String> subjects;
  final int sortOrder;
  Row(this.exam, this.category, this.name, this.code, this.subjects, this.sortOrder);

  String get id => 'es${_fnv1a('$exam|$category|$name')}';
  String get subjectsCsv => subjects.join(', ');
}

// Hash FNV-1a 32 bits → hex (IDs Appwrite stables, <=36 car., valides).
String _fnv1a(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

List<Row> flatten() {
  final rows = <Row>[];
  var order = 0;
  for (final exam in examOrder) {
    final node = examTaxonomy[exam];
    if (node == null) continue;
    if (node.children.isEmpty) {
      // Examen-feuille composé par matières (ex. BEPC).
      rows.add(Row(exam, '', node.label, '', node.subjects, order++));
      continue;
    }
    for (final sub in node.children) {
      final kids = sub.children;
      final groupOfSubjects =
          kids.isNotEmpty && kids.every((c) => c.isLeaf && c.subjects.isEmpty && c.code.isEmpty);
      if (groupOfSubjects) {
        // Ex. GCE : « Science » / « Arts » = filière, ses feuilles = matières.
        rows.add(Row(exam, '', sub.label, '', kids.map((c) => c.label).toList(), order++));
      } else {
        // Séries / spécialités / écoles, chacune avec ses matières.
        for (final leaf in kids) {
          rows.add(Row(exam, sub.label, leaf.label, leaf.code, leaf.subjects, order++));
        }
      }
    }
  }
  return rows;
}

final _client = HttpClient();

Future<HttpClientResponse> _req(String method, String path, {Object? body}) async {
  final req = await _client.openUrl(method, Uri.parse('$endpoint$path'));
  req.headers.set('X-Appwrite-Project', project);
  req.headers.set('X-Appwrite-Key', apiKey);
  req.headers.set('Content-Type', 'application/json');
  if (body != null) req.add(utf8.encode(jsonEncode(body)));
  return req.close();
}

Future<String> _bodyOf(HttpClientResponse r) => r.transform(utf8.decoder).join();

Future<void> ensureAttribute(String type, Map<String, Object?> def) async {
  final r = await _req('POST', '/databases/$database/collections/$collection/attributes/$type', body: def);
  await _bodyOf(r);
  if (r.statusCode == 201 || r.statusCode == 202) {
    print('  + attribut ${def['key']} créé');
  } else if (r.statusCode == 409) {
    print('  • attribut ${def['key']} déjà présent');
  } else {
    print('  ⚠ attribut ${def['key']} : HTTP ${r.statusCode}');
  }
}

Future<void> waitAttributesAvailable() async {
  for (var i = 0; i < 30; i++) {
    final r = await _req('GET', '/databases/$database/collections/$collection/attributes');
    final j = jsonDecode(await _bodyOf(r)) as Map<String, dynamic>;
    final attrs = (j['attributes'] as List).cast<Map<String, dynamic>>();
    final hasNew = attrs.any((a) => a['key'] == 'subjects') && attrs.any((a) => a['key'] == 'code');
    final processing = attrs.any((a) => a['status'] == 'processing');
    if (hasNew && !processing) return;
    stdout.write('.');
    await Future.delayed(const Duration(seconds: 1));
  }
}

Future<List<String>> listExistingIds() async {
  final q = Uri.encodeComponent(jsonEncode({'method': 'limit', 'values': [1000]}));
  final r = await _req('GET', '/databases/$database/collections/$collection/documents?queries[]=$q');
  final j = jsonDecode(await _bodyOf(r)) as Map<String, dynamic>;
  return (j['documents'] as List).map((d) => (d as Map)['\$id'].toString()).toList();
}

Future<void> upsert(Row row) async {
  final data = {
    'exam': row.exam,
    'category': row.category,
    'name': row.name,
    'code': row.code,
    'subjects': row.subjectsCsv,
    'sortOrder': row.sortOrder,
    'active': true,
  };
  // Tente une création ; si 409 (existe), bascule en update.
  var r = await _req('POST', '/databases/$database/collections/$collection/documents',
      body: {'documentId': row.id, 'data': data});
  await _bodyOf(r);
  if (r.statusCode == 409) {
    r = await _req('PATCH', '/databases/$database/collections/$collection/documents/${row.id}',
        body: {'data': data});
    await _bodyOf(r);
  }
  if (r.statusCode >= 300) {
    print('  ⚠ ${row.exam} / ${row.name} : HTTP ${r.statusCode}');
  }
}

Future<void> deleteDoc(String id) async {
  final r = await _req('DELETE', '/databases/$database/collections/$collection/documents/$id');
  await _bodyOf(r);
}

Future<void> main() async {
  apiKey = Platform.environment['APPWRITE_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('APPWRITE_API_KEY manquant.');
    exit(1);
  }

  print('── Attributs (code, subjects) ──');
  await ensureAttribute('string', {'key': 'code', 'size': 16, 'required': false});
  await ensureAttribute('string', {'key': 'subjects', 'size': 4000, 'required': false});
  stdout.write('── Attente des attributs');
  await waitAttributesAvailable();
  print(' ok');

  final rows = flatten();
  print('── ${rows.length} filières/séries à synchroniser ──');

  final wanted = rows.map((r) => r.id).toSet();
  final existing = await listExistingIds();
  final stale = existing.where((id) => !wanted.contains(id)).toList();

  for (final row in rows) {
    await upsert(row);
  }
  print('  ✓ ${rows.length} entrées upsertées');

  if (stale.isNotEmpty) {
    print('── Suppression de ${stale.length} entrées obsolètes ──');
    for (final id in stale) {
      await deleteDoc(id);
    }
  }

  _client.close();
  print('Terminé. La collection « exam_series » reflète la taxonomie des annales.');
}
