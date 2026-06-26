import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../data/exam_taxonomy.dart';
import '../../services/cours_packs_service.dart';
import '../../services/database_service.dart';
import '../../models/annale.dart';
import '../../models/fascicule.dart';

/// Séries ESG retenues pour le Bac / Probatoire (libellé court → code).
/// « A » est une série unique qui regroupe toutes les sous-séries A.
const _esgSeries = [
  ('A', 'A — Littéraire'),
  ('C', 'C — Maths & Sciences physiques'),
  ('D', 'D — Maths & Sciences de la vie'),
  ('TI', 'TI — Technologies de l\'Information'),
  ('E', 'E — Maths & Techniques'),
];

/// Têtes de track rattachées à l'ESG (le compteur/zone considère « A » comme
/// couvrant A1..A5 et ABI). Correspondance exacte sur la tête du track.
const _esgHeads = {'a', 'a1', 'a2', 'a3', 'a4', 'a5', 'abi', 'c', 'd', 'e', 'ti'};

/// Nœud ESG (Bac / Probatoire) limité aux séries A · C · D · TI · E.
ExamNode _esgNode(String label) => ExamNode(
      label,
      children: [for (final s in _esgSeries) ExamNode(s.$2, code: s.$1)],
    );

/// Les 3 examens proposés dans les Cours : BEPC, Bac ESG, Probatoire ESG.
/// `node` = nœud de taxonomie à ouvrir (null → BEPC, pris dans la taxonomie).
class _CoursExam {
  final String name; // libellé carte
  final String exam; // clé examen racine
  final ExamNode? node; // nœud custom (drill ESG)
  final Color c, bg;
  const _CoursExam(this.name, this.exam, this.node, this.c, this.bg);
}

/// Accueil du module Cours — calque de la page Annales : recherche, accès
/// rapides (Mes cours · Panier · Catalogue), grille « Parcourir par examen »
/// (limitée à BEPC · Bac ESG · Probatoire ESG) puis une zone « Tous les cours »
/// qui liste directement les packs de ces examens, triés.
class CoursLibraryHomeScreen extends StatefulWidget {
  const CoursLibraryHomeScreen({super.key});

  @override
  State<CoursLibraryHomeScreen> createState() => _CoursLibraryHomeScreenState();
}

class _CoursLibraryHomeScreenState extends State<CoursLibraryHomeScreen> {
  final _packs = CoursPacks.instance;

  late final List<_CoursExam> _exams = [
    _CoursExam('BEPC', 'BEPC', null, const Color(0xFF1E9E63), const Color(0xFFE5F3EB)),
    _CoursExam('Bac ESG', 'Baccalauréat', _esgNode('Baccalauréat ESG'),
        const Color(0xFFDB4F12), const Color(0xFFFDEBE2)),
    _CoursExam('Probatoire ESG', 'Probatoire', _esgNode('Probatoire ESG'),
        const Color(0xFF2D6CDF), const Color(0xFFE7EEFB)),
  ];

  // Packs regroupés par examen (libellé carte → packs triés par nom).
  Map<String, List<Pack>> _byExam = const {};
  // Cours PDF (course_docs) regroupés par examen, dans l'ordre d'affichage.
  List<MapEntry<String, List<Annale>>> _coursePdf = const [];
  // Fascicules (livres OnBuch) pour la vitrine « Nos fascicules ».
  List<Fascicule> _fascicules = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _packs.load();
    final bepc = await _packs.packsForExam('BEPC');
    final bac = await _packs.packsForExamSeries('Baccalauréat', _esgHeads);
    final prob = await _packs.packsForExamSeries('Probatoire', _esgHeads);
    final docs = await DatabaseService().getCourseDocs();
    final fasc = await DatabaseService().getFascicules();
    int byName(Pack a, Pack b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
    final map = {
      'BEPC': bepc..sort(byName),
      'Bac ESG': bac..sort(byName),
      'Probatoire ESG': prob..sort(byName),
    };
    if (mounted) setState(() { _byExam = map; _coursePdf = _groupCoursePdf(docs); _fascicules = fasc; _loaded = true; });
  }

  /// Regroupe les cours PDF par examen (ordre Bac → Probatoire → BEPC → … →
  /// reste alpha), triés par matière puis titre à l'intérieur.
  static List<MapEntry<String, List<Annale>>> _groupCoursePdf(List<Annale> docs) {
    const order = ['Baccalauréat', 'Probatoire', 'BEPC', 'CAP', 'BT', 'BTS', 'HND'];
    final map = <String, List<Annale>>{};
    for (final d in docs) {
      final e = d.exam.trim().isEmpty ? 'Autres' : d.exam.trim();
      (map[e] ??= []).add(d);
    }
    int subjThenTitle(Annale a, Annale b) {
      final s = a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
      return s != 0 ? s : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        if (ia != -1 || ib != -1) return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [for (final k in keys) MapEntry(k, map[k]!..sort(subjThenTitle))];
  }

  // Couleur d'accent par examen pour les en-têtes « Cours PDF ».
  static Color _examColor(String exam) {
    switch (exam) {
      case 'Baccalauréat':
        return const Color(0xFFDB4F12);
      case 'Probatoire':
        return const Color(0xFF2D6CDF);
      case 'BEPC':
        return const Color(0xFF1E9E63);
      case 'CAP':
        return const Color(0xFF0E9AA0);
      default:
        return const Color(0xFF7A5AE0);
    }
  }

  int _countFor(String name) => _byExam[name]?.length ?? 0;

  void _openExam(_CoursExam e) {
    if (e.node == null) {
      context.push('/cours/folder/${Uri.encodeComponent(e.name)}');
    } else {
      context.push(
        '/cours/folder/${Uri.encodeComponent(e.node!.label)}?exam=${Uri.encodeComponent(e.exam)}',
        extra: e.node,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const OBWordmark(size: 23),
        actions: obTopActions(context),
      ),
      body: RefreshIndicator(
        color: OC.o500,
        onRefresh: () => _load(),
        child: ListenableBuilder(
          listenable: _packs,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
            children: [
              // Recherche → recherche transverse Cours
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.push('/cours-search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.05), blurRadius: 5)],
                    ),
                    child: Row(children: [
                      Icon(Icons.search_rounded, size: 20, color: OC.muted),
                      const SizedBox(width: 11),
                      Expanded(child: Text('Matière, pack, leçon…', style: body(14.5, color: OC.muted, weight: FontWeight.w500))),
                      const Icon(Icons.tune_rounded, size: 19, color: OC.o500),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Accès rapides : Mes cours · Panier · Catalogue
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _QuickCard(Icons.auto_stories_rounded, 'Mes cours', _loaded ? '${_packs.library.length}' : '…', OC.waInk, OC.goodBg,
                      () async { await context.push('/cours/bibliotheque'); _load(); }),
                  const SizedBox(width: 11),
                  _QuickCard(Icons.shopping_bag_outlined, 'Panier', _loaded ? '${_packs.cart.length}' : '…', OC.blue, OC.blueBg,
                      () async { await context.push('/cours/panier'); _load(); }),
                  const SizedBox(width: 11),
                  _QuickCard(Icons.grid_view_rounded, 'Catalogue', _loaded ? '${_packs.catalogue.length}' : '…', const Color(0xFFA6701A), const Color(0xFFFBF0DD),
                      () async { await context.push('/cours/catalogue'); _load(); }),
                ]),
              ),
              const SizedBox(height: 18),

              // ── Vitrine éditoriale « Nos fascicules » (couvertures en éventail) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FasciculesShowcase(_fascicules),
              ),
              const SizedBox(height: 22),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Parcourir par examen', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: _exams.map((e) => _FolderCard(
                    name: e.name,
                    count: _countFor(e.name),
                    loaded: _loaded,
                    c: e.c,
                    bg: e.bg,
                    onTap: () => _openExam(e),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 22),

              // ── Zone dédiée : Cours en PDF (collectés depuis la base) ───────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text('Cours PDF', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                  const SizedBox(width: 8),
                  if (_loaded)
                    Text('${_coursePdf.fold<int>(0, (n, e) => n + e.value.length)}',
                        style: body(12, weight: FontWeight.w700, color: OC.muted)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/search?scope=annales'),
                    child: Text('Rechercher', style: body(12, weight: FontWeight.w700, color: OC.o600)),
                  ),
                ]),
              ),
              const SizedBox(height: 11),
              if (!_loaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: List.generate(4, (_) => const SkeletonRow())),
                )
              else if (_coursePdf.isEmpty)
                _emptyCoursePdf()
              else
                ..._coursePdf.expand((g) => [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                        child: Row(children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(color: _examColor(g.key), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(g.key, style: body(12.5, weight: FontWeight.w800, color: OC.ink)),
                          const SizedBox(width: 6),
                          Text('· ${g.value.length}', style: body(12, weight: FontWeight.w600, color: OC.muted)),
                        ]),
                      ),
                      for (final d in g.value)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _CourseDocRow(
                            doc: d,
                            onTap: () => context.push('/annales/detail', extra: d),
                          ),
                        ),
                      const SizedBox(height: 6),
                    ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCoursePdf() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(children: [
          Icon(Icons.picture_as_pdf_rounded, size: 44, color: OC.faint),
          const SizedBox(height: 12),
          Text('Aucun cours PDF pour le moment', style: display(17, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Les cours en PDF apparaîtront ici dès qu\'ils seront collectés et publiés.',
              textAlign: TextAlign.center, style: body(13, color: OC.muted).copyWith(height: 1.4)),
        ]),
      );
}

/// Ligne d'un cours en PDF (section « Cours PDF »). Ouvre la fiche du document.
class _CourseDocRow extends StatelessWidget {
  final Annale doc;
  final VoidCallback onTap;
  const _CourseDocRow({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = doc;
    final sub = [d.subject, d.track, if (d.year.isNotEmpty) d.year]
        .where((e) => e.trim().isNotEmpty)
        .join(' · ');
    final (icon, c) = d.hasVideo && !d.hasPdf
        ? (Icons.play_circle_outline_rounded, const Color(0xFF7A5AE0))
        : (Icons.picture_as_pdf_rounded, const Color(0xFFC0392B));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 21, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title.isEmpty ? (d.subject.isEmpty ? 'Cours' : d.subject) : d.title,
                style: body(13.5, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(sub.isEmpty ? 'Cours' : sub, style: body(11, color: OC.muted, weight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
        ]),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label, count;
  final Color c, bg;
  final VoidCallback onTap;
  const _QuickCard(this.icon, this.label, this.count, this.c, this.bg, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(height: 9),
          Text(label, style: body(12.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text('$count pack${count == '1' ? '' : 's'}', style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    ));
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final int count;
  final bool loaded;
  final Color c, bg;
  final VoidCallback onTap;
  const _FolderCard({required this.name, required this.count, required this.loaded, required this.c, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
          boxShadow: [
            BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 2),
            BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(children: [
          Positioned(top: -28, right: -22,
            child: Container(width: 70, height: 70, decoration: BoxDecoration(color: bg.withValues(alpha: 0.55), shape: BoxShape.circle))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              SizedBox(
                width: 46, height: 40,
                child: Stack(children: [
                  Positioned(top: 0, left: 2, child: Container(
                    width: 22, height: 8,
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))),
                  )),
                  Positioned(top: 6, left: 0, child: Container(
                    width: 46, height: 34,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.27), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 19),
                  )),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Text(name, style: display(15, weight: FontWeight.w600).copyWith(height: 1.1)),
            const SizedBox(height: 3),
            Text(loaded ? '$count pack${count == 1 ? '' : 's'}' : '…',
                style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
          Positioned(right: 0, top: 0, child: Icon(Icons.chevron_right_rounded, color: OC.faint, size: 18)),
        ]),
      ),
    );
  }
}


/// Vitrine éditoriale « Nos fascicules » : 3 couvertures en éventail (héro sombre).
/// 100 % Dart (Transform + Image.network) → patchable Shorebird, aucun plugin natif.
/// Repli sur une bannière simple si aucune couverture n'est disponible (hors-ligne).
class _FasciculesShowcase extends StatelessWidget {
  const _FasciculesShowcase(this.fascicules);
  final List<Fascicule> fascicules;

  @override
  Widget build(BuildContext context) {
    final covers = [for (final f in fascicules) if (f.hasCover) f.coverUrl];
    return GestureDetector(
      onTap: () => context.push('/fascicules'),
      child: covers.isEmpty ? _plain() : _hero(covers.take(3).toList()),
    );
  }

  // Une couverture de livre (image réseau, tolérante hors-ligne).
  Widget _cover(String url, {double w = 80}) => Container(
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: AspectRatio(
            aspectRatio: 595 / 841,
            child: CachedImage(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Container(color: OC.o600),
              loadingBuilder: (_, child, p) => p == null ? child : Container(color: const Color(0xFF2A211B)),
            ),
          ),
        ),
      );

  // L'éventail : couverture centrale droite, deux latérales inclinées derrière.
  Widget _fan(List<String> covers) {
    Widget at(int i, {required double angle, required Offset shift, double scale = 1}) {
      if (i >= covers.length) return const SizedBox.shrink();
      return Transform.translate(
        offset: shift,
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: _cover(covers[i])),
        ),
      );
    }
    return SizedBox(
      width: 148, height: 122,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        at(1, angle: -0.22, shift: const Offset(-31, 7), scale: 0.82),
        at(2, angle: 0.22, shift: const Offset(31, 7), scale: 0.82),
        at(0, angle: -0.045, shift: const Offset(0, -6)),
      ]),
    );
  }

  Widget _hero(List<String> covers) => Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(0.7, -1.0), radius: 1.4,
            colors: [Color(0xFF3A2E25), Color(0xFF1C1714)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 7))],
        ),
        child: Row(children: [
          _fan(covers),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NOS FASCICULES',
                  style: body(9.5, weight: FontWeight.w800, color: OC.o500).copyWith(letterSpacing: 0.13 * 9.5)),
              const SizedBox(height: 4),
              Text('La bibliothèque OnBuch',
                  style: display(18, weight: FontWeight.w800).copyWith(color: Colors.white, height: 1.05)),
              const SizedBox(height: 5),
              Text('Les bouquins complets — cours + exercices corrigés.',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(11.5, weight: FontWeight.w500).copyWith(color: const Color(0xFFD8CEC4), height: 1.3)),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.fromLTRB(13, 8, 11, 8),
                decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ouvrir', style: body(12.5, weight: FontWeight.w700).copyWith(color: Colors.white)),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ]),
              ),
            ]),
          ),
        ]),
      );

  // Repli (aucune couverture chargée) : bannière sombre simple, comme avant.
  Widget _plain() => Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.ink, OC.ink2],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nos fascicules', style: display(17, weight: FontWeight.w800).copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text('Les bouquins complets OnBuch — cours + exercices corrigés',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(11.5, weight: FontWeight.w500).copyWith(color: Colors.white70, height: 1.25)),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ]),
      );
}
