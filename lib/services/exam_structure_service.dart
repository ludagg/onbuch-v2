import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/exam_taxonomy.dart';
import 'database_service.dart';

/// Source unique de la **structure** des examens (examen → subdivision →
/// série/filière → matières), construite à partir de la base `exam_series`
/// (éditable par l'admin), avec :
///   1. la taxonomie **statique** embarquée comme repli ultime (1ʳᵉ ouverture
///      hors-ligne) ;
///   2. un **cache disque** (`shared_preferences`) : la dernière structure connue
///      reste dispo hors-ligne ;
///   3. un **rafraîchissement** quand on est connecté (met à jour le cache).
///
/// Tous les écrans (Annales, création de compte) lisent [taxonomy] / [order]
/// d'ici → ajuster une matière/filière côté admin se répercute sans MAJ de l'app.
class ExamStructureService {
  ExamStructureService._();
  static final ExamStructureService instance = ExamStructureService._();
  factory ExamStructureService() => instance;

  static const _prefsKey = 'exam_structure_v1';

  Map<String, ExamNode> _taxonomy = examTaxonomy; // repli statique
  List<String> _order = examOrder;
  bool _cacheLoaded = false;

  Map<String, ExamNode> get taxonomy => _taxonomy;
  List<String> get order => _order;

  /// À appeler au démarrage : restaure la dernière structure connue (disque).
  Future<void> loadFromCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final built = _build(rows);
      if (built.$1.isNotEmpty) {
        _taxonomy = built.$1;
        _order = built.$2;
      }
    } catch (_) {/* cache illisible → on garde le statique */}
  }

  /// À appeler quand on a (peut-être) du réseau : récupère `exam_series`,
  /// reconstruit la structure et met à jour le cache disque. Silencieux si
  /// hors-ligne ou base vide (on conserve le cache/statique).
  Future<void> refresh() async {
    try {
      final series = await DatabaseService().getExamSeries(force: true);
      if (series.isEmpty) return;
      final rows = series
          .map((s) => {
                'exam': s.exam,
                'category': s.category ?? '',
                'name': s.name,
                'code': s.code,
                'subjects': s.subjects.join(', '),
                'sortOrder': s.sortOrder,
              })
          .toList();
      final built = _build(rows);
      if (built.$1.isEmpty) return;
      _taxonomy = built.$1;
      _order = built.$2;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(rows));
    } catch (_) {/* hors-ligne / erreur → on garde le cache */}
  }

  // Reconstruit l'arbre [ExamNode] à partir des lignes plates `exam_series`.
  (Map<String, ExamNode>, List<String>) _build(List<Map<String, dynamic>> rows) {
    int sortOf(Map r) {
      final v = r['sortOrder'];
      return v is int ? v : int.tryParse('$v') ?? 0;
    }

    final sorted = [...rows]..sort((a, b) => sortOf(a).compareTo(sortOf(b)));

    final order = <String>[];
    final byExam = <String, List<Map<String, dynamic>>>{};
    for (final r in sorted) {
      final ex = (r['exam'] ?? '').toString();
      if (ex.isEmpty) continue;
      (byExam[ex] ??= []).add(r);
      if (!order.contains(ex)) order.add(ex);
    }

    List<String> subjOf(Map r) => (r['subjects'] ?? '')
        .toString()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final tax = <String, ExamNode>{};
    for (final ex in order) {
      final rs = byExam[ex]!;
      // Examen composé directement par matières (ex. BEPC) : une seule ligne,
      // sans subdivision, dont le nom = l'examen → feuille avec matières.
      if (rs.length == 1 &&
          (rs[0]['category'] ?? '').toString().isEmpty &&
          (rs[0]['name'] ?? '').toString() == ex) {
        tax[ex] = ExamNode(ex, subjects: subjOf(rs[0]));
        continue;
      }
      final children = <ExamNode>[];
      final cats = <String, List<Map<String, dynamic>>>{};
      final catOrder = <String>[];
      for (final r in rs) {
        final c = (r['category'] ?? '').toString();
        (cats[c] ??= []).add(r);
        if (!catOrder.contains(c)) catOrder.add(c);
      }
      for (final c in catOrder) {
        final leaves = cats[c]!
            .map((r) => ExamNode((r['name'] ?? '').toString(),
                code: (r['code'] ?? '').toString(), subjects: subjOf(r)))
            .toList();
        if (c.isEmpty) {
          children.addAll(leaves); // filières sans subdivision (ex. GCE Science/Arts)
        } else {
          children.add(ExamNode(c, children: leaves)); // subdivision
        }
      }
      tax[ex] = ExamNode(ex, children: children);
    }
    return (tax, order);
  }
}
