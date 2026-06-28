import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;
import '../appwrite_config.dart';
import 'appwrite_client.dart';

/// Assistant d'orientation « Léo Orientation » — DÉDIÉ et SÉPARÉ du tuteur.
/// Appelle l'endpoint serveur (clé NVIDIA côté serveur) en streaming : la
/// réponse arrive token par token via [onDelta].
class OrientationAssistantService {
  OrientationAssistantService._();
  static final OrientationAssistantService instance = OrientationAssistantService._();

  // Petit cache de JWT (valable ~15 min côté Appwrite ; on garde une marge).
  String? _jwt;
  DateTime? _jwtAt;

  Future<String?> _getJwt() async {
    final now = DateTime.now();
    if (_jwt != null && _jwtAt != null && now.difference(_jwtAt!).inMinutes < 12) {
      return _jwt;
    }
    try {
      _jwt = (await AppwriteClient.account.createJWT()).jwt;
      _jwtAt = now;
      return _jwt;
    } on AppwriteException {
      return null;
    }
  }

  /// Envoie la conversation et reçoit la réponse en flux. [messages] = liste de
  /// {role: 'user'|'assistant', content}. [profile] = infos élève (facultatif).
  /// Lève une exception en cas d'erreur réseau/serveur.
  Future<void> ask({
    required List<Map<String, String>> messages,
    Map<String, dynamic>? profile,
    required void Function(String delta) onDelta,
  }) async {
    final jwt = await _getJwt();
    if (jwt == null) throw 'Connecte-toi pour utiliser l\'assistant.';

    final req = http.Request('POST', Uri.parse(orientationApiUrl))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'jwt': jwt,
        'messages': messages,
        if (profile != null && profile.isNotEmpty) 'profile': profile,
      });

    final resp = await http.Client().send(req).timeout(const Duration(seconds: 45));
    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      String msg = 'Assistant indisponible. Réessaie.';
      try {
        final m = jsonDecode(body);
        if (m is Map && m['error'] != null) msg = m['error'].toString();
      } catch (_) {}
      throw msg;
    }
    await for (final chunk in resp.stream.transform(utf8.decoder)) {
      if (chunk.isNotEmpty) onDelta(chunk);
    }
  }
}
