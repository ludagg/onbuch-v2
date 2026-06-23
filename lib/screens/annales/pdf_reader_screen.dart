import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_theme.dart';
import '../../services/offline_cache.dart';

/// Lecteur PDF intégré (sujet / corrigé / cours / fiche). Affiche un PDF mis en
/// cache hors-ligne (si dispo) sinon distant via [SfPdfViewer]. Le lien, les
/// libellés et l'id (pour le cache offline) arrivent par `extra`.
class PdfReaderScreen extends StatefulWidget {
  final String url;
  final String? title;
  final String? subtitle;
  final String? offlineId;
  const PdfReaderScreen({super.key, required this.url, this.title, this.subtitle, this.offlineId});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? _error;
  Uint8List? _offlineBytes;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light));
    _checkOffline();
  }

  Future<void> _checkOffline() async {
    Uint8List? bytes;
    if (widget.offlineId != null && widget.offlineId!.isNotEmpty) {
      bytes = await OfflineCache.readBytes(widget.offlineId!);
    }
    if (mounted) setState(() { _offlineBytes = bytes; _checking = false; });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.url.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              _DarkBtn(Icons.arrow_back_ios_new_rounded, () => context.canPop() ? context.pop() : context.go('/annales')),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title ?? 'Document', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(14, weight: FontWeight.w700, color: Colors.white)),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                  Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: body(11, color: Colors.white.withValues(alpha: 0.55))),
              ])),
              const SizedBox(width: 38),
            ]),
          ),
          Expanded(
            child: _checking
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _offlineBytes != null
                    ? SfPdfViewer.memory(_offlineBytes!)
                    : !hasUrl
                        ? _msg('Document indisponible.')
                        : _error != null
                            ? _msg(_error!)
                            : SfPdfViewer.network(
                                widget.url,
                                onDocumentLoadFailed: (details) {
                                  if (mounted) setState(() => _error = 'Impossible d\'ouvrir ce PDF.');
                                },
                              ),
          ),
        ]),
      ),
    );
  }

  Widget _msg(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.picture_as_pdf_rounded, size: 46, color: Color(0x55FFFFFF)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: body(14, color: Colors.white.withValues(alpha: 0.8))),
          ]),
        ),
      );
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}
