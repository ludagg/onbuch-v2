import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../theme/app_theme.dart';

/// Rendu riche d'une réponse du Tuteur :
/// - Markdown (titres, listes, **gras**, tableaux)
/// - Maths LaTeX (`$...$`, `$$...$$`)
/// - Graphiques de fonction : blocs ```onbuch-plot { ...json... } ```
/// - Figures / schémas vectoriels exacts : blocs ```onbuch-svg <svg…/> ```
class RichAnswer extends StatelessWidget {
  final String text;
  final Color? textColor; // défaut résolu au build (OC.ink dépend du thème)
  const RichAnswer(this.text, {super.key, this.textColor});

  // Capture un bloc onbuch-plot OU onbuch-svg. group(1) = type, group(2) = contenu.
  static final _blockRe =
      RegExp(r'```onbuch-(plot|svg)\s*([\s\S]*?)```', multiLine: true);

  @override
  Widget build(BuildContext context) {
    final src = _normalizeBlocks(text);
    final children = <Widget>[];
    var last = 0;
    for (final m in _blockRe.allMatches(src)) {
      final before = src.substring(last, m.start).trim();
      if (before.isNotEmpty) children.add(_markdown(before));
      final kind = m.group(1);
      final content = m.group(2)?.trim() ?? '';
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: kind == 'svg' ? _SvgBlock(content) : _PlotBlock(content),
      ));
      last = m.end;
    }
    final tail = src.substring(last).trim();
    if (tail.isNotEmpty) children.add(_markdown(tail));
    if (children.isEmpty) children.add(_markdown(src));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Le modèle enveloppe parfois le graphique/figure dans un bloc ```json avec une
  // clé « onbuch-plot » / « onbuch-svg » au lieu d'utiliser la balise dédiée. On
  // réécrit ces blocs vers ```onbuch-plot / ```onbuch-svg pour qu'ils s'affichent.
  static final _jsonBlockRe =
      RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', multiLine: true);
  static String _normalizeBlocks(String s) {
    if (!s.contains('onbuch-')) return s;
    return s.replaceAllMapped(_jsonBlockRe, (m) {
      try {
        final obj = jsonDecode(m[1]!);
        if (obj is Map) {
          final plot = obj['onbuch-plot'] ?? obj['plot'];
          if (plot is Map) return '```onbuch-plot\n${jsonEncode(plot)}\n```';
          final svg = obj['onbuch-svg'] ?? obj['svg'];
          if (svg is String && svg.contains('<svg')) return '```onbuch-svg\n$svg\n```';
        }
      } catch (_) {/* pas un JSON onbuch → inchangé */}
      return m[0]!;
    });
  }

  Widget _markdown(String md) => GptMarkdown(
        _normalizeMath(md),
        style: body(13.5, color: textColor ?? OC.ink).copyWith(height: 1.5),
      );

  /// `gpt_markdown` rend les maths avec \( \) (en ligne) et \[ \] (bloc), pas
  /// avec des `$`. On convertit donc les délimiteurs dollar produits par le
  /// modèle pour qu'ils s'affichent bien.
  static String _normalizeMath(String s) {
    // Défense contre le sur-échappement : certains modèles renvoient parfois
    // `\\frac`, `\\lim`, `\\boxed`… (double antislash). `flutter_math_fork`
    // interprète `\\` comme un saut de ligne ⇒ la commande s'affiche en brut.
    // Un vrai saut de ligne LaTeX (`\\`) n'est jamais suivi d'une lettre, donc
    // on peut sans risque ré-assembler `\\` + lettre en une seule commande.
    var out = s.replaceAllMapped(RegExp(r'\\\\([a-zA-Z])'), (m) => '\\${m[1]}');
    out = out.replaceAllMapped(RegExp(r'\$\$([\s\S]+?)\$\$'), (m) => '\\[${m[1]}\\]');
    out = out.replaceAllMapped(RegExp(r'\$([^\$\n]+?)\$'), (m) => '\\(${m[1]}\\)');
    return out;
  }
}

// ─── Bloc graphique ───────────────────────────────────────────────────────────
class _PlotBlock extends StatelessWidget {
  final String spec;
  const _PlotBlock(this.spec);

  // Repli quand le JSON du graphe est cassé : extraction directe des paires [x,y].
  static final _rePair =
      RegExp(r'\[\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\]');
  static final _reTitle = RegExp(r'"title"\s*:\s*"([^"]*)"');
  static final _reType = RegExp(r'"type"\s*:\s*"(line|bar)"');

  static List<FlSpot> _salvagePoints(String spec) {
    final spots = <FlSpot>[];
    for (final m in _rePair.allMatches(spec)) {
      final x = double.tryParse(m[1]!);
      final y = double.tryParse(m[2]!);
      if (x != null && y != null && x.isFinite && y.isFinite) spots.add(FlSpot(x, y));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(spec) as Map<String, dynamic>;
    } catch (_) {
      data = null; // JSON cassé (ex. crochet manquant) → on tentera un repli.
    }
    // Tolérance : contenu enveloppé dans une clé « onbuch-plot »/« plot ».
    if (data != null) {
      final wrapped = data['onbuch-plot'] ?? data['plot'];
      if (wrapped is Map) data = Map<String, dynamic>.from(wrapped);
    }

    var title = (data?['title'] ?? '').toString();
    var type = (data?['type'] ?? 'line').toString();
    var series = data != null ? _parseSeries(data) : <_Series>[];

    // Repli robuste : si le JSON est invalide/illisible (les modèles ratent
    // parfois un crochet sur les longs tableaux), on récupère directement toutes
    // les paires [x, y] présentes dans le texte brut → le graphe s'affiche quand même.
    if (series.isEmpty) {
      final pts = _salvagePoints(spec);
      if (pts.length >= 2) {
        series = [_Series('', pts)];
        if (title.isEmpty) title = _reTitle.firstMatch(spec)?.group(1) ?? '';
        final t = _reType.firstMatch(spec)?.group(1);
        if (t != null) type = t;
      }
    }
    if (series.isEmpty) return const _PlotUnavailable();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title.isNotEmpty) ...[
          Text(title, style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 210,
          child: type == 'bar' ? _bar(series) : _line(series),
        ),
        const SizedBox(height: 8),
        _legend(series),
      ]),
    );
  }

  List<_Series> _parseSeries(Map<String, dynamic> data) {
    final out = <_Series>[];
    final raw = data['series'];
    if (raw is List) {
      for (final s in raw) {
        if (s is! Map) continue;
        final label = (s['label'] ?? '').toString();
        final pts = _points(s['points']);
        if (pts.isNotEmpty) out.add(_Series(label, pts));
      }
    }
    // Tolérance : "points" au premier niveau.
    if (out.isEmpty) {
      final pts = _points(data['points']);
      if (pts.isNotEmpty) out.add(_Series((data['label'] ?? '').toString(), pts));
    }
    return out;
  }

  List<FlSpot> _points(dynamic raw) {
    final spots = <FlSpot>[];
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
        if (x != null && y != null && x.isFinite && y.isFinite) {
          spots.add(FlSpot(x, y));
        }
      }
    }
    return spots;
  }

  Widget _line(List<_Series> series) {
    final bars = <LineChartBarData>[];
    for (var i = 0; i < series.length; i++) {
      bars.add(LineChartBarData(
        spots: series[i].points,
        isCurved: true,
        color: _palette[i % _palette.length],
        barWidth: 2.6,
        dotData: const FlDotData(show: false),
      ));
    }
    return LineChart(LineChartData(
      lineBarsData: bars,
      gridData: FlGridData(show: true, getDrawingHorizontalLine: _grid, getDrawingVerticalLine: _grid),
      titlesData: _titles(),
      borderData: FlBorderData(show: true, border: Border.all(color: OC.line2, width: 1)),
    ));
  }

  Widget _bar(List<_Series> series) {
    final s = series.first;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < s.points.length; i++) {
      groups.add(BarChartGroupData(x: s.points[i].x.round(), barRods: [
        BarChartRodData(
          toY: s.points[i].y,
          color: _palette[0],
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ]));
    }
    return BarChart(BarChartData(
      barGroups: groups,
      gridData: FlGridData(show: true, getDrawingHorizontalLine: _grid, drawVerticalLine: false),
      titlesData: _titles(),
      borderData: FlBorderData(show: true, border: Border.all(color: OC.line2, width: 1)),
    ));
  }

  FlTitlesData _titles() => FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      );

  FlLine _grid(double v) => FlLine(color: OC.line, strokeWidth: 1);

  Widget _legend(List<_Series> series) {
    final items = <Widget>[];
    for (var i = 0; i < series.length; i++) {
      if (series[i].label.isEmpty) continue;
      items.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(
          color: _palette[i % _palette.length], borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(series[i].label, style: body(11, weight: FontWeight.w600, color: OC.ink2)),
      ]));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 14, runSpacing: 6, children: items);
  }

  static List<Color> get _palette => [OC.o500, OC.blue, OC.good, OC.warn, const Color(0xFF7A5AE0)];
}

double? _toD(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class _Series {
  final String label;
  final List<FlSpot> points;
  const _Series(this.label, this.points);
}

// ─── Figure / schéma vectoriel (SVG) ─────────────────────────────────────────
class _SvgBlock extends StatelessWidget {
  final String code;
  const _SvgBlock(this.code);

  @override
  Widget build(BuildContext context) {
    var svg = code.trim();
    // Tolérance : SVG enveloppé dans un JSON { "onbuch-svg": "<svg…/>" }.
    if (svg.startsWith('{')) {
      try {
        final obj = jsonDecode(svg);
        final inner = obj is Map ? (obj['onbuch-svg'] ?? obj['svg']) : null;
        if (inner is String) svg = inner.trim();
      } catch (_) {/* on garde le texte tel quel */}
    }
    if (!svg.contains('<svg')) return const _PlotUnavailable();
    // Toujours sur fond blanc (les figures ont des traits sombres) → lisible
    // aussi en mode sombre.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: SvgPicture.string(
          svg,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox(height: 80,
              child: Center(child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: OC.o500)))),
        ),
      ),
    );
  }
}

class _PlotUnavailable extends StatelessWidget {
  const _PlotUnavailable();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: OC.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Icon(Icons.show_chart_rounded, size: 16, color: OC.muted),
          const SizedBox(width: 8),
          Text('Graphique indisponible', style: body(12, color: OC.muted, weight: FontWeight.w600)),
        ]),
      );
}
