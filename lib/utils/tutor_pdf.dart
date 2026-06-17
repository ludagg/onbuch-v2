import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
const _o100 = PdfColor.fromInt(0xFFFCE9C7);
const _ink = PdfColor.fromInt(0xFF1C1714);
const _ink2 = PdfColor.fromInt(0xFF5B5048);
const _muted = PdfColor.fromInt(0xFF978B80);
const _line2 = PdfColor.fromInt(0xFFE4DACE);
const _bg = PdfColor.fromInt(0xFFFAF6F1);
const _palette = [
  PdfColor.fromInt(0xFFF59321), PdfColor.fromInt(0xFF2D6CDF),
  PdfColor.fromInt(0xFF1E9E63), PdfColor.fromInt(0xFFC9781C),
  PdfColor.fromInt(0xFF7A5AE0),
];

// Jetons privés délimitant un fragment de maths déjà converti (pour ne pas le
// confondre avec du markdown ou un nombre ordinaire).
const _mOpen = '';
const _mClose = '';

/// Génère un PDF élégant de toute la conversation (énoncés + corrections),
/// avec texte mis en forme, maths lisibles et graphiques, puis le partage.
Future<void> exportConversationPdf({
  required List<PdfTurn> turns,
  String? title,
}) async {
  pw.ThemeData? theme;
  try {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();
    theme = pw.ThemeData.withFont(
        base: base, bold: bold, italic: italic, boldItalic: boldItalic);
  } catch (_) {
    theme = null;
  }

  final doc = pw.Document(theme: theme);
  final date = DateFormat('d MMMM y', 'fr_FR').format(DateTime.now());

  final body = <pw.Widget>[];
  for (final t in turns) {
    if (t.isUser) {
      body.add(_userBlock(t));
      body.add(pw.SizedBox(height: 10));
    } else {
      if (t.text.trim().isEmpty) continue;
      body.add(_aiLabel());
      body.add(pw.SizedBox(height: 6));
      body.addAll(_renderMarkdown(t.text));
      body.add(pw.SizedBox(height: 16));
    }
  }

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(38, 38, 38, 46),
    header: (ctx) => ctx.pageNumber == 1
        ? pw.SizedBox()
        : pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text('OnBuch · Tuteur IA',
                style: pw.TextStyle(fontSize: 9, color: _muted)),
          ),
    footer: (ctx) => pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
          'Généré par OnBuch — révise plus malin · page ${ctx.pageNumber}/${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: _muted)),
    ),
    build: (ctx) => [
      _brandHeader(date, title),
      pw.SizedBox(height: 18),
      ...body,
    ],
  ));

  await Printing.sharePdf(bytes: await doc.save(), filename: 'onbuch-tuteur.pdf');
}

// ─── En-tête de marque ───────────────────────────────────────────────────────
pw.Widget _brandHeader(String date, String? title) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(children: [
      pw.Container(
        width: 30, height: 30,
        decoration: pw.BoxDecoration(color: _orange, borderRadius: pw.BorderRadius.circular(8)),
        alignment: pw.Alignment.center,
        child: pw.Text('OB', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(width: 10),
      pw.Text('OnBuch', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.Spacer(),
      pw.Text(date, style: pw.TextStyle(fontSize: 10, color: _ink2)),
    ]),
    pw.SizedBox(height: 6),
    pw.Container(height: 2.5, width: 52, color: _orange),
    pw.SizedBox(height: 14),
    pw.Text('Tuteur IA — correction', style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: _ink)),
    if (title != null && title.trim().isNotEmpty) ...[
      pw.SizedBox(height: 3),
      pw.Text(title.trim(), style: pw.TextStyle(fontSize: 11, color: _ink2)),
    ],
  ]);
}

pw.Widget _aiLabel() => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: pw.BoxDecoration(color: _o50, borderRadius: pw.BorderRadius.circular(20)),
      child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Container(width: 7, height: 7, decoration: pw.BoxDecoration(color: _orange, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 6),
        pw.Text('Tuteur OnBuch', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _o700)),
      ]),
    );

pw.Widget _userBlock(PdfTurn t) {
  final children = <pw.Widget>[
    pw.Text('VOTRE QUESTION',
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _muted, letterSpacing: 0.6)),
  ];
  if (t.image != null) {
    children.add(pw.SizedBox(height: 8));
    children.add(pw.ClipRRect(
      horizontalRadius: 8, verticalRadius: 8,
      child: pw.Image(pw.MemoryImage(t.image!), height: 230, fit: pw.BoxFit.contain),
    ));
  }
  if (t.text.trim().isNotEmpty) {
    children.add(pw.SizedBox(height: 6));
    children.add(pw.RichText(text: _inline(t.text.trim(), size: 11, color: _ink)));
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.fromLTRB(14, 11, 14, 12),
    decoration: pw.BoxDecoration(
      color: _o50,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: _o100, width: 1),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
  );
}

// ─── Markdown → widgets PDF ──────────────────────────────────────────────────
List<pw.Widget> _renderMarkdown(String raw) {
  final out = <pw.Widget>[];
  final plotRe = RegExp(r'```onbuch-plot\s*([\s\S]*?)```', multiLine: true);
  var last = 0;
  for (final m in plotRe.allMatches(raw)) {
    _renderText(raw.substring(last, m.start), out);
    out.add(_chart(m.group(1)?.trim() ?? ''));
    last = m.end;
  }
  _renderText(raw.substring(last), out);
  return out;
}

void _renderText(String raw, List<pw.Widget> out) {
  // Blocs de code génériques (hors graphiques).
  final codeRe = RegExp(r'```[\w-]*\s*([\s\S]*?)```', multiLine: true);
  var last = 0;
  for (final m in codeRe.allMatches(raw)) {
    _renderLines(raw.substring(last, m.start), out);
    out.add(_codeBlock(m.group(1) ?? ''));
    last = m.end;
  }
  _renderLines(raw.substring(last), out);
}

void _renderLines(String block, List<pw.Widget> out) {
  final lines = block.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final t = lines[i].trim();
    if (t.isEmpty) {
      out.add(pw.SizedBox(height: 5));
      continue;
    }
    // Tableau : suite de lignes commençant par '|'.
    if (t.startsWith('|')) {
      final rows = <String>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.add(lines[i].trim());
        i++;
      }
      i--;
      final tbl = _table(rows);
      if (tbl != null) {
        out.add(tbl);
        continue;
      }
    }
    // Titres
    final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(t);
    if (h != null) {
      final lvl = h.group(1)!.length;
      final size = lvl <= 1 ? 15.0 : (lvl == 2 ? 13.5 : 12.0);
      out.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 9, bottom: 4),
        child: pw.RichText(text: _inline(h.group(2)!, size: size, color: _ink, weight: pw.FontWeight.bold)),
      ));
      continue;
    }
    // Séparateur horizontal
    if (RegExp(r'^([-*_])\1{2,}$').hasMatch(t.replaceAll(' ', ''))) {
      out.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Container(height: 1, color: _line2),
      ));
      continue;
    }
    // Citation
    if (t.startsWith('>')) {
      out.add(pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 4),
        padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: pw.BoxDecoration(
          color: _o50,
          borderRadius: pw.BorderRadius.circular(6),
          border: const pw.Border(left: pw.BorderSide(color: _orange, width: 2.5)),
        ),
        child: pw.RichText(text: _inline(t.replaceFirst(RegExp(r'^>\s?'), ''), size: 10.5, color: _ink2)),
      ));
      continue;
    }
    // Puces
    final b = RegExp(r'^[-*+]\s+(.*)$').firstMatch(t);
    if (b != null) {
      out.add(_bulletRow('•', b.group(1)!));
      continue;
    }
    // Liste numérotée
    final n = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(t);
    if (n != null) {
      out.add(_bulletRow('${n.group(1)}.', n.group(2)!));
      continue;
    }
    // Paragraphe
    out.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(text: _inline(t, size: 10.5, color: _ink)),
    ));
  }
}

pw.Widget _bulletRow(String marker, String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3, left: 2),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(
          width: 16,
          child: pw.Text(marker, style: pw.TextStyle(fontSize: 10.5, color: _o700, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(child: pw.RichText(text: _inline(text, size: 10.5, color: _ink))),
      ]),
    );

pw.Widget _codeBlock(String code) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: _bg, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: _line2, width: 1)),
      child: pw.Text(code.trim(), style: pw.TextStyle(fontSize: 9.5, color: _ink2)),
    );

pw.Widget? _table(List<String> rows) {
  List<String> cells(String r) {
    var x = r.trim();
    if (x.startsWith('|')) x = x.substring(1);
    if (x.endsWith('|')) x = x.substring(0, x.length - 1);
    return x.split('|').map((c) => _plain(c.trim())).toList();
  }

  final parsed = rows.map(cells).toList();
  // Retire les lignes de séparation (---).
  final kept = parsed.where((r) =>
      !r.every((c) => c.isEmpty || RegExp(r'^:?-{2,}:?$').hasMatch(c.replaceAll(' ', '')))).toList();
  if (kept.isEmpty) return null;
  final headers = kept.first;
  final data = kept.skip(1).toList();
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.TableHelper.fromTextArray(
      headers: headers,
      data: data.isEmpty ? <List<String>>[List.filled(headers.length, '')] : data,
      border: pw.TableBorder.all(color: _line2, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: _o50),
      headerStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _o700),
      cellStyle: pw.TextStyle(fontSize: 9.5, color: _ink),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      cellAlignment: pw.Alignment.centerLeft,
    ),
  );
}

// ─── Graphique natif PDF ─────────────────────────────────────────────────────
class _S {
  final String label;
  final List<List<double>> pts;
  _S(this.label, this.pts);
}

pw.Widget _chart(String spec) {
  try {
    final data = jsonDecode(spec) as Map<String, dynamic>;
    final type = (data['type'] ?? 'line').toString();
    final title = (data['title'] ?? '').toString();
    final series = _parseSeries(data);
    if (series.isEmpty) return _chartFallback();

    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final s in series) {
      for (final p in s.pts) {
        minX = math.min(minX, p[0]);
        maxX = math.max(maxX, p[0]);
        minY = math.min(minY, p[1]);
        maxY = math.max(maxY, p[1]);
      }
    }
    if (minY > 0) minY = 0; // base à zéro pour bien lire

    final datasets = <pw.Dataset>[];
    if (type == 'bar') {
      final s = series.first;
      datasets.add(pw.BarDataSet(
        legend: s.label.isEmpty ? null : s.label,
        color: _palette[0],
        width: 14,
        data: [for (final p in s.pts) pw.PointChartValue(p[0], p[1])],
      ));
    } else {
      for (var i = 0; i < series.length; i++) {
        datasets.add(pw.LineDataSet(
          legend: series[i].label.isEmpty ? null : series[i].label,
          color: _palette[i % _palette.length],
          isCurved: true,
          drawPoints: false,
          lineWidth: 2,
          drawSurface: false,
          data: [for (final p in series[i].pts) pw.PointChartValue(p[0], p[1])],
        ));
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line2, width: 1),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (title.isNotEmpty) ...[
          pw.Text(_plain(title), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _ink2)),
          pw.SizedBox(height: 10),
        ],
        pw.SizedBox(
          height: 180,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(_ticks(minX, maxX), divisions: true, color: _line2, textStyle: pw.TextStyle(fontSize: 7, color: _muted)),
              yAxis: pw.FixedAxis(_ticks(minY, maxY), divisions: true, color: _line2, textStyle: pw.TextStyle(fontSize: 7, color: _muted)),
            ),
            datasets: datasets,
          ),
        ),
        if (series.any((s) => s.label.isNotEmpty)) ...[
          pw.SizedBox(height: 8),
          pw.Wrap(spacing: 14, runSpacing: 4, children: [
            for (var i = 0; i < series.length; i++)
              if (series[i].label.isNotEmpty)
                pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                  pw.Container(width: 9, height: 9, decoration: pw.BoxDecoration(color: _palette[i % _palette.length], borderRadius: pw.BorderRadius.circular(2))),
                  pw.SizedBox(width: 5),
                  pw.Text(series[i].label, style: pw.TextStyle(fontSize: 9, color: _ink2)),
                ]),
          ]),
        ],
      ]),
    );
  } catch (_) {
    return _chartFallback();
  }
}

pw.Widget _chartFallback() => pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(color: _bg, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: _line2, width: 1)),
      child: pw.Text('[Graphique]', style: pw.TextStyle(fontSize: 10, color: _muted)),
    );

List<_S> _parseSeries(Map<String, dynamic> data) {
  final out = <_S>[];
  final raw = data['series'];
  if (raw is List) {
    for (final s in raw) {
      if (s is! Map) continue;
      final pts = _points(s['points']);
      if (pts.isNotEmpty) out.add(_S((s['label'] ?? '').toString(), pts));
    }
  }
  if (out.isEmpty) {
    final pts = _points(data['points']);
    if (pts.isNotEmpty) out.add(_S((data['label'] ?? '').toString(), pts));
  }
  return out;
}

List<List<double>> _points(dynamic raw) {
  final out = <List<double>>[];
  if (raw is List) {
    for (final p in raw) {
      double? x, y;
      if (p is List && p.length >= 2) {
        x = _toD(p[0]);
        y = _toD(p[1]);
      } else if (p is Map) {
        x = _toD(p['x']);
        y = _toD(p['y']);
      }
      if (x != null && y != null && x.isFinite && y.isFinite) out.add([x, y]);
    }
  }
  return out;
}

double? _toD(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

List<double> _ticks(double a, double b) {
  if (!a.isFinite || !b.isFinite) return [0, 1];
  if (a == b) {
    a -= 1;
    b += 1;
  }
  final step = (b - a) / 4.0;
  return [for (var i = 0; i <= 4; i++) double.parse((a + step * i).toStringAsFixed(2))];
}

// ─── Inline (gras / italique / code / maths) ─────────────────────────────────
pw.TextSpan _inline(String raw, {required double size, required PdfColor color, pw.FontWeight? weight}) {
  final maths = <String>[];
  String repl(Match m) {
    maths.add(_mathToUnicode(m[1]!));
    return '$_mOpen${maths.length - 1}$_mClose';
  }

  var s = raw
      .replaceAllMapped(RegExp(r'\\\[([\s\S]+?)\\\]'), repl)
      .replaceAllMapped(RegExp(r'\$\$([\s\S]+?)\$\$'), repl)
      .replaceAllMapped(RegExp(r'\\\(([\s\S]+?)\\\)'), repl)
      .replaceAllMapped(RegExp(r'\$([^\$\n]+?)\$'), repl);

  final base = pw.TextStyle(fontSize: size, color: color, fontWeight: weight);
  final spans = <pw.TextSpan>[];
  // Gras (**/__), italique (*), code (`), puis jeton maths protégé.
  final re = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|\*(.+?)\*|`(.+?)`|' +
      _mOpen + r'(\d+)' + _mClose);
  var i = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > i) spans.add(pw.TextSpan(text: s.substring(i, m.start), style: base));
    if (m.group(1) != null || m.group(2) != null) {
      spans.add(pw.TextSpan(text: m.group(1) ?? m.group(2), style: base.copyWith(fontWeight: pw.FontWeight.bold)));
    } else if (m.group(3) != null) {
      spans.add(pw.TextSpan(text: m.group(3), style: base.copyWith(fontStyle: pw.FontStyle.italic)));
    } else if (m.group(4) != null) {
      spans.add(pw.TextSpan(text: m.group(4), style: base.copyWith(color: _o700)));
    } else if (m.group(5) != null) {
      spans.add(pw.TextSpan(text: maths[int.parse(m.group(5)!)], style: base));
    }
    i = m.end;
  }
  if (i < s.length) spans.add(pw.TextSpan(text: s.substring(i), style: base));
  return pw.TextSpan(children: spans);
}

/// Convertit les `$...$` markdown en texte simple lisible et retire les
/// marqueurs de gras/italique (pour les cellules de tableau & titres).
String _plain(String s) {
  var x = s
      .replaceAllMapped(RegExp(r'\\\[([\s\S]+?)\\\]'), (m) => _mathToUnicode(m[1]!))
      .replaceAllMapped(RegExp(r'\$\$([\s\S]+?)\$\$'), (m) => _mathToUnicode(m[1]!))
      .replaceAllMapped(RegExp(r'\\\(([\s\S]+?)\\\)'), (m) => _mathToUnicode(m[1]!))
      .replaceAllMapped(RegExp(r'\$([^\$\n]+?)\$'), (m) => _mathToUnicode(m[1]!));
  x = x.replaceAll(RegExp(r'\*\*|__|\*|`'), '');
  return x.trim();
}

// ─── LaTeX → Unicode ─────────────────────────────────────────────────────────
const _supMap = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹','+':'⁺','-':'⁻','=':'⁼','(':'⁽',')':'⁾','n':'ⁿ','i':'ⁱ','x':'ˣ'};
const _subMap = {'0':'₀','1':'₁','2':'₂','3':'₃','4':'₄','5':'₅','6':'₆','7':'₇','8':'₈','9':'₉','+':'₊','-':'₋','=':'₌','(':'₍',')':'₎','a':'ₐ','e':'ₑ','i':'ᵢ','o':'ₒ','x':'ₓ','n':'ₙ','t':'ₜ','h':'ₕ','k':'ₖ','l':'ₗ','m':'ₘ','p':'ₚ','s':'ₛ'};

String _sup(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    final v = _supMap[c];
    if (v == null) return '^($s)';
    b.write(v);
  }
  return b.toString();
}

String _sub(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    final v = _subMap[c];
    if (v == null) return '_($s)';
    b.write(v);
  }
  return b.toString();
}

bool _needsParen(String s) => RegExp(r'[+\-/×·]').hasMatch(s.trim());

String _mathToUnicode(String input) {
  var s = input;
  // \text{...}, \mathrm{...}, \mathbf{...}, \operatorname{...} → contenu
  s = s.replaceAllMapped(RegExp(r'\\(?:text|mathrm|mathbf|mathit|operatorname)\s*\{([^{}]*)\}'), (m) => m[1]!);
  // fractions (plusieurs passes pour les imbrications simples)
  final frac = RegExp(r'\\frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}');
  for (var i = 0; i < 4 && frac.hasMatch(s); i++) {
    s = s.replaceAllMapped(frac, (m) {
      final a = m[1]!, b = m[2]!;
      return '${_needsParen(a) ? '($a)' : a}/${_needsParen(b) ? '($b)' : b}';
    });
  }
  // racines
  s = s.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^{}]*)\}'), (m) => '√(${m[1]})');
  s = s.replaceAllMapped(RegExp(r'\\sqrt\s+(\w)'), (m) => '√${m[1]}');
  // commandes → unicode
  const cmd = {
    r'\times': '×', r'\cdot': '·', r'\div': '÷', r'\pm': '±', r'\mp': '∓',
    r'\leq': '≤', r'\le': '≤', r'\geq': '≥', r'\ge': '≥', r'\neq': '≠', r'\ne': '≠',
    r'\approx': '≈', r'\equiv': '≡', r'\propto': '∝', r'\sim': '∼',
    r'\infty': '∞', r'\partial': '∂', r'\nabla': '∇', r'\degree': '°',
    r'\sum': '∑', r'\prod': '∏', r'\int': '∫',
    r'\Rightarrow': '⇒', r'\Leftarrow': '⇐', r'\Leftrightarrow': '⇔',
    r'\rightarrow': '→', r'\leftarrow': '←', r'\to': '→', r'\mapsto': '↦',
    r'\alpha': 'α', r'\beta': 'β', r'\gamma': 'γ', r'\delta': 'δ', r'\Delta': 'Δ',
    r'\epsilon': 'ε', r'\varepsilon': 'ε', r'\zeta': 'ζ', r'\eta': 'η',
    r'\theta': 'θ', r'\vartheta': 'ϑ', r'\iota': 'ι', r'\kappa': 'κ',
    r'\lambda': 'λ', r'\Lambda': 'Λ', r'\mu': 'μ', r'\nu': 'ν', r'\xi': 'ξ',
    r'\pi': 'π', r'\Pi': 'Π', r'\rho': 'ρ', r'\sigma': 'σ', r'\Sigma': 'Σ',
    r'\tau': 'τ', r'\upsilon': 'υ', r'\phi': 'φ', r'\varphi': 'φ', r'\Phi': 'Φ',
    r'\chi': 'χ', r'\psi': 'ψ', r'\Psi': 'Ψ', r'\omega': 'ω', r'\Omega': 'Ω',
    r'\in': '∈', r'\notin': '∉', r'\subset': '⊂', r'\subseteq': '⊆',
    r'\cup': '∪', r'\cap': '∩', r'\emptyset': '∅', r'\varnothing': '∅',
    r'\forall': '∀', r'\exists': '∃', r'\angle': '∠', r'\perp': '⊥',
    r'\parallel': '∥', r'\cdots': '⋯', r'\ldots': '…', r'\dots': '…',
    r'\circ': '∘', r'\ast': '∗', r'\star': '⋆', r'\bullet': '•',
    r'\left': '', r'\right': '', r'\quad': '  ', r'\qquad': '    ',
    r'\,': ' ', r'\;': ' ', r'\:': ' ', r'\!': '', r'\\': ' ',
  };
  cmd.forEach((k, v) => s = s.replaceAll(k, v));
  // exposants & indices
  s = s.replaceAllMapped(RegExp(r'\^\{([^{}]*)\}'), (m) => _sup(m[1]!));
  s = s.replaceAllMapped(RegExp(r'\^(\w)'), (m) => _sup(m[1]!));
  s = s.replaceAllMapped(RegExp(r'_\{([^{}]*)\}'), (m) => _sub(m[1]!));
  s = s.replaceAllMapped(RegExp(r'_(\w)'), (m) => _sub(m[1]!));
  // nettoyage des commandes restantes et accolades
  s = s.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
  s = s.replaceAll(RegExp(r'[{}\\]'), '');
  s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return s.trim();
}
