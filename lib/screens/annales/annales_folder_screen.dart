import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../data/exam_taxonomy.dart';
import '../../services/exam_structure_service.dart';

/// Navigation des annales dans la taxonomie (profondeur variable).
/// - Niveau de SUBDIVISIONS (ex. Bac → ESG / STT / Industriel) → liste de dossiers.
/// - Niveau TERMINAL (séries / matières) → page « bibliothèque » : filtres
///   (séries de la taxonomie) + grille matières + récemment ajoutés.
class AnnalesFolderScreen extends StatefulWidget {
  final String folderName;
  final ExamNode? node;
  final String? exam; // examen racine (propagé pour retrouver les matières en base)
  const AnnalesFolderScreen({super.key, required this.folderName, this.node, this.exam});

  @override
  State<AnnalesFolderScreen> createState() => _AnnalesFolderScreenState();
}

class _AnnalesFolderScreenState extends State<AnnalesFolderScreen> {
  int _serie = 0;
  int _year = 0;

  // Examen racine : au 1ᵉʳ niveau, le nom du dossier EST l'examen.
  String get _exam => widget.exam ?? widget.folderName;

  static const _years = ['2025', '2024', '2023', '2022'];

  // Matières démo (en attendant la collection `annales`).
  static const _demoSubjects = [
    ('Maths', 18), ('Phys-Chimie', 16), ('SVT', 14),
    ('Philo', 12), ('Français', 10), ('Anglais', 8),
  ];
  static const _recent = [
    ('Maths', 'Mathématiques', true, ['pdf', 'corrige', 'video']),
    ('Phys-Chimie', 'Physique-Chimie', true, ['pdf', 'corrige']),
    ('SVT', 'Sciences de la vie', false, ['pdf', 'corrige', 'video']),
  ];

  // Structure (taxonomie) pilotée par la base + cache disque (offline-first).
  ExamNode? get _node => widget.node ?? ExamStructureService.instance.taxonomy[widget.folderName];

  // On affiche une LISTE de dossiers quand les enfants sont des subdivisions
  // (sous-dossiers), des SÉRIES (feuille AVEC code) ou des SPÉCIALITÉS (feuille
  // avec ses propres matières) : il faut alors choisir d'abord, puis on ouvre la
  // grille de matières du nœud choisi. Si les enfants sont des MATIÈRES
  // terminales (feuille sans code ni matières propres, ex. GCE Science →
  // Mathematics/Physics), on montre directement la grille — une matière mène aux
  // documents, pas à une autre grille.
  bool get _isGroupLevel {
    final n = _node;
    if (n == null || n.children.isEmpty) return false;
    return n.children.any((c) => !c.isLeaf || c.code.isNotEmpty || c.subjects.isNotEmpty);
  }

  // Séries (feuilles AVEC code) → chips de filtre.
  List<ExamNode> get _series =>
      _node?.children.where((c) => c.isLeaf && c.code.isNotEmpty).toList() ?? const [];

  // Matières/spécialités (feuilles SANS code) → grille de dossiers réels.
  List<ExamNode> get _items =>
      _node?.children.where((c) => c.isLeaf && c.code.isEmpty).toList() ?? const [];

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
        actions: [
          IconButton(icon: const Icon(Icons.sort_rounded, size: 19), color: OC.ink2, onPressed: () {}),
        ],
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
            // Un enfant « enterable » mène à une grille : sous-dossier ou
            // spécialité/série porteuse de matières → icône dossier + compteur.
            final count = child.children.isNotEmpty ? child.children.length : child.subjects.length;
            final unit = child.children.isNotEmpty ? 'élément' : 'matière';
            return GestureDetector(
              onTap: () => context.push(
                  '/annales/folder/${Uri.encodeComponent(child.label)}?exam=${Uri.encodeComponent(_exam)}',
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

  // ── Niveau terminal : page « bibliothèque » ───────────────────────────────
  Widget _library(BuildContext context, ExamNode n) {
    final series = _series;
    final items = _items;
    // Matières de la filière (issues de la structure base/cache, ou statique).
    final subjects = n.subjects;
    final useSubjects = subjects.isNotEmpty;
    final useRealGrid = !useSubjects && items.isNotEmpty; // GCE/CAP/BTS/HND : feuilles = matières
    return SingleChildScrollView(
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

        // Filtres : séries (si disponibles) puis années
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < series.length; i++) ...[
              GestureDetector(
                onTap: () => setState(() => _serie = i),
                child: OBChip(_chipLabel(series[i]), active: i == _serie),
              ),
              const SizedBox(width: 9),
            ],
            for (var i = 0; i < _years.length; i++) ...[
              GestureDetector(
                onTap: () => setState(() => _year = i),
                child: OBChip(_years[i], active: i == _year),
              ),
              if (i < _years.length - 1) const SizedBox(width: 9),
            ],
          ]),
        ),
        const SizedBox(height: 18),

        // Grille « Dossiers · matières »
        Text('Dossiers · matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 11),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: useSubjects
              ? subjects.map((s) => _subjectTile(context, s, null, n.label)).toList()
              : useRealGrid
                  ? items.map((it) => _subjectTile(context, it.label, null, n.label)).toList()
                  : _demoSubjects.map((s) => _subjectTile(context, s.$1, s.$2, n.label)).toList(),
        ),
        const SizedBox(height: 18),

        // Récemment ajoutés (démo en attendant la collection annales)
        Text('Récemment ajoutés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 11),
        ..._recent.map((a) => GestureDetector(
              onTap: () => context.go('/annales/detail'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  SubjLogo(a.$1, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.$2, style: body(13.5, weight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Row(children: a.$4.map((t) => Padding(padding: const EdgeInsets.only(right: 5), child: _TypePill(t))).toList()),
                  ])),
                  a.$3
                      ? PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg)
                      : PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD), icon: Icons.lock_outline_rounded),
                ]),
              ),
            )),
      ]),
    );
  }

  String _chipLabel(ExamNode s) {
    final c = s.code;
    // « Série D », « Série F2 », « Série CG »…
    return c.length <= 3 ? 'Série $c' : c;
  }

  Widget _subjectTile(BuildContext context, String name, int? count, String filiere) {
    return GestureDetector(
      onTap: () => context.push('/annales/subject',
          extra: {'subject': name, 'exam': _exam, 'filiere': filiere}),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          SubjLogo(name, size: 36),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(count != null ? '$count épreuves' : 'épreuves bientôt',
                style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
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
