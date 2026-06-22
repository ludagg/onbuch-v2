import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

/// Fiche d'un « pack » (matière) : couverture, statistiques, progression du
/// programme et parcours des chapitres en timeline. Le bouton « Continuer »
/// ouvre le premier chapitre non vu.
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

  int get _done => _chapters.where((c) => _viewed.contains(c.id)).length;

  String? get _level {
    final lv = widget.subject?.levels ?? '';
    final parts = lv.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    return parts.isEmpty ? null : parts.first;
  }

  Future<void> _openLesson(Chapter c) async {
    await context.push('/cours-chapter', extra: {'chapter': c, 'subject': widget.subject?.name ?? ''});
    if (mounted) _load();
  }

  void _continue() {
    if (_chapters.isEmpty) return;
    final next = _chapters.firstWhere((c) => !_viewed.contains(c.id), orElse: () => _chapters.first);
    _openLesson(next);
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
                expandedHeight: 184,
                backgroundColor: _accent,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/cours'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: sub == null
                      ? ColoredBox(color: _accent)
                      : Stack(fit: StackFit.expand, children: [
                          PackCover(subject: sub, height: 184, hero: true, radius: BorderRadius.zero),
                          // Dégradé sombre en bas pour la lisibilité du titre.
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20, right: 20, bottom: 16,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(sub.name, style: display(22, weight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(_level != null ? '$_level · ${_chapters.length} chapitre${_chapters.length > 1 ? 's' : ''}'
                                      : '${_chapters.length} chapitre${_chapters.length > 1 ? 's' : ''}',
                                  style: body(12.5, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _stats(),
                    const SizedBox(height: 20),
                    if (_chapters.isEmpty)
                      _hint('Les chapitres de cette matière arrivent bientôt.')
                    else ...[
                      const SecHead(title: 'Programme du cours', action: null),
                      const SizedBox(height: 12),
                      _progress(),
                      const SizedBox(height: 18),
                      ...List.generate(_chapters.length, (i) {
                        final current = _chapters.indexWhere((c) => !_viewed.contains(c.id));
                        final c = _chapters[i];
                        final status = _viewed.contains(c.id) ? 'done' : (i == current ? 'now' : 'todo');
                        return _timelineRow(c, i, status, i == _chapters.length - 1);
                      }),
                    ],
                  ]),
                ),
              ),
            ]),
      bottomNavigationBar: (_loading || _chapters.isEmpty)
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: OBButton(
                  _done > 0 ? 'Continuer' : 'Commencer',
                  icon: Icons.play_arrow_rounded,
                  expand: true,
                  onTap: _continue,
                ),
              ),
            ),
    );
  }

  // ── Statistiques du pack ──────────────────────────────────────────────────
  Widget _stats() {
    final vids = _chapters.where((c) => c.videoUrl != null).length;
    final pdfs = _chapters.where((c) => c.pdfUrl != null).length;
    return Row(children: [
      _statPill(Icons.layers_rounded, '${_chapters.length}', 'chapitres'),
      const SizedBox(width: 10),
      _statPill(Icons.play_circle_outline_rounded, '$vids', 'vidéos'),
      const SizedBox(width: 10),
      _statPill(Icons.picture_as_pdf_rounded, '$pdfs', 'PDF'),
    ]);
  }

  Widget _statPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: _accent),
          const SizedBox(height: 6),
          Text(value, style: display(16, weight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(label, style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Progression du programme ──────────────────────────────────────────────
  Widget _progress() {
    final total = _chapters.length;
    final pct = total == 0 ? 0.0 : _done / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('$_done leçon${_done > 1 ? 's' : ''} terminée${_done > 1 ? 's' : ''} sur $total',
              style: body(12.5, weight: FontWeight.w700, color: OC.ink2))),
          Text('${(pct * 100).round()} %', style: mono(13, weight: FontWeight.w800, color: _accent)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: OC.line, valueColor: AlwaysStoppedAnimation(_accent)),
        ),
      ]),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────
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
