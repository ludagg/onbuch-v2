import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/annale.dart';
import '../../theme/app_theme.dart';
import '../../utils/launch.dart';
import '../../services/annale_download_stub.dart'
    if (dart.library.io) '../../services/annale_download_io.dart' as dl;

/// Lecteur PDF intégré (Syncfusion). Charge un fichier local téléchargé
/// (hors-ligne) ou un lien réseau (Appwrite Storage / externe).
class PdfReaderScreen extends StatefulWidget {
  final PdfArgs? args;
  const PdfReaderScreen({super.key, this.args});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  int _page = 1;
  int _total = 0;

  Uint8List? _localBytes;
  bool _loadingLocal = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ));
    final path = widget.args?.localPath;
    if (path != null && path.isNotEmpty) {
      _loadingLocal = true;
      dl.readLocalBytes(path).then((b) {
        if (!mounted) return;
        setState(() {
          _localBytes = b;
          _loadingLocal = false;
        });
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    _controller.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/annales');

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final url = args?.url;
    final title = args?.title ?? 'Document';
    final subtitle = (args?.subtitle ?? '').isEmpty ? 'Annale · PDF' : args!.subtitle;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      body: SafeArea(
        child: Column(children: [
          // Barre supérieure
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              _DarkBtn(Icons.arrow_back_ios_new_rounded, _back),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(14, weight: FontWeight.w700, color: Colors.white)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(11, color: Colors.white.withValues(alpha: 0.55))),
              ])),
              if (url != null && url.isNotEmpty) ...[
                _DarkBtn(Icons.open_in_new_rounded, () => openUrl(context, url)),
                const SizedBox(width: 8),
                _DarkBtn(Icons.share_outlined, () => shareArticle(context, title, url: url)),
              ],
            ]),
          ),
          // Contenu
          Expanded(child: _viewer(args, url)),
          // Pagination
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _DarkBtn(Icons.chevron_left_rounded, () => _controller.previousPage()),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$_page / $_total',
                      style: mono(13, weight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                _DarkBtn(Icons.chevron_right_rounded, () => _controller.nextPage()),
              ]),
            ),
        ]),
      ),
    );
  }

  void _onChanged(PdfPageChangedDetails d) {
    if (!mounted) return;
    setState(() => _page = d.newPageNumber);
  }

  void _onLoaded(PdfDocumentLoadedDetails d) {
    if (!mounted) return;
    setState(() => _total = d.document.pages.count);
  }

  Widget _viewer(PdfArgs? args, String? url) {
    // Fichier local (hors-ligne) prioritaire.
    if ((args?.localPath ?? '').isNotEmpty) {
      if (_loadingLocal) return const _Loading();
      if (_localBytes != null) {
        return SfPdfViewer.memory(
          _localBytes!,
          controller: _controller,
          onPageChanged: _onChanged,
          onDocumentLoaded: _onLoaded,
        );
      }
      // Fichier illisible → on tente le réseau si dispo.
    }

    if (url != null && url.isNotEmpty) {
      return SfPdfViewer.network(
        url,
        controller: _controller,
        onPageChanged: _onChanged,
        onDocumentLoaded: _onLoaded,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text('Document indisponible.',
            textAlign: TextAlign.center,
            style: body(14, color: Colors.white.withValues(alpha: 0.7))),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Colors.white));
}

class _DarkBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DarkBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}
