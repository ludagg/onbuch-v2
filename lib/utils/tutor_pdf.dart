import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../theme/app_theme.dart';
import '../widgets/rich_answer.dart';

/// Un tour de la conversation à exporter (question élève ou réponse du Tuteur).
class PdfTurn {
  final bool isUser;
  final String text;
  final Uint8List? image;
  const PdfTurn({required this.isUser, this.text = '', this.image});
}

// Palette OnBuch (PDF).
const _orange = PdfColor.fromInt(0xFFF59321);
const _o700 = PdfColor.fromInt(0xFFA85607);
const _o50 = PdfColor.fromInt(0xFFFFF6E8);
const _ink = PdfColor.fromInt(0xFF1C1714);
const _ink2 = PdfColor.fromInt(0xFF5B5048);
const _muted = PdfColor.fromInt(0xFF978B80);
const _line = PdfColor.fromInt(0xFFE4DACE);

// Largeur logique de rendu (px logiques) du contenu à rasteriser.
const double _renderWidth = 470;
const double _pixelRatio = 3.0;

// ─── Fiche de révision (document dédié) ───────────────────────────────────────

/// Exporte une **fiche de révision** en PDF de marque : couverture (Léo + titre),
/// puis le contenu **rendu fidèlement** (LaTeX compilé, tableaux, graphiques),
/// avec un nom de fichier lié au sujet. Puis ouvre le partage / téléchargement.
Future<void> exportFichePdf({
  required String content,
  String? subject,
  String? title,
  BuildContext? context,
}) async {
  final heading = (title != null && title.trim().isNotEmpty)
      ? title.trim()
      : (subject != null && subject.trim().isNotEmpty ? 'Fiche · ${subject.trim()}' : 'Fiche de révision');

  await _composeAndShare(
    docKind: 'Fiche de révision',
    coverTitle: heading,
    coverSubtitle: subject,
    contentWidget: RichAnswer(content),
    fileName: _fileName('Fiche', subject ?? title ?? 'revision'),
    leoAsset: 'assets/images/leo_celebrate.png',
    context: context,
  );
}

// ─── Conversation Tuteur ──────────────────────────────────────────────────────

/// Exporte toute la conversation (énoncés + corrections) en PDF de marque, avec
/// le contenu **rendu fidèlement** (LaTeX compilé inclus).
Future<void> exportConversationPdf({
  required List<PdfTurn> turns,
  String? title,
  BuildContext? context,
}) async {
  await _composeAndShare(
    docKind: 'Tuteur IA — correction',
    coverTitle: (title != null && title.trim().isNotEmpty) ? title.trim() : 'Correction du Tuteur',
    coverSubtitle: null,
    contentWidget: _ConversationView(turns),
    fileName: _fileName('OnBuch_Tuteur', title ?? 'correction'),
    leoAsset: 'assets/images/leo_thinking.png',
    context: context,
  );
}

// ─── Pipeline commun : rasteriser → découper en pages → PDF de marque ─────────

Future<void> _composeAndShare({
  required String docKind,
  required String coverTitle,
  String? coverSubtitle,
  required Widget contentWidget,
  required String fileName,
  required String leoAsset,
  BuildContext? context,
}) async {
  final date = DateFormat('d MMMM y', 'fr_FR').format(DateTime.now());

  // 1) Rasterise le contenu (rendu app = LaTeX compilé, graphiques, tableaux).
  final shot = await _rasterize(contentWidget, context: context);

  // 2) Léo pour la couverture.
  Uint8List? leo;
  try {
    leo = (await rootBundle.load(leoAsset)).buffer.asUint8List();
  } catch (_) {
    leo = null;
  }

  final doc = pw.Document();
  const pageFormat = PdfPageFormat.a4;
  const mL = 36.0, mR = 36.0, mT = 40.0, mB = 30.0;
  final contentW = pageFormat.width - mL - mR;
  final contentH = pageFormat.height - mT - mB - 16; // -16 pour le pied de page

  // Découpe l'image en bandes de la hauteur d'une page.
  final strips = <Uint8List>[];
  if (shot != null) {
    var full = img.decodePng(shot);
    if (full != null) {
      full = _trimBottom(full);
      final pxPerPt = full.width / contentW;
      final stripPx = (contentH * pxPerPt).floor().clamp(1, full.height);
      for (var y = 0; y < full.height; y += stripPx) {
        final h = (y + stripPx <= full.height) ? stripPx : full.height - y;
        if (h <= 2) break;
        final strip = img.copyCrop(full, x: 0, y: y, width: full.width, height: h);
        strips.add(Uint8List.fromList(img.encodePng(strip)));
      }
    }
  }

  final totalPages = 1 + (strips.isEmpty ? 1 : strips.length);
  var pageNo = 0;

  pw.Widget footer() {
    pageNo++;
    final n = pageNo;
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text('OnBuch · $n / $totalPages',
          style: const pw.TextStyle(fontSize: 8, color: _muted)),
    );
  }

  // Page 1 : couverture de marque.
  doc.addPage(pw.Page(
    pageFormat: pageFormat,
    margin: const pw.EdgeInsets.fromLTRB(mL, mT, mR, mB),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Container(
          width: 26, height: 26,
          decoration: pw.BoxDecoration(color: _orange, borderRadius: pw.BorderRadius.circular(8)),
          alignment: pw.Alignment.center,
          child: pw.Text('OB', style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(width: 9),
        pw.Text('OnBuch', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.Spacer(),
        pw.Text(date, style: const pw.TextStyle(fontSize: 10, color: _ink2)),
      ]),
      pw.SizedBox(height: 6),
      pw.Container(height: 2.5, width: 52, color: _orange),
      pw.Spacer(),
      if (leo != null)
        pw.Center(child: pw.Image(pw.MemoryImage(leo), width: 150, height: 150)),
      pw.SizedBox(height: 18),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: pw.BoxDecoration(color: _o50, borderRadius: pw.BorderRadius.circular(20)),
        child: pw.Text(docKind.toUpperCase(),
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _o700, letterSpacing: 0.6)),
      ),
      pw.SizedBox(height: 12),
      pw.Text(coverTitle, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: _ink)),
      if (coverSubtitle != null && coverSubtitle.trim().isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Text(coverSubtitle.trim(), style: const pw.TextStyle(fontSize: 13, color: _ink2)),
      ],
      pw.SizedBox(height: 10),
      pw.Text('Généré par Léo, ton Tuteur OnBuch.',
          style: const pw.TextStyle(fontSize: 11, color: _muted)),
      pw.Spacer(),
      footer(),
    ]),
  ));

  // Pages de contenu (bandes rasterisées).
  if (strips.isEmpty) {
    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(mL, mT, mR, mB),
      build: (_) => pw.Column(children: [
        pw.Expanded(child: pw.Center(child: pw.Text('Contenu indisponible.', style: const pw.TextStyle(color: _muted)))),
        footer(),
      ]),
    ));
  } else {
    for (final strip in strips) {
      doc.addPage(pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(mL, mT, mR, mB),
        build: (_) => pw.Column(children: [
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.Image(pw.MemoryImage(strip), width: contentW),
            ),
          ),
          pw.Container(height: 1, color: _line),
          footer(),
        ]),
      ));
    }
  }

  await Printing.sharePdf(bytes: await doc.save(), filename: fileName);
}

/// Retire la bande blanche en bas de la capture (espace vide sous le contenu).
img.Image _trimBottom(img.Image im) {
  final step = (im.width ~/ 24).clamp(1, im.width);
  var lastContent = 0;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x += step) {
      final p = im.getPixel(x, y);
      if (p.r < 248 || p.g < 248 || p.b < 248) {
        lastContent = y;
        break;
      }
    }
  }
  final h = (lastContent + 14).clamp(1, im.height);
  if (h >= im.height) return im;
  return img.copyCrop(im, x: 0, y: 0, width: im.width, height: h);
}

/// Rasterise un widget de l'app (rendu fidèle, LaTeX compilé) en PNG.
Future<Uint8List?> _rasterize(Widget content, {BuildContext? context}) async {
  final controller = ScreenshotController();
  try {
    return await controller.captureFromWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: _renderWidth,
            color: Colors.white,
            padding: const EdgeInsets.all(18),
            child: content,
          ),
        ),
      ),
      pixelRatio: _pixelRatio,
      delay: const Duration(milliseconds: 180),
      context: context,
      targetSize: const Size(_renderWidth, 6000),
    );
  } catch (_) {
    return null;
  }
}

// Vue « conversation » rendue pour le PDF (énoncés + réponses de Léo).
class _ConversationView extends StatelessWidget {
  final List<PdfTurn> turns;
  const _ConversationView(this.turns);

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final t in turns) {
      if (t.isUser) {
        items.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCE9C7), width: 1.2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TA QUESTION', style: body(8.5, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 0.6)),
            if (t.image != null) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.memory(t.image!, fit: BoxFit.contain)),
            ],
            if (t.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(t.text.trim(), style: body(12.5, color: OC.ink, weight: FontWeight.w600)),
            ],
          ]),
        ));
      } else if (t.text.trim().isNotEmpty) {
        items.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Léo · Tuteur OnBuch', style: body(10.5, weight: FontWeight.w800, color: OC.o700)),
            ]),
            const SizedBox(height: 7),
            RichAnswer(t.text.trim()),
          ]),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: items);
  }
}

// Nom de fichier propre, lié au sujet demandé.
String _fileName(String prefix, String raw) {
  var s = raw.toLowerCase().trim();
  const map = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'û': 'u', 'ù': 'u', 'ü': 'u', 'ç': 'c',
  };
  map.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  s = s.replaceAll(RegExp(r'^_|_$'), '');
  if (s.length > 40) s = s.substring(0, 40);
  if (s.isEmpty) s = 'document';
  return '${prefix}_$s.pdf';
}
