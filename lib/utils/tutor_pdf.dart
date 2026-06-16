import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Génère et partage/enregistre un PDF de la correction (énoncé + correction),
/// à la marque OnBuch.
Future<void> exportCorrectionPdf({
  required String correction,
  Uint8List? image,
  String? question,
  String? title,
}) async {
  // Police Unicode (gère les symboles math) avec repli sur la police par défaut.
  pw.ThemeData? theme;
  try {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    theme = pw.ThemeData.withFont(base: base, bold: bold);
  } catch (_) {
    theme = null;
  }

  final doc = pw.Document(theme: theme);
  const orange = PdfColor.fromInt(0xFFF59321);
  const ink = PdfColor.fromInt(0xFF1C1714);
  const ink2 = PdfColor.fromInt(0xFF5B5048);
  final date = DateFormat('d MMMM y', 'fr_FR').format(DateTime.now());

  final cover = image != null ? pw.MemoryImage(image) : null;
  final blocks = _cleanToBlocks(correction);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text('OnBuch · Tuteur IA', style: pw.TextStyle(fontSize: 9, color: ink2)),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text('Généré par OnBuch — révise plus malin · page ${ctx.pageNumber}/${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF978B80))),
      ),
      build: (ctx) => [
        // En-tête de marque
        pw.Row(children: [
          pw.Container(
            width: 30, height: 30,
            decoration: pw.BoxDecoration(color: orange, borderRadius: pw.BorderRadius.circular(8)),
            alignment: pw.Alignment.center,
            child: pw.Text('OB', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(width: 10),
          pw.Text('OnBuch', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: ink)),
          pw.Spacer(),
          pw.Text(date, style: pw.TextStyle(fontSize: 10, color: ink2)),
        ]),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, color: orange, width: 48),
        pw.SizedBox(height: 16),

        pw.Text('Correction — Tuteur IA', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: ink)),
        if (title != null && title.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(title, style: pw.TextStyle(fontSize: 11, color: ink2)),
        ],
        pw.SizedBox(height: 16),

        // Énoncé
        _sectionTitle('Exercice', orange),
        pw.SizedBox(height: 8),
        if (cover != null)
          pw.Center(child: pw.ClipRRect(
            horizontalRadius: 8, verticalRadius: 8,
            child: pw.Image(cover, width: 320, fit: pw.BoxFit.contain),
          ))
        else if (question != null && question.isNotEmpty)
          pw.Text(question, style: const pw.TextStyle(fontSize: 11, color: ink))
        else
          pw.Text('—', style: const pw.TextStyle(fontSize: 11, color: ink2)),
        pw.SizedBox(height: 18),

        // Correction
        _sectionTitle('Correction', orange),
        pw.SizedBox(height: 8),
        ...blocks,
      ],
    ),
  );

  await Printing.sharePdf(bytes: await doc.save(), filename: 'onbuch-correction.pdf');
}

pw.Widget _sectionTitle(String t, PdfColor color) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF6E8), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFA85607))),
    );

/// Nettoie le markdown/LaTeX en texte lisible et le découpe en blocs PDF.
List<pw.Widget> _cleanToBlocks(String raw) {
  var s = raw;
  // Retire les blocs graphiques (non rendus en PDF).
  s = s.replaceAll(RegExp(r'```onbuch-plot[\s\S]*?```'), '[Graphique disponible dans l\'application]');
  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), '');
  // Délimiteurs maths -> texte
  s = s.replaceAll(RegExp(r'\\[\(\)\[\]]'), '');
  s = s.replaceAllMapped(RegExp(r'\\frac\{([^{}]*)\}\{([^{}]*)\}'), (m) => '(${m[1]})/(${m[2]})');
  s = s.replaceAllMapped(RegExp(r'\\sqrt\{([^{}]*)\}'), (m) => 'sqrt(${m[1]})');
  // Conversions ASCII (sûres même sans police Unicode).
  const repl = {
    r'\Delta': 'Delta', r'\times': 'x', r'\div': '/', r'\pm': '+/-', r'\cdot': '.',
    r'\le': '<=', r'\ge': '>=', r'\neq': '!=', r'\infty': 'inf', r'\alpha': 'alpha',
    r'\beta': 'beta', r'\pi': 'pi', r'\Rightarrow': '=>', r'\rightarrow': '->', r'\,': ' ',
  };
  repl.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'\{|\}'), '');

  const ink = PdfColor.fromInt(0xFF1C1714);
  const ink2 = PdfColor.fromInt(0xFF5B5048);
  final widgets = <pw.Widget>[];

  for (final lineRaw in s.split('\n')) {
    final line = lineRaw.trimRight();
    final t = line.trim();
    if (t.isEmpty) {
      widgets.add(pw.SizedBox(height: 6));
      continue;
    }
    if (t.startsWith('### ') || t.startsWith('#### ')) {
      widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
          child: pw.Text(_inline(t.replaceAll(RegExp(r'^#+\s*'), '')),
              style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: ink))));
    } else if (t.startsWith('## ') || t.startsWith('# ')) {
      widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
          child: pw.Text(_inline(t.replaceAll(RegExp(r'^#+\s*'), '')),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: ink))));
    } else if (RegExp(r'^[-*]\s+').hasMatch(t)) {
      widgets.add(pw.Bullet(text: _inline(t.replaceFirst(RegExp(r'^[-*]\s+'), '')),
          style: const pw.TextStyle(fontSize: 11, color: ink2, lineSpacing: 2)));
    } else if (t.startsWith('|')) {
      // Lignes de tableau : on les rend en texte simple.
      widgets.add(pw.Text(t.replaceAll('|', '  ').replaceAll(RegExp(r'-{2,}'), '—'),
          style: const pw.TextStyle(fontSize: 10, color: ink2)));
    } else {
      widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(_inline(t), style: const pw.TextStyle(fontSize: 11, color: ink, lineSpacing: 2))));
    }
  }
  return widgets;
}

/// Retire les marqueurs gras/italiques markdown (pas de rich-text simple ici).
String _inline(String s) => s.replaceAll(RegExp(r'\*\*|__|\*|`'), '');
