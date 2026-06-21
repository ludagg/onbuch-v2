import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

/// Détail d'une matière (refonte « Nomad Educ ») : bannière, onglets
/// Cours / Fiches / Quiz / Vidéos, et parcours de chapitres en timeline.
class ChaptersScreen extends StatefulWidget {
  final Subject? subject;
  const ChaptersScreen({super.key, this.subject});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final _db = DatabaseService();
  List<Chapter> _chapters = [];
  Set<String> _viewed = {};
  bool _loading = true;
  int _tab = 0;

  static const _tabs = ['Cours', 'Fiches', 'Quiz', 'Vidéos'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sub = widget.subject;
    if (sub == null) {
      setState(() => _loading = false);
      return;
    }
    final all = await _db.getChapters();
    final viewed = await _db.getViewedChapterIds();
    if (mounted) {
      setState(() {
        _chapters = all.where((c) => c.subjectId == sub.id).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        _viewed = viewed;
        _loading = false;
      });
    }
  }

  Color get _accent => widget.subject?.color ?? OC.o500;

  Future<void> _openLesson(Chapter c) async {
    await context.push('/cours-chapter', extra: {'chapter': c, 'subject': widget.subject?.name ?? ''});
    if (mounted) _load();
  }

  void _openQuiz(Chapter c) {
    context.push('/cours-quiz', extra: {'chapter': c, 'subject': widget.subject?.name ?? ''});
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject;
    return Scaffold(
      backgroundColor: OC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : CustomScrollView(slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 116,
                backgroundColor: _accent,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/cours'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [_accent, Color.lerp(_accent, Colors.black, 0.35)!],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: _accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Icon(sub?.icon ?? Icons.auto_stories_rounded, size: 25, color: _accent)),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sub?.name ?? 'Matière', style: display(20, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${_chapters.length} chapitre${_chapters.length > 1 ? 's' : ''}',
                            style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
                      ])),
                    ]),
                    const SizedBox(height: 18),
                    _tabBar(),
                    const SizedBox(height: 18),
                    if (_chapters.isEmpty)
                      _hint('Les chapitres de cette matière arrivent bientôt.')
                    else
                      _body(),
                  ]),
                ),
              ),
            ]),
    );
  }

  Widget _tabBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == _tab;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: on ? _accent : OC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? _accent : OC.line2, width: 1.5),
              ),
              child: Text(_tabs[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 1: // Fiches
        return Column(children: _chapters.map((c) => _row(c, Icons.description_outlined, 'Fiche de révision', () => _openLesson(c))).toList());
      case 2: // Quiz
        return Column(children: _chapters.map((c) => _row(c, Icons.quiz_outlined, 'QCM du chapitre', () => _openQuiz(c))).toList());
      case 3: // Vidéos
        final vids = _chapters.where((c) => c.videoUrl != null).toList();
        if (vids.isEmpty) return _hint('Aucune vidéo pour cette matière (pour l\'instant).');
        return Column(children: vids.map((c) => _row(c, Icons.play_circle_outline_rounded, 'Vidéo de cours', () => _openLesson(c))).toList());
      default: // Cours — timeline
        final current = _chapters.indexWhere((c) => !_viewed.contains(c.id));
        return Column(children: List.generate(_chapters.length, (i) {
          final c = _chapters[i];
          final status = _viewed.contains(c.id) ? 'done' : (i == current ? 'now' : 'todo');
          return _timelineRow(c, i, status, i == _chapters.length - 1);
        }));
    }
  }

  // ── Timeline (onglet Cours) ───────────────────────────────────────────────
  Widget _timelineRow(Chapter c, int i, String status, bool last) {
    final done = status == 'done';
    final now = status == 'now';
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: done ? _accent : (now ? _accent.withValues(alpha: 0.12) : OC.panel),
              shape: BoxShape.circle,
              border: Border.all(color: now ? _accent : (done ? _accent : OC.line2), width: 1.6),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : Text('${i + 1}', style: mono(12, weight: FontWeight.w700, color: now ? _accent : OC.ink2)),
            ),
          ),
          if (!last) Expanded(child: Container(width: 2, color: OC.line2, margin: const EdgeInsets.symmetric(vertical: 2))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _openLesson(c),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: now ? _accent.withValues(alpha: 0.5) : OC.line, width: 1.5),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ch. ${i + 1} — ${c.title}', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.2)),
                  const SizedBox(height: 3),
                  Text(_meta(c, done, now), style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
                ])),
                Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
              ]),
            ),
          ),
        )),
      ]),
    );
  }

  String _meta(Chapter c, bool done, bool now) {
    final bits = <String>[];
    if (done) {
      bits.add('Terminé');
    } else if (now) {
      bits.add('À continuer');
    }
    if (c.videoUrl != null) bits.add('vidéo');
    if (c.pdfUrl != null) bits.add('PDF');
    bits.add('quiz');
    return bits.join(' · ');
  }

  // ── Ligne simple (Fiches / Quiz / Vidéos) ─────────────────────────────────
  Widget _row(Chapter c, IconData icon, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: _accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 21, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          if (_viewed.contains(c.id)) const Icon(Icons.check_circle_rounded, size: 18, color: OC.good)
          else Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _hint(String t) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Icon(Icons.menu_book_rounded, size: 18, color: OC.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: body(13, color: OC.muted, weight: FontWeight.w500))),
        ]),
      );
}
