import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class AnnalesFolderScreen extends StatelessWidget {
  final String folderName;
  const AnnalesFolderScreen({super.key, required this.folderName});

  static const _subjects = [
    ('Maths', 18), ('Phys-Chimie', 16), ('SVT', 14),
    ('Philo', 12), ('Français', 10), ('Anglais', 8),
  ];

  static const _recent = [
    ('Maths', 'Mathématiques', 'Bac D · 2025', true, ['pdf', 'corrige', 'video']),
    ('Phys-Chimie', 'Physique-Chimie', 'Bac D · 2025', true, ['pdf', 'corrige']),
    ('SVT', 'Sciences de la vie', 'Bac D · 2024', false, ['pdf', 'corrige', 'video']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text(folderName, style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/annales'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.sort_rounded, size: 19), color: OC.ink2, onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Breadcrumb
          Row(children: [
            Text('Bibliothèque', style: body(12, color: OC.muted, weight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, size: 13, color: OC.faint),
            Text(folderName, style: body(12, weight: FontWeight.w600, color: OC.ink)),
          ]),
          const SizedBox(height: 14),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: const [
              OBChip('Série D', active: true),
              SizedBox(width: 9),
              OBChip('2025', active: true),
              SizedBox(width: 9),
              OBChip('Série C'),
              SizedBox(width: 9),
              OBChip('Série A'),
            ]),
          ),
          const SizedBox(height: 18),

          // Subject folders grid
          Text('Dossiers · matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: _subjects.map((s) => GestureDetector(
              onTap: () => context.go('/annales/detail'),
              child: Container(
                padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
                decoration: BoxDecoration(
                  color: OC.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OC.line, width: 1.5),
                ),
                child: Row(children: [
                  SubjTile(s.$1, size: 36),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s.$1, style: body(13, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    Text('${s.$2} épreuves', style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
                  ])),
                ]),
              ),
            )).toList(),
          ),
          const SizedBox(height: 18),

          // Recent files
          Text('Récemment ajoutés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          ..._recent.map((a) => GestureDetector(
            onTap: () => context.go('/annales/detail'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Row(children: [
                SubjTile(a.$1, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.$2, style: body(13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Row(children: a.$5.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: _TypePill(t),
                  )).toList()),
                ])),
                a.$4
                    ? PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg)
                    : PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD),
                        icon: Icons.lock_outline_rounded),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill(this.type);

  @override
  Widget build(BuildContext context) {
    const map = {
      'pdf':     ('PDF', Color(0xFFC0392B), Color(0xFFFAE7E4)),
      'video':   ('Vidéo', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
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
