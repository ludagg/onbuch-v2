import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;
import 'appwrite_client.dart';
import '../appwrite_config.dart';

/// Rachat d'un **code crédits** (émis par le bot Telegram après validation d'un
/// paiement Mobile Money). L'app envoie un JWT Appwrite court + le code à
/// l'endpoint serveur (`onbuchRedeemUrl`), qui vérifie le JWT, contrôle le code
/// et crédite `tutor_quota`. L'app ne crédite jamais elle-même.
class CreditsService {
  /// Retourne le nombre de crédits ajoutés. Lève une `String` lisible si échec.
  static Future<int> redeemCode(String code) async {
    final c = code.trim().toUpperCase();
    if (c.length < 4) throw 'Code invalide.';

    String jwt;
    try {
      final t = await AppwriteClient.account.createJWT();
      jwt = t.jwt;
    } on AppwriteException {
      throw 'Connecte-toi pour utiliser un code.';
    }

    http.Response r;
    try {
      r = await http
          .post(Uri.parse(onbuchRedeemUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'code': c, 'jwt': jwt}))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw 'Connexion impossible. Vérifie ta connexion et réessaie.';
    }

    Map<String, dynamic> m;
    try {
      m = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw 'Réponse inattendue. Réessaie.';
    }
    if (m['ok'] == true) return (m['credits'] as num?)?.toInt() ?? 0;
    throw (m['error'] ?? 'Code refusé.').toString();
  }
}
