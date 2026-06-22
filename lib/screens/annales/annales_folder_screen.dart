import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../data/exam_taxonomy.dart';
import '../../models/annale.dart';
import '../../services/database_service.dart';

/// Navigation des annales dans la taxonomie (profondeur variable).
/// - Niveau de SUBDIVISIONS (ex. Bac → ESG / STT / Industriel) → liste de dossiers.
/// - Niveau TERMINAL (séries / matières) → page « bibliothèque » alimentée par la
///   collection `annales` : filtres années + grille matières + récemment ajoutés.
class AnnalesFolderScreen extends StatefulWidget {
  final String folderName;
  final ExamNode? node;
  final String examRoot; // examen de tête (clé de la collection `annales`)
  const AnnalesFolderScreen({
    super.key,
    required this.folderName,
    this.node,
    this.examRoot = '',
  });

  @override
  State<AnnalesFolderScreen> createState() => _AnnalesFolderScreenState();
}

class _AnnalesFolderScreenState extends State<AnnalesFolderScreen> {
  final _db = DatabaseService();
  int _yearIdx = 0; // 0 = « Toutes »
  bool _loading = true;
  List<Annale> _all = const []; // annales de l'examen de tête

  ExamNode? get _node => widget.node ?? examTaxonomy[widget.folderName];
  String get _exam => widget.examRoot.isNotEmpty ? widget.examRoot : widget.folderName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getAnnales(_exam);
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  bool get _isGroupLevel {
    final n = _node;
    if (n == null || n.children.isEmpty) return false;
    return n.children.any((c) => !c.isLeaf || c.code.isNotEmpty || c.subjects.isNotEmpty);
  }

  // Matières/spécialités terminales (feuilles SANS code) → grille de dossiers.
  List<ExamNode> get _items =>
      _node?.children.where((c) => c.isLeaf && c.code.isEmpty).toList() ?? const [];

  // Libellé de série/spécialité à enregistrer comme `track` (vide à la racine).
  String _trackOf(ExamNode n) => n.label == _exam ? '' : n.label;

  // Documents de la série courante (filtrés par track + année sélectionnée).
  List<Annale> _docsFor(String track) {
    final year = _selectedYear;
    return _all.where((a) {
      if (track.isNotEmpty && a.track != track) return false;
      if (year.isNotEmpty && a.year != year) return false;
      return true;
    }).toList();
  }

  // Années réellement disponibles pour la série courante.
  List<String> _yearsFor(String track) {
    final s = <String>{};
    for (final a in _all) {
      if (track.isNotEmpty && a.track != track) continue;
      if (a.year.isNotEmpty) s.add(a.year);
    }
    final list = s.toList()..sort((x, y) => y.compareTo(x));
    return list;
  }

  List<String> _yearOptions = const ['Toutes'];
  String get _selectedYear =>
      (_yearIdx <= 0 || _yearIdx >= _yearOptions.length) ? '' : _yearOptions[_yearIdx];

  @override
  Widget build(BuildContext context) {
    final n = _node;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text(n?.label ?? widget.folderName, style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
        ),
      ),
      body: n == null
          ? Center(child: Text('Catégorie inconnue.', style: body(14, color: OC.muted)))
          : (_isGroupLevel ? _drillList(context, n) : _library(context, n)),
    );
  }

  // ── Niveau subdivisions : liste de dossiers ───────────────────────────────
  Widget _drillList(BuildContext context, ExamNode n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        if (n.note != null) ...[
          Text(n.note!, style: body(13, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 14),
        ],
        Text(n.children.length > 1 ? '${n.children.length} rubriques' : '1 rubrique',
            style: body(12.5, color: OC.muted, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final child in n.children)
          Builder(builder: (context) {
            final count = child.children.isNotEmpty ? child.children.length : child.subjects.length;
            final unit = child.children.isNotEmpty ? 'élément' : 'matière';
            return GestureDetector(
              onTap: () => context.push(
                '/annales/folder/${Uri.encodeComponent(child.label)}?exam=${Uri.encodeComponent(_exam)}',
                extra: child,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.folder_rounded, size: 21, color: OC.o600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(child.label, style: body(13.5, weight: FontWeight.w700)),
                    if (count > 0) ...[
                      const SizedBox(height: 2),
                      Text('$count $unit${count > 1 ? 's' : ''}',
                          style: body(11, color: OC.muted, weight: FontWeight.w600)),
                    ],
                  ])),
                  Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
                ]),
              ),
            );
          }),
      ],
    );
  }

  // ── Niveau terminal : page « bibliothèque » ───────────────────────────────
  Widget _library(BuildContext context, ExamNode n) {
    final track = _trackOf(n);
    _yearOptions = ['Toutes', ..._yearsFor(track)];
    if (_yearIdx >= _yearOptions.length) _yearIdx = 0;

    // Source des matières : matières de série, sinon spécialités-feuilles.
    final useSubjects = n.subjects.isNotEmpty;
    final subjectNames = useSubjects
        ? n.subjects
        : _items.isNotEmpty
            ? _items.map((it) => it.label).toList()
            : _subjectsFromData(track); // repli : matières présentes dans les données

    final docs = _docsFor(track);

    return RefreshIndicator(
      onRefresh: () async {
        DatabaseService.clearCache();
        await _load();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Fil d'Ariane
          Row(children: [
            Text('Bibliothèque', style: body(12, color: OC.muted, weight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, size: 13, color: OC.faint),
            Flexible(child: Text(n.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(12, weight: FontWeight.w600, color: OC.ink))),
          ]),
          const SizedBox(height: 14),

          // Filtres années (réels)
          if (_yearOptions.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < _yearOptions.length; i++) ...[
                  GestureDetector(
                    onTap: () => setState(() => _yearIdx = i),
                    child: OBChip(_yearOptions[i], active: i == _yearIdx),
                  ),
                  if (i < _yearOptions.length - 1) const SizedBox(width: 9),
                ],
              ]),
            ),
            const SizedBox(height: 18),
          ],

          // Grille matières
          Text('Matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()))
          else if (subjectNames.isEmpty)
            _emptyHint('Aucune matière pour le moment.')
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: subjectNames
                  .map((s) => _subjectTile(context, s, track, _countFor(track, s)))
                  .toList(),
            ),
          const SizedBox(height: 18),

          // Récemment ajoutés (réels)
          if (!_loading && docs.isNotEmpty) ...[
            Text('Récemment ajoutés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 11),
            ..._recentGroups(track).map((g) => _recentTile(context, g, track)),
          ],
        ]),
      ),
    );
  }

  // Matières distinctes présentes dans les données (repli quand la taxonomie
  // n'a pas de liste de matières).
  List<String> _subjectsFromData(String track) {
    final s = <String>{};
    for (final a in _all) {
      if (track.isNotEmpty && a.track != track) continue;
      if (a.subject.isNotEmpty) s.add(a.subject);
    }
    final list = s.toList()..sort();
    return list;
  }

  // Nombre d'épreuves (groupes matière+année) pour une matière donnée.
  int _countFor(String track, String subject) {
    final years = <String>{};
    for (final a in _all) {
      if (track.isNotEmpty && a.track != track) continue;
      if (a.subject != subject) continue;
      if (_selectedYear.isNotEmpty && a.year != _selectedYear) continue;
      years.add(a.year);
    }
    return years.where((y) => y.isNotEmpty).length;
  }

  // Groupes (matière, année) récents pour la section « Récemment ajoutés ».
  List<_Group> _recentGroups(String track) {
    final map = <String, _Group>{};
    for (final a in _docsFor(track)) {
      final key = '${a.subject}|${a.year}';
      final g = map.putIfAbsent(key, () => _Group(a.subject, a.year));
      if (a.isSujet) g.hasSujet = true;
      if (a.isCorrige) g.hasCorrige = true;
      if (a.isVideo) g.hasVideo = true;
      if (a.premium) g.premium = true;
    }
    final list = map.values.toList()
      ..sort((x, y) => y.year.compareTo(x.year));
    return list.take(6).toList();
  }

  Widget _subjectTile(BuildContext context, String name, String track, int count) {
    return GestureDetector(
      onTap: () => _openSubject(context, name, track),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          SubjLogo(name, size: 36),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(count > 0 ? '$count épreuve${count > 1 ? 's' : ''}' : 'épreuves bientôt',
                style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
        ]),
      ),
    );
  }

  Widget _recentTile(BuildContext context, _Group g, String track) {
    final types = <String>[
      if (g.hasSujet) 'pdf',
      if (g.hasCorrige) 'corrige',
      if (g.hasVideo) 'video',
    ];
    return GestureDetector(
      onTap: () => _openSubject(context, g.subject, track, year: g.year),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          SubjLogo(g.subject, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.year.isEmpty ? g.subject : '${g.subject} · ${g.year}',
                style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 5),
            Row(children: types.map((t) => Padding(padding: const EdgeInsets.only(right: 5), child: _TypePill(t))).toList()),
          ])),
          g.premium
              ? PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD), icon: Icons.lock_outline_rounded)
              : PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
        ]),
      ),
    );
  }

  void _openSubject(BuildContext context, String subject, String track, {String? year}) {
    context.push('/annales/detail', extra: AnnaleRef(
      exam: _exam,
      track: track,
      subject: subject,
      year: year ?? _selectedYear,
      title: '$subject · $_exam',
    ));
  }

  Widget _emptyHint(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Text(msg, style: body(13, color: OC.muted, weight: FontWeight.w600)),
      );
}

class _Group {
  final String subject;
  final String year;
  bool hasSujet = false, hasCorrige = false, hasVideo = false, premium = false;
  _Group(this.subject, this.year);
}

class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill(this.type);

  @override
  Widget build(BuildContext context) {
    const map = {
      'pdf': ('PDF', Color(0xFFC0392B), Color(0xFFFAE7E4)),
      'video': ('Vidéo', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
      'corrige': ('Corrigé', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
    };
    final m = map[type] ?? map['pdf']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: m.$3, borderRadius: BorderRadius.circular(7)),
      child: Text(m.$1, style: body(10, weight: FontWeight.w800, color: m.$2)),
    );
  }
}
