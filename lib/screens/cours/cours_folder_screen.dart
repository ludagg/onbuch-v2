import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../data/exam_taxonomy.dart';
import '../../services/exam_structure_service.dart';
import '../../services/cours_packs_service.dart';

/// Navigation des cours dans la taxonomie des examens (profondeur variable) —
/// calque exact de la page Annales :
/// - Niveau de SUBDIVISIONS (ex. Bac → ESG / STT / Industriel) → liste de dossiers.
/// - Niveau TERMINAL (séries / matières) → liste des **packs de cours** dispo.
class CoursFolderScreen extends StatefulWidget {
  final String folderName;
  final ExamNode? node;
  final String? exam; // examen racine (propagé)
  final String? subdivision; // filière parente
  const CoursFolderScreen({super.key, required this.folderName, this.node, this.exam, this.subdivision});

  @override
  State<CoursFolderScreen> createState() => _CoursFolderScreenState();
}

class _CoursFolderScreenState extends State<CoursFolderScreen> {
  List<Pack> _packs = const [];
  bool _packsLoaded = false;

  String get _exam => widget.exam ?? widget.folderName;
  ExamNode? get _node => widget.node ?? ExamStructureService.instance.taxonomy[widget.folderName];

  bool get _isGroupLevel {
    final n = _node;
    if (n == null || n.children.isEmpty) return false;
    return n.children.any((c) => !c.isLeaf || c.code.isNotEmpty || c.subjects.isNotEmpty);
  }

  List<ExamNode> get _items =>
      _node?.children.where((c) => c.isLeaf && c.code.isEmpty).toList() ?? const [];

  @override
  void initState() {
    super.initState();
    if (!_isGroupLevel) _loadPacks();
  }

  // Charge les packs de cette filière/série (matières correspondant à l'examen).
  Future<void> _loadPacks() async {
    final n = _node;
    final serie = n == null ? '' : (n.code.isNotEmpty ? n.code : n.label);
    final packs = await CoursPacks.instance.packsForExam(_exam, serie: serie);
    if (mounted) setState(() { _packs = packs; _packsLoaded = true; });
  }

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
          onPressed: () => context.canPop() ? context.pop() : context.go('/cours'),
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
            final childIsSerie = child.isLeaf && (child.code.isNotEmpty || child.subjects.isNotEmpty);
            final sub = childIsSerie ? n.label : (widget.subdivision ?? '');
            return GestureDetector(
              onTap: () => context.push(
                  '/cours/folder/${Uri.encodeComponent(child.label)}?exam=${Uri.encodeComponent(_exam)}&sub=${Uri.encodeComponent(sub)}',
                  extra: child),
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

  // ── Niveau terminal : liste des packs de cours ────────────────────────────
  Widget _library(BuildContext context, ExamNode n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Fil d'Ariane
        Row(children: [
          Text('Cours', style: body(12, color: OC.muted, weight: FontWeight.w600)),
          Icon(Icons.chevron_right_rounded, size: 13, color: OC.faint),
          Flexible(child: Text(n.label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: body(12, weight: FontWeight.w600, color: OC.ink))),
        ]),
        const SizedBox(height: 16),
        Text('Packs de cours', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 11),
        if (!_packsLoaded)
          ...List.generate(4, (_) => const SkeletonRow())
        else if (_packs.isEmpty)
          _empty(n.label)
        else
          for (final p in _packs) _packRow(context, p),
      ],
    );
  }

  Widget _packRow(BuildContext context, Pack p) {
    final sub = [p.lessons > 0 ? '${p.lessons} leçons' : null, p.level.isEmpty ? null : p.level]
        .whereType<String>()
        .join(' · ');
    final owned = CoursPacks.instance.isOwned(p.id);
    return GestureDetector(
      onTap: () async { await context.push('/cours/pack?id=${p.id}'); if (mounted) setState(() {}); },
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

  Widget _empty(String label) => Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Column(children: [
          Icon(Icons.auto_stories_rounded, size: 46, color: OC.faint),
          const SizedBox(height: 12),
          Text('Aucun pack pour le moment', style: display(18, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Les packs de cours de $label apparaîtront ici dès qu\'ils seront ajoutés.',
              textAlign: TextAlign.center, style: body(13.5, color: OC.muted).copyWith(height: 1.4)),
        ]),
      );
}
