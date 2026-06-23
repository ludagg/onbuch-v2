import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/cours_packs_service.dart';

/// Examens de la grille « Parcourir par examen » (mêmes libellés/couleurs que la
/// page Annales — clés de la taxonomie `examTaxonomy`).
const _examFolders = [
  ('BEPC', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
  ('Probatoire', Color(0xFF2D6CDF), Color(0xFFE7EEFB)),
  ('Baccalauréat', Color(0xFFDB4F12), Color(0xFFFDEBE2)),
  ('CAP', Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
  ('BT', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
  ('BTS', Color(0xFF3F51B5), Color(0xFFE8EAF6)),
  ('HND', Color(0xFFA6651E), Color(0xFFF6ECDC)),
  ('GCE O Level', Color(0xFF00897B), Color(0xFFE0F2F1)),
  ('GCE A Level', Color(0xFF5E35B1), Color(0xFFEDE7F6)),
  ('Concours', Color(0xFFC0392B), Color(0xFFFBEAE5)),
];

/// Accueil du module Cours — calque exact de la page Annales : barre de
/// recherche, accès rapides (Mes cours · Panier · Catalogue), puis grille
/// « Parcourir par examen ». La seule différence avec les annales : le contenu
/// terminal liste des **packs de cours** au lieu de documents.
class CoursLibraryHomeScreen extends StatefulWidget {
  const CoursLibraryHomeScreen({super.key});

  @override
  State<CoursLibraryHomeScreen> createState() => _CoursLibraryHomeScreenState();
}

class _CoursLibraryHomeScreenState extends State<CoursLibraryHomeScreen> {
  final _packs = CoursPacks.instance;
  Map<String, int> _counts = const {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _packs.load();
    final counts = await _packs.countByExam(_examFolders.map((f) => f.$1).toList());
    if (mounted) setState(() { _counts = counts; _loaded = true; });
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
                  children: _examFolders.map((f) => _FolderCard(
                    name: f.$1,
                    count: _counts[f.$1] ?? 0,
                    loaded: _loaded,
                    c: f.$2,
                    bg: f.$3,
                    onTap: () => context.push('/cours/folder/${Uri.encodeComponent(f.$1)}'),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
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
