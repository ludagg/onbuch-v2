import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../appwrite_config.dart';
import 'appwrite_client.dart';
import 'local_notifications_service.dart';
import 'leaderboard_service.dart';
import 'auth_service.dart';

/// État de progression (gamification) de l'élève.
class GamificationState {
  final int xp;
  final int streak;
  final int bestStreak;
  final String lastActive; // YYYY-MM-DD
  final int quizzes;
  final int tutorUses;
  final Set<String> badges;

  const GamificationState({
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastActive = '',
    this.quizzes = 0,
    this.tutorUses = 0,
    this.badges = const {},
  });

  GamificationState copyWith({int? xp, int? streak, int? bestStreak, String? lastActive, int? quizzes, int? tutorUses, Set<String>? badges}) =>
      GamificationState(
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastActive: lastActive ?? this.lastActive,
        quizzes: quizzes ?? this.quizzes,
        tutorUses: tutorUses ?? this.tutorUses,
        badges: badges ?? this.badges,
      );

  // ── Niveaux ──────────────────────────────────────────────────────────────
  // XP cumulé pour atteindre le niveau L : 50·(L-1)·L (1→0, 2→100, 3→300, 4→600…)
  int get level {
    var l = 1;
    while (50 * l * (l + 1) <= xp) {
      l++;
    }
    return l;
  }

  int get _floor => 50 * (level - 1) * level;
  int get _ceil => 50 * level * (level + 1);
  int get xpInLevel => xp - _floor;
  int get xpForLevel => _ceil - _floor;
  double get levelProgress => xpForLevel == 0 ? 0 : (xpInLevel / xpForLevel).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'xp': xp, 'streak': streak, 'bestStreak': bestStreak, 'lastActive': lastActive,
        'quizzes': quizzes, 'tutorUses': tutorUses, 'badges': badges.join(','),
      };

  factory GamificationState.fromMap(Map<String, dynamic> d) => GamificationState(
        xp: (d['xp'] as num?)?.toInt() ?? 0,
        streak: (d['streak'] as num?)?.toInt() ?? 0,
        bestStreak: (d['bestStreak'] as num?)?.toInt() ?? 0,
        lastActive: (d['lastActive'] ?? '').toString(),
        quizzes: (d['quizzes'] as num?)?.toInt() ?? 0,
        tutorUses: (d['tutorUses'] as num?)?.toInt() ?? 0,
        badges: (d['badges'] ?? '').toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet(),
      );
}

/// Définition d'un badge (débloqué selon l'état).
class GameBadge {
  final String id;
  final IconData icon;
  final String label;
  final String desc;
  final bool Function(GamificationState s) earned;
  const GameBadge(this.id, this.icon, this.label, this.desc, this.earned);
}

const List<GameBadge> kBadges = [
  GameBadge('first_quiz', Icons.track_changes_rounded, 'Premier quiz', 'Termine ton premier quiz', _bFirstQuiz),
  GameBadge('quiz_10', Icons.psychology_rounded, 'Studieux', 'Termine 10 quiz', _bQuiz10),
  GameBadge('streak_3', Icons.local_fire_department_rounded, 'En forme', '3 jours d\'affilée', _bStreak3),
  GameBadge('streak_7', Icons.bolt_rounded, 'Régulier', '7 jours d\'affilée', _bStreak7),
  GameBadge('streak_30', Icons.emoji_events_rounded, 'Inarrêtable', '30 jours d\'affilée', _bStreak30),
  GameBadge('tutor_5', Icons.forum_rounded, 'Curieux', 'Pose 5 questions à Léo', _bTutor5),
  GameBadge('xp_500', Icons.star_rounded, 'Monte en puissance', 'Atteins 500 XP', _bXp500),
  GameBadge('xp_2000', Icons.diamond_rounded, 'Élite', 'Atteins 2000 XP', _bXp2000),
];

bool _bFirstQuiz(GamificationState s) => s.quizzes >= 1;
bool _bQuiz10(GamificationState s) => s.quizzes >= 10;
bool _bStreak3(GamificationState s) => s.bestStreak >= 3;
bool _bStreak7(GamificationState s) => s.bestStreak >= 7;
bool _bStreak30(GamificationState s) => s.bestStreak >= 30;
bool _bTutor5(GamificationState s) => s.tutorUses >= 5;
bool _bXp500(GamificationState s) => s.xp >= 500;
bool _bXp2000(GamificationState s) => s.xp >= 2000;

/// Service de gamification : streak quotidien, XP, niveaux, badges.
/// Source : doc Appwrite `gamification/{uid}` (par utilisateur) + cache disque
/// (`shared_preferences`) pour l'affichage instantané et le hors-ligne.
class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  static const _prefsKey = 'gamification_v1';
  static const _dailyKey = 'gamification_daily_v1';

  final ValueNotifier<GamificationState> state = ValueNotifier(const GamificationState());
  // Historique local du XP gagné par jour ('YYYY-MM-DD' → xp). Sert au graphe
  // d'activité et au cumul hebdomadaire (leaderboard). ~3 semaines conservées.
  final Map<String, int> _dailyXp = {};
  String? _uid;
  bool _loaded = false;

  String _today() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  String _yesterday() {
    final n = DateTime.now().subtract(const Duration(days: 1));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  /// Charge l'état (cache disque puis serveur). Idempotent.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    // Cache disque d'abord (instantané, offline).
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        state.value = GamificationState.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      }
      final rawDaily = p.getString(_dailyKey);
      if (rawDaily != null && rawDaily.isNotEmpty) {
        final m = jsonDecode(rawDaily) as Map<String, dynamic>;
        _dailyXp
          ..clear()
          ..addAll(m.map((k, v) => MapEntry(k, (v as num).toInt())));
      }
    } catch (_) {}
    // Serveur (autorité si dispo).
    try {
      final user = await AppwriteClient.account.get();
      _uid = user.$id;
      try {
        final doc = await AppwriteClient.databases.getDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteGamificationCollectionId,
          documentId: _uid!,
        );
        state.value = GamificationState.fromMap(doc.data);
        await _saveLocal();
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _persist(); // crée le doc serveur à partir de l'état courant
        }
      }
    } catch (_) {/* hors-ligne / non connecté → cache local */}
  }

  Future<void> _saveLocal() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsKey, jsonEncode(state.value.toMap()));
    } catch (_) {}
  }

  Future<void> _persist() async {
    await _saveLocal();
    final uid = _uid;
    if (uid == null) return;
    final data = {...state.value.toMap(), 'updatedAt': DateTime.now().toIso8601String()};
    try {
      await AppwriteClient.databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteGamificationCollectionId,
        documentId: uid,
        data: data,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await AppwriteClient.databases.createDocument(
            databaseId: appwriteDatabaseId,
            collectionId: appwriteGamificationCollectionId,
            documentId: uid,
            data: data,
            permissions: [
              Permission.read(Role.user(uid)),
              Permission.update(Role.user(uid)),
              Permission.delete(Role.user(uid)),
            ],
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Incrémente le XP du jour (historique local) + élague au-delà de 21 jours.
  Future<void> _bumpDaily(int amount) async {
    if (amount <= 0) return;
    final today = _today();
    _dailyXp[today] = (_dailyXp[today] ?? 0) + amount;
    // Élagage : ne garder que les 21 derniers jours.
    if (_dailyXp.length > 21) {
      final keys = _dailyXp.keys.toList()..sort();
      for (final k in keys.take(_dailyXp.length - 21)) {
        _dailyXp.remove(k);
      }
    }
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_dailyKey, jsonEncode(_dailyXp));
    } catch (_) {}
  }

  String _dayKey(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// XP gagné chaque jour sur les [days] derniers jours (du plus ancien à
  /// aujourd'hui). Pour le graphe d'activité.
  List<int> dailyXpSeries({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      return _dailyXp[_dayKey(d)] ?? 0;
    });
  }

  /// XP cumulé de la semaine en cours (lundi → aujourd'hui). Pour le leaderboard.
  int weeklyXp() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    var total = 0;
    _dailyXp.forEach((k, v) {
      final parts = k.split('-');
      if (parts.length != 3) return;
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (!d.isBefore(monday) && !d.isAfter(today)) total += v;
    });
    return total;
  }

  Set<String> _withNewBadges(GamificationState s) {
    final b = {...s.badges};
    for (final badge in kBadges) {
      if (badge.earned(s)) b.add(badge.id);
    }
    return b;
  }

  /// À l'ouverture de l'app : met à jour le streak (1×/jour) + bonus quotidien.
  Future<void> recordActivity() async {
    await load();
    final s = state.value;
    final today = _today();
    if (s.lastActive == today) return; // déjà compté aujourd'hui
    final newStreak = s.lastActive == _yesterday() ? s.streak + 1 : 1;
    var next = s.copyWith(
      streak: newStreak,
      bestStreak: newStreak > s.bestStreak ? newStreak : s.bestStreak,
      lastActive: today,
      xp: s.xp + 10, // bonus de connexion quotidienne
    );
    next = next.copyWith(badges: _withNewBadges(next));
    await _bumpDaily(10); // bonus quotidien dans l'historique
    state.value = next;
    await _persist();
    // L'élève est venu aujourd'hui → on annule le rappel du jour et on
    // reprogramme les suivants à partir du nouvel état de la série.
    LocalNotificationsService.instance
        .reschedule(streak: next.streak, lastActive: next.lastActive);
    // Publie l'entrée de classement de la semaine (best-effort).
    final uid = _uid;
    if (uid != null) {
      LeaderboardService.instance.submit(
        uid: uid,
        name: AuthService.cachedFullName ?? 'Élève',
        level: next.level,
        xp: next.xp,
        weeklyXp: weeklyXp(),
      );
    }
  }

  /// Ajoute de l'XP (+ incréments éventuels), recalcule les badges.
  Future<void> addXp(int amount, {int quizzes = 0, int tutorUses = 0}) async {
    await load();
    final s = state.value;
    var next = s.copyWith(
      xp: s.xp + amount,
      quizzes: s.quizzes + quizzes,
      tutorUses: s.tutorUses + tutorUses,
    );
    next = next.copyWith(badges: _withNewBadges(next));
    await _bumpDaily(amount);
    state.value = next;
    await _persist();
  }
}
