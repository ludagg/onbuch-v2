import 'package:app_links/app_links.dart';
import '../router/app_router.dart';

/// Écoute les liens entrants (deep links / liens de partage) et ouvre la fiche
/// du document correspondant :
///   - schéma app  : `onbuch://annale/{id}`
///   - lien web    : `https://onbuch-go.vercel.app/a/{id}`
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {}
    _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final id = _extractId(uri);
    if (id != null && id.isNotEmpty) {
      appRouter.push('/annales/open/$id');
    }
  }

  String? _extractId(Uri uri) {
    // onbuch://annale/{id}
    if (uri.scheme == 'onbuch' && uri.host == 'annale' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    // …/a/{id}
    final segs = uri.pathSegments;
    final i = segs.indexOf('a');
    if (i >= 0 && i + 1 < segs.length) return segs[i + 1];
    return null;
  }
}
