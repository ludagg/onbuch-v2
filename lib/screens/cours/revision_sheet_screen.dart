import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rich_answer.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

/// Fiche de révision (résumé « 1 page ») — contenu réel du chapitre.
class RevisionSheetScreen extends StatelessWidget {
  final String? chapterId;
  final String? title;
  const RevisionSheetScreen({super.key, this.chapterId, this.title});

  @override
  Widget build(BuildContext context) {
    final t = (title ?? '').trim().isEmpty ? 'Chapitre' : title!.trim();
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fiche · $t', style: display(16, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Résumé 1 page', style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
        actions: [IconButton(icon: Icon(Icons.star_border_rounded, color: OC.ink), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('L\'essentiel', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: DatabaseService().getLesson(chapterId ?? ''),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (final _ in [0, 1, 2])
                        Container(height: 10, width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: OC.line, borderRadius: BorderRadius.circular(5))),
                    ]);
                  }
                  final content = (snap.data ?? '').trim();
                  if (content.isEmpty) {
                    return Text('La fiche de ce chapitre sera ajoutée prochainement.', style: body(13, color: OC.muted));
                  }
                  return RichAnswer(content);
                },
              ),
            ]),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: Row(children: [
          Expanded(child: _foot(Icons.picture_as_pdf_rounded, 'PDF', false, () {})),
          const SizedBox(width: 10),
          Expanded(child: _foot(Icons.style_rounded, 'Flashcards', false, () {})),
          const SizedBox(width: 10),
          Expanded(child: _foot(Icons.quiz_rounded, 'Quiz', true, () => context.push('/cours-quiz', extra: {
            'chapter': Chapter(id: chapterId ?? '', subjectId: '', title: t),
            'subject': t,
          }))),
        ]),
      ),
    );
  }

  Widget _foot(IconData icon, String label, bool primary, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: primary ? OC.grad : null,
            color: primary ? null : OC.paper,
            borderRadius: BorderRadius.circular(13),
            border: primary ? null : Border.all(color: OC.line, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: primary ? Colors.white : OC.ink),
            const SizedBox(width: 6),
            Text(label, style: body(12.5, weight: FontWeight.w700, color: primary ? Colors.white : OC.ink)),
          ]),
        ),
      );
}
