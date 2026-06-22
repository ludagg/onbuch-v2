import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cours_packs_service.dart';
import 'database_service.dart';

/// Hors-ligne des packs de cours : met en cache le **contenu texte** des leçons
/// (et titres de chapitres) dans `shared_preferences` pour une lecture sans
/// réseau. Léger, multiplateforme, sans plugin natif (patchable Shorebird).
class CoursOffline extends ChangeNotifier {
  CoursOffline._();
  static final CoursOffline instance = CoursOffline._();

  SharedPreferences? _prefs;
  final Set<String> _downloaded = {};

  // État du téléchargement en cours (pour l'écran hors-ligne).
  String? activeSubject;
  int done = 0;
  int total = 0;
  bool downloading = false;
  bool paused = false;

  static const _indexKey = 'cours_offline_packs';
  String _packKey(String id) => 'cours_offline_$id';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _downloaded
      ..clear()
      ..addAll(_prefs!.getStringList(_indexKey) ?? const []);
  }

  bool isDownloaded(String subjectId) => _downloaded.contains(subjectId);
  Set<String> get downloaded => _downloaded;

  /// Contenu de leçon mis en cache (ou null si non téléchargé).
  String? offlineLesson(String subjectId, String chapterId) {
    final raw = _prefs?.getString(_packKey(subjectId));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final content = j['content'] as Map<String, dynamic>?;
      final c = content?[chapterId];
      final s = (c is Map) ? c['lesson']?.toString() : null;
      return (s == null || s.trim().isEmpty) ? null : s;
    } catch (_) {
      return null;
    }
  }

  /// Télécharge (met en cache) toutes les leçons d'un pack.
  Future<void> download(Pack p) async {
    await init();
    if (downloading) return;
    downloading = true;
    paused = false;
    activeSubject = p.id;
    total = p.modules.length;
    done = 0;
    notifyListeners();

    final db = DatabaseService();
    final content = <String, dynamic>{};
    for (final m in p.modules) {
      if (paused) break;
      String lesson = '';
      try {
        lesson = (await db.getLesson(m.id)) ?? '';
      } catch (_) {}
      content[m.id] = {'title': m.title, 'lesson': lesson};
      done++;
      notifyListeners();
    }

    if (!paused) {
      await _prefs!.setString(_packKey(p.id), jsonEncode({
        'name': p.name,
        'chapters': [for (final m in p.modules) {'id': m.id, 'title': m.title}],
        'content': content,
        'savedAt': DateTime.now().toIso8601String(),
      }));
      _downloaded.add(p.id);
      await _prefs!.setStringList(_indexKey, _downloaded.toList());
    }
    downloading = false;
    notifyListeners();
  }

  void pause() {
    paused = true;
    notifyListeners();
  }

  Future<void> remove(String subjectId) async {
    await init();
    await _prefs!.remove(_packKey(subjectId));
    _downloaded.remove(subjectId);
    await _prefs!.setStringList(_indexKey, _downloaded.toList());
    notifyListeners();
  }
}
