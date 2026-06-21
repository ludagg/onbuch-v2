import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/article.dart';
import '../../models/course.dart';
import '../../models/concours.dart';
import '../../services/database_service.dart';

/// Recherche globale transverse : actualités, cours et concours.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

enum _Kind { cours, actu, concours }

class _Hit {
  final String title, subtitle;
  final _Kind kind;
  final Object payload; // Chapter / Article / Concours
  final String? subjectName;
  const _Hit(this.title, this.subtitle, this.kind, this.payload, {this.subjectName});
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _db = DatabaseService();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  List<Article> _articles = [];
  List<Concours> _concours = [];
  Map<String, Subject> _subjectById = {};
  List<Chapter> _chapters = [];
  bool _loading = true;
  String _query = '';
  int _filter = 0; // 0 Tout, 1 Cours, 2 Actus, 3 Concours

  static const _filters = ['Tout', 'Cours', 'Actus', 'Concours'];

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
    final results = await Future.wait([
      _db.getArticles(limit: 60),
      _db.getSubjects(),
      _db.getChapters(),
      _db.getConcours(),
    ]);
    if (!mounted) return;
    setState(() {
      _articles = results[0] as List<Article>;
      _subjectById = {for (final s in results[1] as List<Subject>) s.id: s};
      _chapters = results[2] as List<Chapter>;
      _concours = results[3] as List<Concours>;
      _loading = false;
    });
  }

  List<_Hit> get _hits {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <_Hit>[];
    if (_filter == 0 || _filter == 1) {
      for (final c in _chapters) {
        final sub = _subjectById[c.subjectId];
        if ('${c.title} ${sub?.name ?? ''}'.toLowerCase().contains(q)) {
          out.add(_Hit(c.title, '${sub?.name ?? 'Cours'} · leçon', _Kind.cours, c, subjectName: sub?.name ?? ''));
        }
      }
    }
    if (_filter == 0 || _filter == 2) {
      for (final a in _articles) {
        if ('${a.title} ${a.category}'.toLowerCase().contains(q)) {
          out.add(_Hit(a.title, '${a.category} · actualité', _Kind.actu, a));
        }
      }
    }
    if (_filter == 0 || _filter == 3) {
      for (final c in _concours) {
        if ('${c.name} ${c.organizer}'.toLowerCase().contains(q)) {
          out.add(_Hit(c.name, '${c.organizer.isEmpty ? 'Concours' : c.organizer} · concours', _Kind.concours, c));
        }
      }
    }
    return out;
  }

  void _open(_Hit h) {
    switch (h.kind) {
      case _Kind.cours:
        context.push('/cours-chapter', extra: {'chapter': h.payload as Chapter, 'subject': h.subjectName ?? ''});
        break;
      case _Kind.actu:
        context.push('/article', extra: h.payload as Article);
        break;
      case _Kind.concours:
        context.push('/concours-detail', extra: h.payload as Concours);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              ),
              Expanded(child: Container(
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.ink, width: 1.6)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(Icons.search_rounded, size: 18, color: OC.ink2),
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
                      hintText: 'Cours, actu, concours…',
                      hintStyle: body(14, color: OC.muted),
                    ),
                  )),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() { _ctrl.clear(); _query = ''; }),
                      child: Icon(Icons.close_rounded, size: 18, color: OC.muted),
                    ),
                ]),
              )),
            ]),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final on = i == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = i),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: on ? OC.ink : OC.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: on ? OC.ink : OC.line2, width: 1.5),
                    ),
                    child: Text(_filters[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: OC.o500))
              : _query.trim().isEmpty
                  ? const EmptyState(
                      art: LeoMascot(size: 104, mood: LeoMood.wave),
                      icon: Icons.search_rounded,
                      title: 'Cherche dans OnBuch',
                      message: 'Cours, actualités, concours — tout au même endroit.',
                    )
                  : hits.isEmpty
                      ? EmptyState(icon: Icons.search_off_rounded, title: 'Aucun résultat', message: 'Rien pour « $_query ».')
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                          children: [
                            Text('${hits.length} résultat${hits.length > 1 ? 's' : ''}', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            for (var i = 0; i < hits.length; i++) Appear(index: i, child: _hitRow(hits[i])),
                          ],
                        )),
        ]),
      ),
    );
  }

  Widget _hitRow(_Hit h) {
    final (icon, c) = switch (h.kind) {
      _Kind.actu => (Icons.article_outlined, OC.blue),
      _Kind.concours => (Icons.track_changes_rounded, const Color(0xFF0E9AA0)),
      _Kind.cours => (Icons.menu_book_rounded, OC.o600),
    };
    return GestureDetector(
      onTap: () => _open(h),
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
            Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(h.subtitle, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}
