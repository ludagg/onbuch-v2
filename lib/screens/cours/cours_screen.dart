import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Accueil du module Cours (refonte « Nomad Educ ») : progression, reprise de
/// la dernière leçon, grille de matières avec anneaux de progression.
class CoursScreen extends StatefulWidget {
  const CoursScreen({super.key});

  @override
  State<CoursScreen> createState() => _CoursScreenState();
}

class _CoursScreenState extends State<CoursScreen> {
  final _db = DatabaseService();
  List<Subject> _subjects = [];
  List<Chapter> _chapters = [];
  Set<String> _viewed = {};
  String? _classe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await _db.getSubjects();
    final chapters = await _db.getChapters();
    final viewed = await _db.getViewedChapterIds();
    String? classe;
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      final p = await _db.getUserProfile(user.$id);
      classe = p?['classe']?.toString();
    }
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _chapters = chapters;
        _viewed = viewed;
        _classe = classe;
        _loading = false;
      });
    }
  }

  List<Subject> get _visible {
    final v = _subjects.where((s) => s.appliesTo(_classe)).toList();
    return v.isEmpty ? _subjects : v;
  }

  List<Chapter> _chaptersOf(String subjectId) {
    final l = _chapters.where((c) => c.subjectId == subjectId).toList();
    l.sort((a, b) => a.order.compareTo(b.order));
    return l;
  }

  int _doneOf(List<Chapter> chs) => chs.where((c) => _viewed.contains(c.id)).length;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 40 - 12) / 2;
    final totalCh = _chapters.length;
    final doneCh = _chapters.where((c) => _viewed.contains(c.id)).length;
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: OC.bg,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 18,
          title: const OBWordmark(size: 23),
          actions: obTopActions(context),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cours', style: display(24, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(_classe != null && _classe!.isNotEmpty ? '$_classe · MINESEC' : 'Programme MINESEC',
                  style: body(13, color: OC.ink2, weight: FontWeight.w500)),
              const SizedBox(height: 16),

              // Recherche transverse
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/cours-search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: OC.line2, width: 1.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, size: 19, color: OC.muted),
                    const SizedBox(width: 11),
                    Text('Chercher un cours, une vidéo, un quiz…', style: body(13.5, color: OC.muted, weight: FontWeight.w500)),
                  ]),
                ),
              ),
              const SizedBox(height: 18),

              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: OC.o500)))
              else if (_subjects.isEmpty)
                _hint('Les matières arrivent bientôt.')
              else ...[
                _progressStrip(totalCh, doneCh),
                const SizedBox(height: 20),
                ..._resumeBlock(),
                Text('Mes matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: _visible.map((s) => _subjectCard(s, w)).toList(),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Bandeau de progression ────────────────────────────────────────────────
  Widget _progressStrip(int total, int done) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [OC.darkHero, OC.darkHero2]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        _Ring(pct: pct, size: 52, color: OC.o500, track: Colors.white24,
            center: Text('${(pct * 100).round()}%', style: mono(13, weight: FontWeight.w800, color: Colors.white))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ta progression', style: body(13.5, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('$done leçon${done > 1 ? 's' : ''} terminée${done > 1 ? 's' : ''} sur $total',
              style: body(12, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  // ── Reprendre ─────────────────────────────────────────────────────────────
  List<Widget> _resumeBlock() {
    final r = _resume();
    if (r == null) return const [];
    final (chapter, subject, idx, total) = r;
    final done = _doneOf(_chaptersOf(subject.id));
    final pct = total == 0 ? 0.0 : done / total;
    return [
      Text('Reprendre', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () async {
          await context.push('/cours-chapter', extra: {'chapter': chapter, 'subject': subject.name});
          if (mounted) _load();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OC.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OC.line, width: 1.5),
            boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: subject.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                child: Center(child: Icon(Icons.play_arrow_rounded, color: subject.color, size: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(6)),
                  child: Text('REPRENDRE', style: body(8.5, weight: FontWeight.w800, color: OC.o700).copyWith(letterSpacing: 0.04 * 8.5)),
                ),
                const SizedBox(height: 6),
                Text(chapter.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${subject.name} · Chapitre $idx/$total', style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
              ])),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: OC.line, valueColor: AlwaysStoppedAnimation(subject.color)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 22),
    ];
  }

  /// Choisit la prochaine leçon à reprendre : 1re matière en cours, sinon 1re
  /// leçon non vue, sinon la première leçon.
  (Chapter, Subject, int, int)? _resume() {
    Chapter? fallbackCh;
    Subject? fallbackSub;
    int fIdx = 0, fTotal = 0;
    for (final s in _visible) {
      final chs = _chaptersOf(s.id);
      if (chs.isEmpty) continue;
      final done = _doneOf(chs);
      final firstNot = chs.indexWhere((c) => !_viewed.contains(c.id));
      if (done > 0 && done < chs.length && firstNot >= 0) {
        return (chs[firstNot], s, firstNot + 1, chs.length);
      }
      if (fallbackCh == null) {
        final i = firstNot >= 0 ? firstNot : 0;
        fallbackCh = chs[i];
        fallbackSub = s;
        fIdx = i + 1;
        fTotal = chs.length;
      }
    }
    if (fallbackCh != null) return (fallbackCh, fallbackSub!, fIdx, fTotal);
    return null;
  }

  // ── Carte matière (avec anneau) ───────────────────────────────────────────
  Widget _subjectCard(Subject s, double w) {
    final chs = _chaptersOf(s.id);
    final total = chs.length;
    final done = _doneOf(chs);
    final pct = total == 0 ? 0.0 : done / total;
    return GestureDetector(
      onTap: () async {
        await context.push('/cours-subject', extra: s);
        if (mounted) _load();
      },
      child: Container(
        width: w,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: s.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
              child: Center(child: Text(s.code, style: display(16, weight: FontWeight.w700, color: s.color))),
            ),
            const Spacer(),
            _Ring(pct: pct, size: 36, color: s.color, track: OC.line,
                center: Text('${(pct * 100).round()}', style: mono(10.5, weight: FontWeight.w800, color: s.color))),
          ]),
          const SizedBox(height: 11),
          Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: body(14.5, weight: FontWeight.w700).copyWith(height: 1.15)),
          const SizedBox(height: 4),
          Text('$total chapitre${total > 1 ? 's' : ''}', style: body(12, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _hint(String t) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          const Icon(Icons.menu_book_rounded, size: 18, color: OC.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: body(13, color: OC.muted, weight: FontWeight.w500))),
        ]),
      );
}

// ─── Anneau de progression réutilisable ───────────────────────────────────────
class _Ring extends StatelessWidget {
  final double pct; // 0..1
  final double size;
  final Color color;
  final Color track;
  final Widget? center;
  const _Ring({required this.pct, this.size = 40, this.color = OC.o500, this.track = OC.line, this.center});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(size), painter: _RingPainter(pct.clamp(0.0, 1.0), color, track)),
        if (center != null) center!,
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color, track;
  _RingPainter(this.pct, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final bg = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track;
    final fg = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bg);
    if (pct > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.pct != pct || old.color != color || old.track != track;
}
