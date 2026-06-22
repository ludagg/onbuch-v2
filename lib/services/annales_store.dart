import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/annale.dart';
import 'annale_download_stub.dart'
    if (dart.library.io) 'annale_download_io.dart' as dl;

/// Une épreuve téléchargée pour la consultation hors-ligne.
class OfflineAnnale {
  final String id; // id du document `annales` (le fichier sujet)
  final String title;
  final String subject;
  final String exam;
  final String track;
  final String year;
  final String path; // chemin du fichier local

  const OfflineAnnale({
    required this.id,
    required this.title,
    required this.subject,
    required this.exam,
    this.track = '',
    this.year = '',
    required this.path,
  });

  AnnaleRef get ref =>
      AnnaleRef(exam: exam, track: track, subject: subject, year: year, title: title);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'exam': exam,
        'track': track,
        'year': year,
        'path': path,
      };

  factory OfflineAnnale.fromJson(Map<String, dynamic> m) => OfflineAnnale(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        subject: (m['subject'] ?? '').toString(),
        exam: (m['exam'] ?? '').toString(),
        track: (m['track'] ?? '').toString(),
        year: (m['year'] ?? '').toString(),
        path: (m['path'] ?? '').toString(),
      );
}

/// Collections perso des annales (Favoris / Récents / Hors-ligne), persistées
/// **localement** via `shared_preferences`. Favoris et récents raisonnent au
/// niveau d'une épreuve (regroupement sujet/corrigé/vidéo) ; le hors-ligne au
/// niveau d'un fichier téléchargé.
class AnnalesStore extends ChangeNotifier {
  AnnalesStore._();
  static final AnnalesStore instance = AnnalesStore._();

  static const _favKey = 'ob_annales_favorites';
  static const _recentKey = 'ob_annales_recents';
  static const _offlineKey = 'ob_annales_offline';
  static const _recentCap = 30;

  bool _loaded = false;
  final List<AnnaleRef> _favorites = [];
  final List<AnnaleRef> _recents = [];
  final List<OfflineAnnale> _offline = [];

  /// Le téléchargement hors-ligne nécessite un système de fichiers (mobile).
  bool get offlineSupported => !kIsWeb;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites
        ..clear()
        ..addAll(_decodeRefs(prefs.getStringList(_favKey)));
      _recents
        ..clear()
        ..addAll(_decodeRefs(prefs.getStringList(_recentKey)));
      _offline
        ..clear()
        ..addAll((prefs.getStringList(_offlineKey) ?? const <String>[])
            .map(_tryDecode)
            .whereType<Map<String, dynamic>>()
            .map(OfflineAnnale.fromJson));
    } catch (_) {
      // Démarrage tolérant : collections vides si lecture impossible.
    }
  }

  // ── Favoris ────────────────────────────────────────────────────────────────
  List<AnnaleRef> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String groupKey) => _favorites.any((r) => r.groupKey == groupKey);

  Future<void> toggleFavorite(AnnaleRef ref) async {
    final i = _favorites.indexWhere((r) => r.groupKey == ref.groupKey);
    if (i >= 0) {
      _favorites.removeAt(i);
    } else {
      _favorites.insert(0, ref);
    }
    await _persist(_favKey, _favorites.map((r) => jsonEncode(r.toJson())).toList());
    notifyListeners();
  }

  // ── Récents ──────────────────────────────────────────────────────────────
  List<AnnaleRef> get recents => List.unmodifiable(_recents);

  Future<void> pushRecent(AnnaleRef ref) async {
    _recents.removeWhere((r) => r.groupKey == ref.groupKey);
    _recents.insert(0, ref);
    if (_recents.length > _recentCap) _recents.removeRange(_recentCap, _recents.length);
    await _persist(_recentKey, _recents.map((r) => jsonEncode(r.toJson())).toList());
    notifyListeners();
  }

  // ── Hors-ligne ─────────────────────────────────────────────────────────────
  List<OfflineAnnale> get downloads => List.unmodifiable(_offline);

  bool isDownloaded(String docId) => _offline.any((o) => o.id == docId);

  String? localPath(String docId) {
    for (final o in _offline) {
      if (o.id == docId) return o.path;
    }
    return null;
  }

  /// Télécharge le fichier d'une épreuve pour la consultation hors-ligne.
  /// Renvoie `true` en cas de succès.
  Future<bool> download(Annale a) async {
    if (!offlineSupported || !a.hasFile || isDownloaded(a.id)) return false;
    final path = await dl.downloadAnnaleFile(a.fileUrl!, a.id);
    if (path == null) return false;
    _offline.insert(
      0,
      OfflineAnnale(
        id: a.id,
        title: a.title.isEmpty ? a.subject : a.title,
        subject: a.subject,
        exam: a.exam,
        track: a.track,
        year: a.year,
        path: path,
      ),
    );
    await _saveOffline();
    notifyListeners();
    return true;
  }

  Future<void> removeDownload(String docId) async {
    final i = _offline.indexWhere((o) => o.id == docId);
    if (i < 0) return;
    final path = _offline[i].path;
    _offline.removeAt(i);
    await dl.deleteAnnaleFile(path);
    await _saveOffline();
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Future<void> _saveOffline() =>
      _persist(_offlineKey, _offline.map((o) => jsonEncode(o.toJson())).toList());

  Future<void> _persist(String key, List<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, values);
    } catch (_) {}
  }

  static List<AnnaleRef> _decodeRefs(List<String>? raw) => (raw ?? const <String>[])
      .map(_tryDecode)
      .whereType<Map<String, dynamic>>()
      .map(AnnaleRef.fromJson)
      .toList();

  static Map<String, dynamic>? _tryDecode(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
}
