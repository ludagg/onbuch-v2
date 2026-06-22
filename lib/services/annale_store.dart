import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/annale.dart';

/// Stockage local (hors-ligne) des **favoris** et **récents** d'annales.
/// On mémorise le document complet (JSON) → consultable même sans réseau.
class AnnaleStore {
  AnnaleStore._();
  static final AnnaleStore instance = AnnaleStore._();
  factory AnnaleStore() => instance;

  static const _favKey = 'annale_favs_v1';
  static const _recKey = 'annale_recents_v1';
  static const _maxRecents = 30;

  Future<List<Annale>> _load(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Annale.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String key, List<Annale> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(list.map((a) => a.toJson()).toList()));
  }

  Future<List<Annale>> favorites() => _load(_favKey);
  Future<List<Annale>> recents() => _load(_recKey);

  Future<bool> isFavorite(String id) async => (await favorites()).any((a) => a.id == id);

  /// Ajoute/retire des favoris. Renvoie le nouvel état (true = favori).
  Future<bool> toggleFavorite(Annale a) async {
    final list = await favorites();
    final exists = list.any((x) => x.id == a.id);
    if (exists) {
      list.removeWhere((x) => x.id == a.id);
    } else {
      list.insert(0, a);
    }
    await _save(_favKey, list);
    return !exists;
  }

  /// Mémorise un document ouvert (en tête, sans doublon, borné).
  Future<void> recordRecent(Annale a) async {
    if (a.id.isEmpty) return;
    final list = await recents();
    list.removeWhere((x) => x.id == a.id);
    list.insert(0, a);
    if (list.length > _maxRecents) list.removeRange(_maxRecents, list.length);
    await _save(_recKey, list);
  }
}
