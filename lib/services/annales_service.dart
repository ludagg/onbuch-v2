import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/annale.dart';
import '../models/annales_filter.dart';
import '../models/facets.dart';

/// Accès à la bibliothèque d'annales servie par l'API NextJS `ol`.
///
/// Tout est en lecture seule et tolérant aux pannes : en cas d'erreur réseau
/// ou serveur, on renvoie une valeur de repli vide pour que l'UI reste stable.
class AnnalesService {
  AnnalesService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? onbuchApiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query == null || query.isEmpty ? null : query);

  /// Liste paginée de documents selon un [filter].
  Future<AnnalePage> fetchDocuments(
    AnnalesFilter filter, {
    int page = 1,
    int limit = 20,
  }) async {
    final params = filter.toParams()
      ..['page'] = '$page'
      ..['limit'] = '$limit';
    try {
      final res = await _client.get(_uri('/api/documents', params)).timeout(_timeout);
      if (res.statusCode != 200) return AnnalePage.empty;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return AnnalePage.fromJson(body);
    } catch (_) {
      return AnnalePage.empty;
    }
  }

  /// Facettes (compteurs par dimension) pour le sous-ensemble décrit par [filter].
  Future<FacetSet> fetchFacets([AnnalesFilter filter = const AnnalesFilter()]) async {
    try {
      final res = await _client.get(_uri('/api/facets', filter.toParams())).timeout(_timeout);
      if (res.statusCode != 200) return FacetSet.empty;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return FacetSet.fromJson(body);
    } catch (_) {
      return FacetSet.empty;
    }
  }

  void dispose() => _client.close();
}
