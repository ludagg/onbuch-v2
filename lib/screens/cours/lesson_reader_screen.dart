import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rich_answer.dart';
import '../../utils/launch.dart';
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
          _LessonVideo(url: m?.videoUrl, query: m == null ? null : '${m.title} ${p.name} cours'),
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
        final cachedEx = CoursOffline.instance.offlineLesson(p.id, m.id);
        if (cachedEx != null && cachedEx.trim().isNotEmpty) {
          final ex = _examplesFrom(cachedEx);
          return ex == null ? _noExamples() : RichAnswer(ex);
        }
        return FutureBuilder<String?>(
          future: _db.getLesson(m.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _loadingBars();
            final ex = _examplesFrom((snap.data ?? '').trim());
            return ex == null ? _noExamples() : RichAnswer(ex);
          },
        );
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

  /// Extrait la section « exercices corrigés / exemples » d'une leçon Markdown
  /// (de son titre jusqu'au prochain « À retenir »), pour alimenter l'onglet
  /// Exemples sans dupliquer les données. `null` si la leçon n'en contient pas.
  String? _examplesFrom(String md) {
    if (md.trim().isEmpty) return null;
    final lines = md.split('\n');
    final heading = RegExp(r'^#{1,4}\s+(.*)$');
    final startKey = RegExp(r'exerc|corrig|worked|practice|cas pratique|exemple r|sujet', caseSensitive: false);
    final stopKey = RegExp(r'retenir|key point|repères et chiffres', caseSensitive: false);
    int start = -1;
    for (var i = 0; i < lines.length; i++) {
      final h = heading.firstMatch(lines[i]);
      if (h != null && startKey.hasMatch(h.group(1) ?? '')) { start = i; break; }
    }
    if (start < 0) return null;
    int end = lines.length;
    for (var i = start + 1; i < lines.length; i++) {
      final h = heading.firstMatch(lines[i]);
      if (h != null && stopKey.hasMatch(h.group(1) ?? '')) { end = i; break; }
    }
    final out = lines.sublist(start, end).join('\n').trim();
    return out.isEmpty ? null : out;
  }

  Widget _loadingBars() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final _ in [0, 1, 2, 3])
          Container(height: 11, width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(6))),
      ]);

  Widget _noExamples() => _card(Column(children: [
        Icon(Icons.lightbulb_outline_rounded, size: 28, color: OC.faint),
        const SizedBox(height: 8),
        Text('Exemples dans le cours', style: body(13.5, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Les exercices corrigés de ce chapitre sont intégrés à l\'onglet « Cours ».',
            textAlign: TextAlign.center, style: body(12.5, color: OC.muted)),
      ]));

  Widget _grad(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(height: 46, width: double.infinity,
            decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
            child: Text(label, style: body(13.5, weight: FontWeight.w700, color: Colors.white))),
      );

  // (lecteur vidéo extrait en _LessonVideo ci-dessous)

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

/// Lecteur vidéo **intégré** (inline) de la leçon. Affiche la vidéo YouTube du
/// chapitre via `youtube_player_iframe` ; emplacement « bientôt disponible » si
/// aucune vidéo (ou lien non reconnu). Recrée le contrôleur si l'URL change.
class _LessonVideo extends StatefulWidget {
  final String? url;
  final String? query; // recherche YouTube de repli (si pas de vidéo embarquée)
  const _LessonVideo({this.url, this.query});

  @override
  State<_LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<_LessonVideo> {
  YoutubePlayerController? _yt;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final url = (widget.url ?? '').trim();
    if (url.isEmpty) return;
    final id = YoutubePlayerController.convertUrlToId(url);
    if (id != null) {
      _yt = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _LessonVideo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _yt?.close();
      _yt = null;
      _setup();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_yt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: 16 / 9, child: YoutubePlayer(controller: _yt!)),
      );
    }
    // Aucune vidéo embarquée : repli vers une recherche YouTube du chapitre.
    final q = (widget.query ?? '').trim();
    return GestureDetector(
      onTap: q.isEmpty ? null : () => openUrl(context, 'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(q)}'),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(color: Color(0xFFC0392B), shape: BoxShape.circle),
              child: const Icon(Icons.smart_display_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(q.isEmpty ? 'Vidéo bientôt disponible' : 'Voir des vidéos sur YouTube',
                style: body(12.5, color: OC.ink2, weight: FontWeight.w700)),
            if (q.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Recherche du chapitre', style: body(10.5, color: OC.muted, weight: FontWeight.w500)),
            ],
          ]),
        ),
      ),
    );
  }
}
