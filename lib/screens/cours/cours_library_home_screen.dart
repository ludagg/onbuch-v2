import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../data/exam_taxonomy.dart';
import '../../services/cours_packs_service.dart';

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
    int byName(Pack a, Pack b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
    final map = {
      'BEPC': bepc..sort(byName),
      'Bac ESG': bac..sort(byName),
      'Probatoire ESG': prob..sort(byName),
    };
    if (mounted) setState(() { _byExam = map; _loaded = true; });
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

              // ── Zone dédiée : tous les cours des 3 examens, triés ───────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Tous les cours', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              ),
              const SizedBox(height: 11),
              if (!_loaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: List.generate(4, (_) => const SkeletonRow())),
                )
              else if (_byExam.values.every((l) => l.isEmpty))
                _emptyAll()
              else
                ..._exams.where((e) => _countFor(e.name) > 0).expand((e) => [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                        child: Row(children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(color: e.c, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(e.name, style: body(12.5, weight: FontWeight.w800, color: OC.ink)),
                          const SizedBox(width: 6),
                          Text('· ${_countFor(e.name)}', style: body(12, weight: FontWeight.w600, color: OC.muted)),
                        ]),
                      ),
                      for (final p in _byExam[e.name]!)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _PackRow(pack: p, onChanged: () { if (mounted) setState(() {}); }),
                        ),
                      const SizedBox(height: 6),
                    ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyAll() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(children: [
          Icon(Icons.auto_stories_rounded, size: 44, color: OC.faint),
          const SizedBox(height: 12),
          Text('Aucun cours pour le moment', style: display(17, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Les packs de cours (BEPC, Bac ESG, Probatoire ESG) apparaîtront ici dès qu\'ils seront ajoutés.',
              textAlign: TextAlign.center, style: body(13, color: OC.muted).copyWith(height: 1.4)),
        ]),
      );
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

/// Ligne de pack pour la zone « Tous les cours » (même style que la page dossier).
class _PackRow extends StatelessWidget {
  final Pack pack;
  final VoidCallback onChanged;
  const _PackRow({required this.pack, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = pack;
    final sub = [p.lessons > 0 ? '${p.lessons} leçons' : null, p.level.isEmpty ? null : p.level]
        .whereType<String>()
        .join(' · ');
    final owned = CoursPacks.instance.isOwned(p.id);
    return GestureDetector(
      onTap: () async { await context.push('/cours/pack?id=${p.id}'); onChanged(); },
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
            width: 52, height: 52,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Text(p.code, style: display(15, weight: FontWeight.w800, color: OC.o600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: body(13.5, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(sub.isEmpty ? 'Pack de cours' : sub, style: body(11, color: OC.muted, weight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            owned
                ? PillBadge('AJOUTÉ', color: OC.waInk, bg: OC.goodBg, icon: Icons.check_rounded)
                : p.premium
                    ? PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD), icon: Icons.lock_outline_rounded)
                    : PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
            const SizedBox(height: 12),
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
          ]),
        ]),
      ),
    );
  }
}
