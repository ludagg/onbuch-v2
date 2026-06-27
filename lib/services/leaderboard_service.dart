import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';
import 'appwrite_client.dart';

/// Une ligue (palier de classement, façon Duolingo). On y est rangé selon son
/// niveau ; on y est classé chaque semaine selon le XP gagné dans la semaine.
class League {
  final String name;
  final IconData icon;
  final Color color;
  final int minLevel;
  const League(this.name, this.icon, this.color, this.minLevel);
}

/// Ligues, du plus bas au plus haut palier.
const List<League> kLeagues = [
  League('Bronze', Icons.workspace_premium_rounded, Color(0xFFCD7F32), 1),
  League('Argent', Icons.workspace_premium_rounded, Color(0xFF9AA0A6), 3),
  League('Or', Icons.workspace_premium_rounded, Color(0xFFE3B341), 5),
  League('Saphir', Icons.shield_rounded, Color(0xFF2D6CDF), 8),
  League('Rubis', Icons.shield_rounded, Color(0xFFD2462E), 12),
  League('Diamant', Icons.diamond_rounded, Color(0xFF22B8CF), 17),
];

League leagueForLevel(int level) {
  var res = kLeagues.first;
  for (final l in kLeagues) {
    if (level >= l.minLevel) res = l;
  }
  return res;
}

League leagueByName(String name) =>
    kLeagues.firstWhere((l) => l.name == name, orElse: () => kLeagues.first);

/// Une entrée de classement.
class LeaderboardEntry {
  final String uid;
  final String name;
  final int level;
  final int weeklyXp;
  final int xp;
  int rank; // attribué après tri (1-based)

  LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.level,
    required this.weeklyXp,
    required this.xp,
    this.rank = 0,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> d) => LeaderboardEntry(
        uid: (d['uid'] ?? '').toString(),
        name: (d['name'] ?? 'Élève').toString(),
        level: (d['level'] as num?)?.toInt() ?? 1,
        weeklyXp: (d['weeklyXp'] as num?)?.toInt() ?? 0,
        xp: (d['xp'] as num?)?.toInt() ?? 0,
      );

  String get initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
  }
}

/// Classement / ligues. Chaque élève **publie** son entrée (lecture publique,
/// écriture propriétaire) ; le classement d'une ligue est lu par tous.
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  /// Identifiant de la semaine = date du lundi ('YYYY-MM-DD'). Le XP
  /// hebdomadaire repart de zéro chaque lundi.
  String currentWeekId() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${monday.year}-${two(monday.month)}-${two(monday.day)}';
  }

  /// Publie (ou met à jour) l'entrée de l'élève pour la semaine courante.
  Future<void> submit({
    required String uid,
    required String name,
    required int level,
    required int xp,
    required int weeklyXp,
  }) async {
    final data = {
      'uid': uid,
      'name': name,
      'level': level,
      'xp': xp,
      'weeklyXp': weeklyXp,
      'league': leagueForLevel(level).name,
      'weekId': currentWeekId(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    try {
      await AppwriteClient.databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteLeaderboardCollectionId,
        documentId: uid,
        data: data,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await AppwriteClient.databases.createDocument(
            databaseId: appwriteDatabaseId,
            collectionId: appwriteLeaderboardCollectionId,
            documentId: uid,
            data: data,
            permissions: [
              Permission.read(Role.any()),
              Permission.update(Role.user(uid)),
              Permission.delete(Role.user(uid)),
            ],
          );
        } catch (_) {}
      }
    } catch (_) {/* best-effort */}
  }

  /// Classement d'une ligue pour la semaine courante (meilleur XP hebdo d'abord).
  Future<List<LeaderboardEntry>> top({required String league, int limit = 50}) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteLeaderboardCollectionId,
        queries: [
          Query.equal('weekId', currentWeekId()),
          Query.equal('league', league),
          Query.orderDesc('weeklyXp'),
          Query.limit(limit),
        ],
      );
      final list = res.documents.map((d) => LeaderboardEntry.fromMap(d.data)).toList();
      for (var i = 0; i < list.length; i++) {
        list[i].rank = i + 1;
      }
      return list;
    } catch (_) {
      return const [];
    }
  }
}
