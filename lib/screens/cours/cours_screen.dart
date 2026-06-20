import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
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
                Column(children: const [
                  Skeleton(width: double.infinity, height: 80, radius: 20),
                  SizedBox(height: 20),
                  SkeletonList(count: 3),
                ])
              else if (_subjects.isEmpty)
                const EmptyState(
                  art: LeoMascot(size: 96, mood: LeoMood.wave),
                  icon: Icons.menu_book_rounded,
                  title: 'Bientôt disponible',
                  message: 'Les matières de ton programme arriveront ici.',
                )
              else ...[
                _progressStrip(totalCh, doneCh),
                const SizedBox(height: 20),
                ..._resumeBlock(),
                Text('Mes matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    for (var i = 0; i < _visible.length; i++)
                      Appear(index: i, child: _subjectCard(_visible[i], w)),
                  ],
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
        OBRing(pct: pct, size: 52, color: OC.o500, track: Colors.white24,
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
              child: Center(child: Icon(s.icon, size: 23, color: s.color)),
            ),
            const Spacer(),
            OBRing(
              pct: pct, size: 36,
              color: total == 0 ? OC.line2 : s.color,
              track: OC.line,
              center: total == 0
                  ? Text('–', style: mono(11, weight: FontWeight.w800, color: OC.muted))
                  : Text('${(pct * 100).round()}%', style: mono(9, weight: FontWeight.w800, color: s.color)),
            ),
          ]),
          const SizedBox(height: 11),
          // Hauteur fixe (2 lignes) pour que toutes les cartes s'alignent.
          SizedBox(
            height: 38,
            child: Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: body(14.5, weight: FontWeight.w700).copyWith(height: 1.15)),
          ),
          const SizedBox(height: 4),
          Text(total == 0 ? 'Bientôt disponible' : '$total chapitre${total > 1 ? 's' : ''}',
              style: body(12, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

}
