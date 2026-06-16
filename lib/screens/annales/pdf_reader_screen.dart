import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// Arguments passés au lecteur PDF via `context.push('/annales/pdf', extra: …)`.
class PdfArgs {
  final String url;
  final String title;
  final String subtitle;
  const PdfArgs({required this.url, required this.title, this.subtitle = ''});
}

/// Lecteur PDF plein écran qui charge le document distant servi par `ol`.
class PdfReaderScreen extends StatefulWidget {
  final PdfArgs args;
  const PdfReaderScreen({super.key, required this.args});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  bool _failed = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light));
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark));
    super.dispose();
  }

  Future<void> _openExternally() async {
    await launchUrl(Uri.parse(widget.args.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      body: SafeArea(
        child: Column(children: [
          // Barre supérieure
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              _DarkBtn(Icons.arrow_back_ios_new_rounded, () => context.pop()),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: body(14, weight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (a.subtitle.isNotEmpty)
                    Text(a.subtitle, style: body(11, color: Colors.white.withValues(alpha: 0.55)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              _DarkBtn(Icons.download_outlined, _openExternally),
              const SizedBox(width: 8),
              _DarkBtn(Icons.open_in_new_rounded, _openExternally),
            ]),
          ),
          // Contenu
          Expanded(
            child: _failed
                ? _ErrorView(message: _error, onOpenExternally: _openExternally, onBack: () => context.pop())
                : SfPdfViewer.network(
                    a.url,
                    controller: _controller,
                    canShowScrollHead: true,
                    onDocumentLoadFailed: (details) {
                      if (!mounted) return;
                      setState(() {
                        _failed = true;
                        _error = details.description;
                      });
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onOpenExternally, onBack;
  const _ErrorView({required this.message, required this.onOpenExternally, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 46, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Text('Impossible d\'afficher le PDF', style: display(16, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(message.isEmpty ? 'Le document n\'a pas pu être chargé.' : message,
              textAlign: TextAlign.center, style: body(12.5, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w500)),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onOpenExternally,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
              child: Text('Ouvrir dans le navigateur', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onBack,
            child: Text('Retour', style: body(13, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
          ),
        ]),
      ),
    );
  }
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}
