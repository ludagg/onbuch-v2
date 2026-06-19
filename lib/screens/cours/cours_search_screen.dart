import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

/// Recherche transverse dans les cours (section F) : leçons, vidéos et quiz,
/// filtrable par type.
class CoursSearchScreen extends StatefulWidget {
  const CoursSearchScreen({super.key});

  @override
  State<CoursSearchScreen> createState() => _CoursSearchScreenState();
}

class _CoursSearchScreenState extends State<CoursSearchScreen> {
  final _db = DatabaseService();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  Map<String, Subject> _subjectById = {};
  List<Chapter> _chapters = [];
  bool _loading = true;
  String _query = '';
  int _type = 0; // 0 Tout, 1 Cours, 2 Vidéos, 3 Quiz

  static const _types = ['Tout', 'Cours', 'Vidéos', 'Quiz'];

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final subjects = await _db.getSubjects();
    final chapters = await _db.getChapters();
    if (!mounted) return;
    setState(() {
      _subjectById = {for (final s in subjects) s.id: s};
      _chapters = chapters;
      _loading = false;
    });
  }

  List<_Result> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <_Result>[];
    for (final c in _chapters) {
      final sub = _subjectById[c.subjectId];
      final hay = '${c.title} ${sub?.name ?? ''}'.toLowerCase();
      if (!hay.contains(q)) continue;
      final subName = sub?.name ?? '';
      final color = sub?.color ?? OC.o500;
      if (_type == 0 || _type == 1) {
        out.add(_Result(c.title, '$subName · leçon', _ResType.cours, c, subName, color));
      }
      if ((_type == 0 || _type == 2) && c.videoUrl != null) {
        out.add(_Result(c.title, '$subName · vidéo', _ResType.video, c, subName, color));
      }
      if (_type == 0 || _type == 3) {
        out.add(_Result('QCM — ${c.title}', '$subName · quiz', _ResType.quiz, c, subName, color));
      }
    }
    return out;
  }

  void _open(_Result r) {
    if (r.type == _ResType.quiz) {
      context.push('/cours-quiz', extra: {'chapter': r.chapter, 'subject': r.subjectName});
    } else {
      context.push('/cours-chapter', extra: {'chapter': r.chapter, 'subject': r.subjectName});
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.canPop() ? context.pop() : context.go('/cours'),
              ),
              Expanded(child: Container(
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.ink, width: 1.6)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  const Icon(Icons.search_rounded, size: 18, color: OC.ink2),
                  const SizedBox(width: 9),
                  Expanded(child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    style: body(14, color: OC.ink),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Un cours, une notion…',
                      hintStyle: body(14, color: OC.muted),
                    ),
                  )),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() { _ctrl.clear(); _query = ''; }),
                      child: const Icon(Icons.close_rounded, size: 18, color: OC.muted),
                    ),
                ]),
              )),
            ]),
          ),
          // Filtres
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final on = i == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = i),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: on ? OC.ink : OC.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: on ? OC.ink : OC.line2, width: 1.5),
                    ),
                    child: Text(_types[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: OC.o500))
              : _query.trim().isEmpty
                  ? _placeholder('Tape pour chercher un cours, une vidéo ou un quiz.')
                  : results.isEmpty
                      ? _placeholder('Aucun résultat pour « $_query ».')
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                          children: [
                            Text('${results.length} résultat${results.length > 1 ? 's' : ''}',
                                style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            ...results.map(_resultRow),
                          ],
                        )),
        ]),
      ),
    );
  }

  Widget _resultRow(_Result r) {
    final (icon, c) = switch (r.type) {
      _ResType.video => (Icons.play_circle_outline_rounded, const Color(0xFF7A5AE0)),
      _ResType.quiz => (Icons.quiz_outlined, OC.blue),
      _ => (Icons.menu_book_rounded, r.color),
    };
    return GestureDetector(
      onTap: () => _open(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 21, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(r.subtitle, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _placeholder(String t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_rounded, size: 40, color: OC.faint),
            const SizedBox(height: 12),
            Text(t, textAlign: TextAlign.center, style: body(13.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.4)),
          ]),
        ),
      );
}

enum _ResType { cours, video, quiz }

class _Result {
  final String title, subtitle;
  final _ResType type;
  final Chapter chapter;
  final String subjectName;
  final Color color;
  const _Result(this.title, this.subtitle, this.type, this.chapter, this.subjectName, this.color);
}
