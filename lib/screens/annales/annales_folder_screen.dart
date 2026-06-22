import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/annale_actions.dart';
import '../../data/exam_taxonomy.dart';
import '../../services/exam_structure_service.dart';
import '../../services/database_service.dart';
import '../../models/annale.dart';

/// Navigation des annales dans la taxonomie (profondeur variable).
/// - Niveau de SUBDIVISIONS (ex. Bac → ESG / STT / Industriel) → liste de dossiers.
/// - Niveau TERMINAL (séries / matières) → page « bibliothèque » : grille des
///   matières (avec nombre réel de documents) + documents récemment ajoutés.
class AnnalesFolderScreen extends StatefulWidget {
  final String folderName;
  final ExamNode? node;
  final String? exam; // examen racine (propagé pour retrouver les matières en base)
  const AnnalesFolderScreen({super.key, required this.folderName, this.node, this.exam});

  @override
  State<AnnalesFolderScreen> createState() => _AnnalesFolderScreenState();
}

class _AnnalesFolderScreenState extends State<AnnalesFolderScreen> {
  List<Annale> _docs = const [];
  bool _docsLoaded = false;

  // Examen racine : au 1ᵉʳ niveau, le nom du dossier EST l'examen.
  String get _exam => widget.exam ?? widget.folderName;

  // Structure (taxonomie) pilotée par la base + cache disque (offline-first).
  ExamNode? get _node => widget.node ?? ExamStructureService.instance.taxonomy[widget.folderName];

  // On affiche une LISTE de dossiers quand les enfants sont des subdivisions
  // (sous-dossiers), des SÉRIES (feuille AVEC code) ou des SPÉCIALITÉS (feuille
  // avec ses propres matières). Sinon (matières terminales) → grille.
  bool get _isGroupLevel {
    final n = _node;
    if (n == null || n.children.isEmpty) return false;
    return n.children.any((c) => !c.isLeaf || c.code.isNotEmpty || c.subjects.isNotEmpty);
  }

  // Matières/spécialités (feuilles SANS code) → repli de grille.
  List<ExamNode> get _items =>
      _node?.children.where((c) => c.isLeaf && c.code.isEmpty).toList() ?? const [];

  @override
  void initState() {
    super.initState();
    if (!_isGroupLevel) _loadDocs();
  }

  // Charge les documents de l'examen (pour compter par matière + récents).
  Future<void> _loadDocs() async {
    final docs = await DatabaseService().getAnnalesForExam(_exam);
    if (mounted) setState(() { _docs = docs; _docsLoaded = true; });
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
    final items = _items;
    final subjects = n.subjects.isNotEmpty ? n.subjects : items.map((e) => e.label).toList();

    // Documents réels de cette filière (correspondance souple : code / libellé /
    // général) — robuste face aux imports (track = « D », « D — … » ou vide).
    final docs = _docs.where((d) => d.appliesToSerie(n.code, n.label)).toList();
    final counts = <String, int>{};
    for (final d in docs) {
      counts[d.subject] = (counts[d.subject] ?? 0) + 1;
    }
    final recents = docs.take(4).toList(); // _docs déjà triés (créés récemment d'abord)

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
        const SizedBox(height: 16),

        if (subjects.isNotEmpty) ...[
          Text('Matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: subjects
                .map((s) => _subjectTile(context, s, _docsLoaded ? (counts[s] ?? 0) : null, n.label, n.code))
                .toList(),
          ),
          const SizedBox(height: 18),
        ],

        // Récemment ajoutés (vrais documents)
        if (recents.isNotEmpty) ...[
          Text('Récemment ajoutés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          ...recents.map((a) => GestureDetector(
                onTap: () => context.push('/annales/detail', extra: a),
                onLongPress: () => showAnnaleActions(context, a),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                  child: Row(children: [
                    SubjLogo(a.subject, size: 40),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Row(children: a.formats.map((t) => Padding(padding: const EdgeInsets.only(right: 5), child: _TypePill(t))).toList()),
                    ])),
                    a.premium
                        ? PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD), icon: Icons.lock_outline_rounded)
                        : PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
                  ]),
                ),
              )),
        ],
      ]),
    );
  }

  Widget _subjectTile(BuildContext context, String name, int? count, String filiere, String code) {
    final label = count == null
        ? 'Ouvrir'
        : (count == 0 ? 'Bientôt' : '$count document${count > 1 ? 's' : ''}');
    return GestureDetector(
      onTap: () => context.push('/annales/subject',
          extra: {'subject': name, 'exam': _exam, 'filiere': filiere, 'code': code}),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          SubjLogo(name, size: 36),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
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
