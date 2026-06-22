import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rich_answer.dart';
import '../../models/course.dart';
import '../../services/cours_packs_service.dart';
import '../../services/cours_offline_service.dart';
import '../../services/database_service.dart';

const _kTabs = ['Cours', 'Fiche', 'Exemples', 'Quiz'];

/// Lecteur de leçon (à l'intérieur d'un pack) — contenu réel des chapitres.
class LessonReaderScreen extends StatefulWidget {
  final String? subjectId;
  final int startIndex;
  const LessonReaderScreen({super.key, this.subjectId, this.startIndex = 0});

  @override
  State<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends State<LessonReaderScreen> {
  final _store = CoursPacks.instance;
  final _db = DatabaseService();
  int _i = 0;
  int _tab = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _i = widget.startIndex;
    _store.load();
    CoursOffline.instance.init();
  }

  // Modules navigables : tous si possédé, sinon seulement les aperçus gratuits.
  List<PackModule> _modules(Pack p) {
    final owned = _store.isOwned(p.id);
    return owned ? p.modules : p.modules.where((m) => m.free).toList();
  }

  void _view(PackModule m) => _db.markChapterViewed(m.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final p = _store.byId(widget.subjectId ?? '');
          if (p == null) {
            if (_store.loading) return const Center(child: CircularProgressIndicator(color: OC.o500));
            return Center(child: Text('Leçon indisponible.', style: body(14, color: OC.muted)));
          }
          final mods = _modules(p);
          if (mods.isEmpty) {
            return _scaffoldBody(p, null, 0, const SizedBox.shrink());
          }
          final i = _i.clamp(0, mods.length - 1);
          final m = mods[i];
          if (!_started) { _started = true; _view(m); }
          return _scaffoldBody(p, m, mods.length, _content(p, m));
        },
      ),
    );
  }

  Widget _scaffoldBody(Pack p, PackModule? m, int total, Widget content) {
    final i = total == 0 ? 0 : _i.clamp(0, total - 1);
    return Column(children: [
      AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m?.title ?? p.name, style: display(16, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Pack ${p.name} · ${total == 0 ? 0 : i + 1}/$total', style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
        actions: [IconButton(icon: Icon(Icons.star_border_rounded, color: OC.ink), onPressed: () {})],
      ),
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30)),
                const SizedBox(height: 8),
                Text('Vidéo de la leçon', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: List.generate(_kTabs.length, (t) {
            final active = _tab == t;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _tab = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: active ? OC.ink : OC.paper, borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: active ? OC.ink : OC.line, width: 1.5)),
                  child: Text(_kTabs[t], style: body(12.5, weight: FontWeight.w700, color: active ? Colors.white : OC.ink2)),
                ),
              ),
            );
          })),
          const SizedBox(height: 16),
          content,
        ],
      )),
      if (total > 0) _footer(p, total),
    ]);
  }

  Widget _content(Pack p, PackModule m) {
    switch (_tab) {
      case 1: // Fiche
        return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fiche de révision', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Le résumé condensé « 1 page » de ce chapitre.', style: body(13, color: OC.ink2).copyWith(height: 1.45)),
          const SizedBox(height: 14),
          _grad('Ouvrir la fiche', () => context.push('/cours/fiche?id=${m.id}&t=${Uri.encodeComponent(m.title)}')),
        ]));
      case 2: // Exemples
        return _card(Column(children: [
          Icon(Icons.lightbulb_outline_rounded, size: 30, color: OC.o500),
          const SizedBox(height: 8),
          Text('Exemples', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Les exemples corrigés de ce chapitre arriveront ici.', textAlign: TextAlign.center, style: body(12.5, color: OC.muted)),
        ]));
      case 3: // Quiz — moteur QCM réel
        return _card(Column(children: [
          Icon(Icons.quiz_rounded, size: 36, color: OC.o500),
          const SizedBox(height: 10),
          Text('Quiz du chapitre', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Vérifie que c\'est acquis.', textAlign: TextAlign.center, style: body(12.5, color: OC.muted)),
          const SizedBox(height: 14),
          _grad('Lancer le quiz', () => context.push('/cours-quiz', extra: {
            'chapter': Chapter(id: m.id, subjectId: p.id, title: m.title),
            'subject': p.name,
          })),
        ]));
      default: // Cours — contenu réel (cache hors-ligne prioritaire)
        final cached = CoursOffline.instance.offlineLesson(p.id, m.id);
        if (cached != null && cached.trim().isNotEmpty) {
          return RichAnswer(cached);
        }
        return FutureBuilder<String?>(
          future: _db.getLesson(m.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final _ in [0, 1, 2, 3])
                  Container(height: 11, width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(6))),
              ]);
            }
            final content = (snap.data ?? '').trim();
            if (content.isEmpty) {
              return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.menu_book_rounded, size: 28, color: OC.faint),
                const SizedBox(height: 8),
                Text('Cours bientôt disponible', style: body(13.5, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Le contenu de ce chapitre sera ajouté prochainement.', style: body(12.5, color: OC.muted)),
              ]));
            }
            return RichAnswer(content);
          },
        );
    }
  }

  Widget _card(Widget child) => Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: child,
      );

  Widget _grad(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(height: 46, width: double.infinity,
            decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
            child: Text(label, style: body(13.5, weight: FontWeight.w700, color: Colors.white))),
      );

  Widget _footer(Pack p, int total) {
    final hasNext = _i < total - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
      child: Row(children: [
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Leçon disponible hors-ligne ✓', style: body(13, weight: FontWeight.w600, color: Colors.white)),
            backgroundColor: OC.good, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )),
          child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: OC.line, width: 1.5)),
            child: Row(children: [Icon(Icons.download_rounded, size: 17, color: OC.ink), const SizedBox(width: 6), Text('Hors-ligne', style: body(12.5, weight: FontWeight.w700))]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: hasNext ? () => setState(() { _i++; _tab = 0; _started = false; }) : () => context.pop(),
          child: Container(height: 50, decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)), alignment: Alignment.center,
              child: Text(hasNext ? 'Leçon suivante →' : 'Terminer ✓', style: body(14, weight: FontWeight.w700, color: Colors.white))),
        )),
      ]),
    );
  }
}
