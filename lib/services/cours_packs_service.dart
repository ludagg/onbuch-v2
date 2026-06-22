import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../appwrite_config.dart';
import '../models/course.dart';
import 'appwrite_client.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'tutor_service.dart';

/// Un module de pack = un chapitre.
@immutable
class PackModule {
  final String id; // chapterId
  final String title;
  final bool free; // chapitre en aperçu gratuit
  const PackModule(this.id, this.title, {this.free = false});
}

/// Vue « pack » = matière (`subjects`) + ses chapitres + métadonnées d'achat.
@immutable
class Pack {
  final String id; // subjectId
  final String code;
  final String name;
  final String level;
  final int lessons;
  final int videos;
  final int quizzes;
  final int coef;
  final bool premium;
  final int price; // crédits
  final List<PackModule> modules;
  const Pack({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    required this.lessons,
    required this.videos,
    required this.quizzes,
    required this.coef,
    required this.premium,
    required this.price,
    this.modules = const [],
  });

  String? get firstLesson => modules.isEmpty ? null : modules.first.title;

  factory Pack.fromSubject(Subject s, List<Chapter> chapters) {
    final modules = <PackModule>[
      for (var i = 0; i < chapters.length; i++)
        PackModule(chapters[i].id, chapters[i].title.isEmpty ? 'Chapitre ${i + 1}' : chapters[i].title, free: i < s.freeChapters),
    ];
    return Pack(
      id: s.id,
      code: s.code,
      name: s.name,
      level: s.levels.trim().isEmpty ? '' : s.levels.trim(),
      lessons: chapters.length,
      videos: chapters.where((c) => (c.videoUrl ?? '').trim().isNotEmpty).length,
      quizzes: chapters.length,
      coef: s.coef,
      premium: s.premium,
      price: s.priceCredits,
      modules: modules,
    );
  }
}

/// Store réel des packs de cours : catalogue filtré par la classe de l'élève
/// (examen + série, comme les annales), bibliothèque possédée (`pack_purchases`),
/// progression, solde de crédits, achat en crédits.
class CoursPacks extends ChangeNotifier {
  CoursPacks._();
  static final CoursPacks instance = CoursPacks._();

  List<Pack> _packs = const [];
  final Set<String> _owned = {};
  final Set<String> _cart = {};
  final Map<String, double> _progress = {};
  int credits = 0;
  bool loading = false;
  bool loaded = false;
  String examLabel = '';
  String serieLabel = '';

  String get classLabel {
    final e = _short(examLabel);
    final s = serieLabel.trim();
    if (e.isEmpty) return s.isEmpty ? '' : 'Série $s';
    return s.isEmpty ? e : '$e · Série $s';
  }

  static String _short(String exam) {
    final e = exam.trim();
    if (e.toLowerCase().startsWith('bacc')) return 'Bac';
    if (e.toLowerCase().startsWith('prob')) return 'Probatoire';
    return e;
  }

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (loaded && !force) return;
    loading = true;
    notifyListeners();
    final db = DatabaseService();

    // Profil élève (examen + série) pour filtrer comme les annales.
    String? exam, serie;
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        final p = await db.getUserProfile(user.$id);
        exam = p?['examen']?.toString();
        serie = p?['serie']?.toString();
      }
    } catch (_) {}
    examLabel = exam ?? '';
    serieLabel = serie ?? '';

    final subjects = await db.getSubjects();
    final chapters = await db.getChapters();
    final viewed = await db.getViewedChapterIds();
    final owned = await db.getOwnedSubjectIds();
    try {
      credits = (await TutorService().getQuota()).credits;
    } catch (_) {}

    final applicable = subjects.where((s) => s.appliesToClass(exam, serie)).toList();
    _packs = applicable.map((s) {
      final chs = chapters.where((c) => c.subjectId == s.id).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return Pack.fromSubject(s, chs);
    }).toList();

    _owned
      ..clear()
      ..addAll(owned);
    _progress.clear();
    for (final s in applicable) {
      final chs = chapters.where((c) => c.subjectId == s.id).toList();
      _progress[s.id] = chs.isEmpty ? 0 : chs.where((c) => viewed.contains(c.id)).length / chs.length;
    }
    loaded = true;
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(force: true);

  bool isOwned(String id) => _owned.contains(id);
  bool inCart(String id) => _cart.contains(id);
  double progress(String id) => _progress[id] ?? 0;

  List<Pack> get catalogue => _packs;
  List<Pack> get library => _packs.where((p) => _owned.contains(p.id)).toList();
  List<Pack> get cart => _packs.where((p) => _cart.contains(p.id)).toList();
  List<Pack> get premiumAvailable => _packs.where((p) => p.premium && !isOwned(p.id)).toList();
  Pack? byId(String id) {
    for (final p in _packs) {
      if (p.id == id) return p;
    }
    return null;
  }

  int get cartSubtotal => cart.fold(0, (s, p) => s + p.price);
  int get bundlePrice => cart.length >= 2 ? (cartSubtotal * 0.7).round() : cartSubtotal;
  bool get hasBundle => cart.length >= 2;

  /// Gratuit → ajout direct à la bibliothèque ; premium → ajout au panier.
  Future<void> add(Pack p) async {
    if (p.premium) {
      _cart.add(p.id);
      notifyListeners();
    } else {
      final ok = await DatabaseService().addFreePack(p.id);
      if (ok) _owned.add(p.id);
      notifyListeners();
    }
  }

  void addAllToCart(Iterable<Pack> packs) {
    for (final p in packs) {
      if (p.premium && !isOwned(p.id)) _cart.add(p.id);
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cart.remove(id);
    notifyListeners();
  }

  /// Achète le panier avec les crédits OnBuch. `null` si succès, sinon message.
  Future<String?> checkout() async {
    final ids = cart.map((p) => p.id).toList();
    if (ids.isEmpty) return 'Panier vide.';
    String jwt;
    try {
      jwt = (await AppwriteClient.account.createJWT()).jwt;
    } on AppwriteException {
      return 'Connecte-toi pour acheter.';
    }
    http.Response r;
    try {
      r = await http
          .post(Uri.parse(onbuchBuyPackUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'jwt': jwt, 'subjectIds': ids}))
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      return 'Connexion impossible. Réessaie.';
    }
    Map<String, dynamic> m;
    try {
      m = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return 'Réponse inattendue. Réessaie.';
    }
    if (m['ok'] == true) {
      _owned.addAll((m['owned'] as List?)?.map((e) => e.toString()) ?? const []);
      _cart.clear();
      credits = (m['newBalance'] as num?)?.toInt() ?? credits;
      notifyListeners();
      return null;
    }
    return (m['error'] ?? 'Achat impossible.').toString();
  }
}
