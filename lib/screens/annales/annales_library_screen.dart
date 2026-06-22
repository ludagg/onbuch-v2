import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

/// Une catégorie d'examen : libellé, sous-titre, couleur d'accent + fond.
typedef _Cat = (String name, String subtitle, Color c, Color bg);

/// Catégories d'annales, ordonnées par cycle puis par système.
const List<(String, List<_Cat>)> _sections = [
  ('Enseignement général', [
    ('BEPC', 'Collège · 3ᵉ', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
    ('Probatoire', '1ʳᵉ', Color(0xFF2D6CDF), Color(0xFFE7EEFB)),
    ('Baccalauréat', 'Terminale', Color(0xFFDB4F12), Color(0xFFFDEBE2)),
  ]),
  ('Technique & professionnel', [
    ('CAP', 'Aptitude professionnelle', Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
    ('BT', 'Brevet de Technicien', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
    ('BTS', 'Technicien supérieur', Color(0xFF3F51B5), Color(0xFFE8EAF6)),
    ('HND', 'Higher National Diploma', Color(0xFFA6651E), Color(0xFFF6ECDC)),
  ]),
  ('Anglophone — GCE', [
    ('GCE O Level', 'Ordinary Level', Color(0xFF00897B), Color(0xFFE0F2F1)),
    ('GCE A Level', 'Advanced Level', Color(0xFF5E35B1), Color(0xFFEDE7F6)),
  ]),
  ('Concours', [
    ('Concours', 'Écoles & fonction publique', Color(0xFFC0392B), Color(0xFFFBEAE5)),
  ]),
];

class AnnalesLibraryScreen extends StatelessWidget {
  const AnnalesLibraryScreen({super.key});

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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Annales', style: display(24, weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('Épreuves officielles & corrigés', style: body(13, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 16),

          // Recherche
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/cours-search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: OC.line2, width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.search_rounded, size: 19, color: OC.muted),
                const SizedBox(width: 11),
                Text('Matière, examen, année…', style: body(13.5, color: OC.muted, weight: FontWeight.w500)),
              ]),
            ),
          ),
          const SizedBox(height: 22),

          for (final section in _sections) ...[
            Text(section.$1, style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 12),
            _grid(context, section.$2),
            const SizedBox(height: 22),
          ],
        ]),
      ),
    );
  }

  Widget _grid(BuildContext context, List<_Cat> cats) {
    // Une seule catégorie → carte pleine largeur ; sinon grille 2 colonnes.
    if (cats.length == 1) {
      return _FolderCard(cat: cats.first, wide: true,
          onTap: () => context.push('/annales/folder/${cats.first.$1}'));
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: cats
          .map((c) => _FolderCard(cat: c, onTap: () => context.push('/annales/folder/${c.$1}')))
          .toList(),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final _Cat cat;
  final bool wide;
  final VoidCallback onTap;
  const _FolderCard({required this.cat, required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final (name, subtitle, c, bg) = cat;
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
              child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(color: bg.withValues(alpha: 0.55), shape: BoxShape.circle))),
          if (wide)
            Row(children: [
              _folderIcon(c),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: display(16, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
              ])),
              Icon(Icons.chevron_right_rounded, color: OC.faint, size: 20),
            ])
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _folderIcon(c),
              const SizedBox(height: 14),
              Text(name, style: display(15, weight: FontWeight.w600).copyWith(height: 1.1)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
            ]),
          if (!wide)
            Positioned(right: 0, top: 0, child: Icon(Icons.chevron_right_rounded, color: OC.faint, size: 18)),
        ]),
      ),
    );
  }

  Widget _folderIcon(Color c) => SizedBox(
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
      );
}
