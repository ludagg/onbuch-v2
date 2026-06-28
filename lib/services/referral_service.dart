import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../appwrite_config.dart';
import 'appwrite_client.dart';

/// Stats de parrainage de l'élève (vue « Parrainage »).
@immutable
class ReferralStats {
  final String code; // mon code à partager
  final int total; // nb de filleuls (tous statuts)
  final int rewarded; // filleuls ayant atteint le palier (parrain crédité)
  final int pending; // filleuls pas encore au palier
  final int creditsEarned; // crédits gagnés grâce au parrainage
  const ReferralStats({
    this.code = '',
    this.total = 0,
    this.rewarded = 0,
    this.pending = 0,
    this.creditsEarned = 0,
  });
}

/// Parrainage : récupère/réclame un code et lit les stats. Toute la logique de
/// récompense (crédits) est côté serveur (`api/referral.js`), authentifiée par
/// le JWT de l'élève — l'app ne fait qu'appeler l'endpoint.
class ReferralService {
  ReferralService._();
  static final ReferralService instance = ReferralService._();

  Future<String?> _jwt() async {
    try {
      return (await AppwriteClient.account.createJWT()).jwt;
    } on AppwriteException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(Map<String, dynamic> body) async {
    final jwt = await _jwt();
    if (jwt == null) return null;
    try {
      final r = await http
          .post(Uri.parse(referralApiUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({...body, 'jwt': jwt}))
          .timeout(const Duration(seconds: 20));
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Mon code de parrainage (créé côté serveur si absent). `null` si hors-ligne.
  Future<String?> myCode() async {
    final m = await _post({'action': 'code'});
    return (m != null && m['ok'] == true) ? m['code']?.toString() : null;
  }

  /// Le filleul saisit le code de son parrain. Renvoie `null` si succès, sinon
  /// un message d'erreur lisible.
  Future<String?> claim(String code) async {
    final c = code.trim();
    if (c.isEmpty) return 'Entre un code de parrainage.';
    final m = await _post({'action': 'claim', 'code': c});
    if (m == null) return 'Connexion impossible. Réessaie.';
    if (m['ok'] == true) return null;
    return (m['error'] ?? 'Parrainage impossible.').toString();
  }

  /// Tente de créditer le parrain si le filleul a atteint le palier. Best-effort,
  /// silencieux — à appeler au démarrage / après un gain de XP.
  Future<void> settle() async {
    await _post({'action': 'settle'});
  }

  /// Stats de parrain (code + filleuls + crédits gagnés).
  Future<ReferralStats> stats() async {
    final m = await _post({'action': 'stats'});
    if (m == null || m['ok'] != true) return const ReferralStats();
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return ReferralStats(
      code: m['code']?.toString() ?? '',
      total: n(m['total']),
      rewarded: n(m['rewarded']),
      pending: n(m['pending']),
      creditsEarned: n(m['creditsEarned']),
    );
  }
}
