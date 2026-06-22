import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/annales_store.dart';

// Examens de tête (clés de la taxonomie ET valeurs du champ `exam` de la
// collection `annales`). La couleur/teinte sert d'identité visuelle.
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

class AnnalesLibraryScreen extends StatefulWidget {
  const AnnalesLibraryScreen({super.key});

  @override
  State<AnnalesLibraryScreen> createState() => _AnnalesLibraryScreenState();
}

class _AnnalesLibraryScreenState extends State<AnnalesLibraryScreen> {
  final _store = AnnalesStore.instance;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Recherche (ouvre la recherche globale)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/search'),
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
                  Expanded(child: Text('Matière, examen, année…',
                      style: body(14.5, color: OC.muted, weight: FontWeight.w500))),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Accès rapides (compteurs réels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _QuickCard(Icons.download_rounded, 'Hors-ligne', _store.downloads.length,
                  OC.waInk, OC.goodBg, () => context.push('/annales/offline')),
              const SizedBox(width: 11),
              _QuickCard(Icons.access_time_rounded, 'Récents', _store.recents.length,
                  OC.blue, OC.blueBg, () => context.push('/annales/recent')),
              const SizedBox(width: 11),
              _QuickCard(Icons.bookmark_outline_rounded, 'Favoris', _store.favorites.length,
                  const Color(0xFFA6701A), const Color(0xFFFBF0DD),
                  () => context.push('/annales/favorites')),
            ]),
          ),
          const SizedBox(height: 18),

          // Parcourir par examen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Parcourir par examen',
                style: body(13, weight: FontWeight.w800, color: OC.ink2)),
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
                c: f.$2,
                bg: f.$3,
                onTap: () => context.go(
                    '/annales/folder/${Uri.encodeComponent(f.$1)}?exam=${Uri.encodeComponent(f.$1)}'),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
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
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(height: 9),
          Text(label, style: body(12.5, weight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text('$count fichier${count > 1 ? 's' : ''}',
              style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    ));
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final Color c, bg;
  final VoidCallback onTap;
  const _FolderCard({required this.name, required this.c, required this.bg, required this.onTap});

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
            child: Container(width: 70, height: 70, decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.55), shape: BoxShape.circle))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 46, height: 40,
              child: Stack(children: [
                Positioned(top: 0, left: 2, child: Container(
                  width: 22, height: 8,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                  ),
                )),
                Positioned(top: 6, left: 0, child: Container(
                  width: 46, height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.27), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 19),
                )),
              ]),
            ),
            const SizedBox(height: 14),
            Text(name, style: display(15, weight: FontWeight.w600).copyWith(height: 1.1)),
            const SizedBox(height: 3),
            Text('Voir les épreuves', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
          Positioned(right: 0, top: 0, child: Icon(Icons.chevron_right_rounded, color: OC.faint, size: 18)),
        ]),
      ),
    );
  }
}
