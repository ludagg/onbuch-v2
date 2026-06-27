import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_theme.dart';
import '../../services/offline_cache.dart';
import '../../utils/launch.dart';

/// Lecteur PDF intégré (sujet / corrigé / cours / fiche). Affiche un PDF mis en
/// cache hors-ligne (si dispo) sinon distant via [SfPdfViewer]. Le lien, les
/// libellés et l'id (pour le cache offline) arrivent par `extra`.
///
/// Mode **aperçu** (`previewPages`) : limite la lecture aux N premières pages
/// (fascicules) et affiche un encart d'achat/précommande à la fin de l'aperçu.
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
  final PdfViewerController _ctrl = PdfViewerController();
  int _page = 1;
  int _pageCount = 0;

  bool get _isPreview => (widget.previewPages ?? 0) > 0;

  /// Dernière page autorisée en aperçu (bornée au nombre réel de pages).
  int get _limit {
    final p = widget.previewPages ?? 0;
    if (_pageCount > 0) return p > _pageCount ? _pageCount : p;
    return p;
  }

  /// Aperçu terminé : l'élève a atteint la dernière page autorisée.
  bool get _previewEnded => _isPreview && _page >= _limit;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light));
    _checkOffline();
  }

  Future<void> _checkOffline() async {
    Uint8List? bytes;
    // En mode aperçu on ne sert jamais la version hors-ligne (document complet).
    if (!_isPreview && widget.offlineId != null && widget.offlineId!.isNotEmpty) {
      bytes = await OfflineCache.readBytes(widget.offlineId!);
    }
    if (mounted) setState(() { _offlineBytes = bytes; _checking = false; });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark));
    super.dispose();
  }

  void _onPageChanged(PdfPageChangedDetails d) {
    if (!_isPreview) {
      setState(() => _page = d.newPageNumber);
      return;
    }
    // Empêche d'aller au-delà de l'aperçu : on ramène à la dernière page permise.
    if (d.newPageNumber > _limit) {
      _ctrl.jumpToPage(_limit);
      setState(() => _page = _limit);
    } else {
      setState(() => _page = d.newPageNumber);
    }
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
          Expanded(
            child: _checking
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Stack(children: [
                    Positioned.fill(child: _viewer(hasUrl)),
                    if (_isPreview) Positioned(left: 0, right: 0, bottom: 0, child: _previewBar()),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _viewer(bool hasUrl) {
    if (_offlineBytes != null) return SfPdfViewer.memory(_offlineBytes!);
    if (!hasUrl) return _msg('Document indisponible.');
    if (_error != null) return _msg(_error!);
    return SfPdfViewer.network(
      widget.url,
      controller: _ctrl,
      canShowScrollHead: !_isPreview,
      canShowScrollStatus: !_isPreview,
      onPageChanged: _onPageChanged,
      onDocumentLoaded: (d) {
        if (mounted) setState(() => _pageCount = d.document.pages.count);
      },
      onDocumentLoadFailed: (details) {
        if (mounted) setState(() => _error = 'Impossible d\'ouvrir ce PDF.');
      },
    );
  }

  /// Barre d'aperçu : progression + encart d'achat quand l'aperçu est terminé.
  Widget _previewBar() {
    final ended = _previewEnded;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, const Color(0xFF1A1410).withValues(alpha: 0.96), const Color(0xFF1A1410)],
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!ended) ...[
          Text('Aperçu — page $_page/$_limit',
              style: body(12, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 8),
        ] else ...[
          Text('🔒 Fin de l\'aperçu',
              style: body(14, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Achète ou précommande pour avoir la version complète (papier ou numérique).',
              textAlign: TextAlign.center,
              style: body(12.5, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 12),
        ],
        if (widget.orderUrl != null && widget.orderUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => openUrl(context, widget.orderUrl),
            child: Container(
              width: double.infinity, height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ended ? const Color(0xFF25D366) : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
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
