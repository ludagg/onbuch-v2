import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../theme/app_theme.dart';

/// Rendu riche d'une réponse du Tuteur :
/// - Markdown (titres, listes, **gras**, tableaux)
/// - Maths LaTeX (`$...$`, `$$...$$`)
/// - Graphiques décrits par des blocs ```onbuch-plot { ...json... } ```
class RichAnswer extends StatelessWidget {
  final String text;
  final Color textColor;
  const RichAnswer(this.text, {super.key, this.textColor = OC.ink});

  static final _plotRe =
      RegExp(r'```onbuch-plot\s*([\s\S]*?)```', multiLine: true);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var last = 0;
    for (final m in _plotRe.allMatches(text)) {
      final before = text.substring(last, m.start).trim();
      if (before.isNotEmpty) children.add(_markdown(before));
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: _PlotBlock(m.group(1)?.trim() ?? ''),
      ));
      last = m.end;
    }
    final tail = text.substring(last).trim();
    if (tail.isNotEmpty) children.add(_markdown(tail));
    if (children.isEmpty) children.add(_markdown(text));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _markdown(String md) => GptMarkdown(
        md,
        style: body(13.5, color: textColor).copyWith(height: 1.5),
      );
}

// ─── Bloc graphique ───────────────────────────────────────────────────────────
class _PlotBlock extends StatelessWidget {
  final String spec;
  const _PlotBlock(this.spec);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(spec) as Map<String, dynamic>;
    } catch (_) {
      return const _PlotUnavailable();
    }

    final title = (data['title'] ?? '').toString();
    final type = (data['type'] ?? 'line').toString();
    final series = _parseSeries(data);
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

  FlLine _grid(double v) => const FlLine(color: OC.line, strokeWidth: 1);

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

  static const _palette = [OC.o500, OC.blue, OC.good, OC.warn, Color(0xFF7A5AE0)];
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
          const Icon(Icons.show_chart_rounded, size: 16, color: OC.muted),
          const SizedBox(width: 8),
          Text('Graphique indisponible', style: body(12, color: OC.muted, weight: FontWeight.w600)),
        ]),
      );
}
