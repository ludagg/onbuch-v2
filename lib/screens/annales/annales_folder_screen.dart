import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/states.dart';
import '../../data/exam_taxonomy.dart';

/// Navigation d'une catégorie d'annales dans la taxonomie (profondeur variable).
/// Un nœud avec enfants → liste des sous-rubriques ; une feuille → liste des
/// épreuves (bientôt branchée sur la collection `annales`).
class AnnalesFolderScreen extends StatelessWidget {
  final String folderName;
  final ExamNode? node;
  const AnnalesFolderScreen({super.key, required this.folderName, this.node});

  ExamNode? get _node => node ?? examTaxonomy[folderName];

  @override
  Widget build(BuildContext context) {
    final n = _node;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text(n?.label ?? folderName, style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
        ),
      ),
      body: n == null
          ? const EmptyState(
              icon: Icons.folder_off_rounded,
              title: 'Catégorie inconnue',
              message: 'Cette catégorie n\'est pas encore configurée.',
            )
          : (n.isLeaf ? _leaf(n) : _branch(context, n)),
    );
  }

  Widget _branch(BuildContext context, ExamNode n) {
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
        for (final child in n.children) _row(context, child),
      ],
    );
  }

  Widget _row(BuildContext context, ExamNode child) {
    final isGroup = !child.isLeaf;
    return GestureDetector(
      onTap: () => context.push('/annales/folder/${Uri.encodeComponent(child.label)}', extra: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
            child: Icon(isGroup ? Icons.folder_rounded : Icons.description_outlined, size: 21, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(child.label, style: body(13.5, weight: FontWeight.w700)),
            if (isGroup) ...[
              const SizedBox(height: 2),
              Text('${child.children.length} élément${child.children.length > 1 ? 's' : ''}',
                  style: body(11, color: OC.muted, weight: FontWeight.w600)),
            ],
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _leaf(ExamNode n) => EmptyState(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Épreuves bientôt disponibles',
        message: '« ${n.label} » — les annales (sujets + corrigés) seront ajoutées ici prochainement.',
      );
}
