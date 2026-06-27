import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_theme.dart';
import '../../services/offline_cache.dart';
import '../../utils/launch.dart';

/// Lecteur PDF intégré (sujet / corrigé / cours / fiche). Affiche un PDF mis en
/// cache hors-ligne (si dispo) sinon distant via [SfPdfViewer].
///
/// Mode **aperçu** (`previewPages`) : ne charge **réellement que les N
/// premières pages** (rasterisées en images) — impossible d'aller plus loin —
/// puis affiche un encart d'achat/précommande à la fin.
class PdfReaderScreen extends StatefulWidget {
  final String url;
  final String? title;
  final String? subtitle;
  final String? offlineId;
  final int? previewPages; // null = document complet
  final String? orderUrl; // lien WhatsApp de précommande (mode aperçu)
  final String? orderLabel;
  const PdfReaderScreen({
    super.key,
    required this.url,
    this.title,
    this.subtitle,
    this.offlineId,
    this.previewPages,
    this.orderUrl,
    this.orderLabel,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? _error;
  Uint8List? _offlineBytes;
  bool _checking = true;

  // Mode aperçu : images des N premières pages.
  bool get _isPreview => (widget.previewPages ?? 0) > 0;
  List<Uint8List> _previewImages = const [];
  bool _previewLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light));
    if (_isPreview) {
      _loadPreview();
    } else {
      _checkOffline();
    }
  }

  Future<void> _checkOffline() async {
    Uint8List? bytes;
    if (widget.offlineId != null && widget.offlineId!.isNotEmpty) {
      bytes = await OfflineCache.readBytes(widget.offlineId!);
    }
    if (mounted) setState(() { _offlineBytes = bytes; _checking = false; });
  }

  /// Télécharge le PDF et rasterise UNIQUEMENT les N premières pages.
  Future<void> _loadPreview() async {
    setState(() { _previewLoading = true; _checking = false; });
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode != 200) throw 'http ${res.statusCode}';
      final n = widget.previewPages!;
      final pages = List<int>.generate(n, (i) => i);
      final imgs = <Uint8List>[];
      await for (final page in Printing.raster(res.bodyBytes, pages: pages, dpi: 120)) {
        imgs.add(await page.toPng());
        if (mounted) setState(() => _previewImages = List.of(imgs));
      }
      if (mounted) setState(() => _previewLoading = false);
    } catch (_) {
      if (mounted) setState(() { _error = 'Aperçu indisponible.'; _previewLoading = false; });
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              if (_isPreview)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(999)),
                  child: Text('APERÇU', style: body(10, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.5)),
                )
              else
                const SizedBox(width: 38),
            ]),
          ),
          Expanded(child: _isPreview ? _previewBody() : _fullBody()),
        ]),
      ),
    );
  }

  // ── Document complet ─────────────────────────────────────────────────────────
  Widget _fullBody() {
    final hasUrl = widget.url.trim().isNotEmpty;
    if (_checking) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_offlineBytes != null) return SfPdfViewer.memory(_offlineBytes!);
    if (!hasUrl) return _msg('Document indisponible.');
    if (_error != null) return _msg(_error!);
    return SfPdfViewer.network(
      widget.url,
      onDocumentLoadFailed: (details) {
        if (mounted) setState(() => _error = 'Impossible d\'ouvrir ce PDF.');
      },
    );
  }

  // ── Aperçu (N pages rasterisées + encart d'achat) ───────────────────────────
  Widget _previewBody() {
    if (_error != null) return _msg(_error!);
    if (_previewImages.isEmpty && _previewLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_previewImages.isEmpty) return _msg('Aperçu indisponible.');
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      children: [
        for (var i = 0; i < _previewImages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              // Fond BLANC obligatoire : les PDF (fascicules LaTeX) n'ont pas de
              // rectangle de page blanc → le PNG rastérisé a un fond transparent.
              // Sans ce blanc, la page apparaîtrait noire (sur le fond sombre du
              // lecteur) et le texte serait illisible. Un document = toujours blanc.
              child: Container(
                color: Colors.white,
                child: Image.memory(_previewImages[i], fit: BoxFit.fitWidth, width: double.infinity),
              ),
            ),
          ),
        if (_previewLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          )
        else
          _paywall(),
      ],
    );
  }

  Widget _paywall() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(children: [
        const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
        const SizedBox(height: 10),
        Text('Fin de l\'aperçu', style: display(17, weight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Achète ou précommande pour débloquer le fascicule complet (version papier ou numérique).',
            textAlign: TextAlign.center,
            style: body(12.5, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w500).copyWith(height: 1.45)),
        const SizedBox(height: 16),
        if (widget.orderUrl != null && widget.orderUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => openUrl(context, widget.orderUrl),
            child: Container(
              width: double.infinity, height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(14)),
              child: Text(widget.orderLabel ?? 'Précommander',
                  style: body(14.5, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
      ]),
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
