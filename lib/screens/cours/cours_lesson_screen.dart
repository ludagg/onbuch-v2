import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/rich_answer.dart';
import '../../models/course.dart';

/// Lecture d'un cours ou d'une fiche de révision.
///
/// Le corps réutilise [RichAnswer] : Markdown + LaTeX + tableaux + graphes
/// `onbuch-plot`, exactement comme les corrections du Tuteur.
class CoursLessonScreen extends StatelessWidget {
  final Course? course;
  const CoursLessonScreen({super.key, this.course});

  @override
  Widget build(BuildContext context) {
    final c = course;
    if (c == null) return const _LessonNotFound();

    final subj = c.subject;
    final lessonBody = (c.body ?? '').trim();

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/cours'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded, size: 20),
            color: OC.ink2,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Favoris — bientôt disponible',
                    style: body(13, weight: FontWeight.w600, color: Colors.white)),
                backgroundColor: OC.ink,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête : pastille matière + type + temps de lecture
          Row(children: [
            SubjTile(subj.tileKey, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subj.label, style: body(12.5, weight: FontWeight.w700, color: subj.color)),
                const SizedBox(height: 2),
                Text('${c.isFiche ? 'Fiche de révision' : 'Cours'} · ${c.readTimeMinutes} min',
                    style: body(11.5, weight: FontWeight.w500, color: OC.muted)),
              ]),
            ),
            if (c.premium)
              PillBadge('PREMIUM',
                  color: const Color(0xFFA6701A),
                  bg: const Color(0xFFFBF0DD),
                  icon: Icons.lock_outline_rounded)
            else
              PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
          ]),
          const SizedBox(height: 16),

          // Titre
          Text(c.title, style: display(24, weight: FontWeight.w700).copyWith(height: 1.18)),
          if (c.chapter != null) ...[
            const SizedBox(height: 6),
            Text(c.chapter!, style: body(13, weight: FontWeight.w600, color: OC.ink2)),
          ],
          const SizedBox(height: 16),
          const HRule(),
          const SizedBox(height: 16),

          // Corps riche (Markdown / LaTeX / graphes)
          if (lessonBody.isNotEmpty)
            RichAnswer(lessonBody)
          else
            Text('Le contenu de cette leçon sera bientôt disponible.',
                style: body(14.5, color: OC.muted).copyWith(height: 1.5)),
        ]),
      ),
    );
  }
}

class _LessonNotFound extends StatelessWidget {
  const _LessonNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: OC.ink),
          onPressed: () => context.go('/cours'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.menu_book_outlined, size: 48, color: OC.faint),
            const SizedBox(height: 14),
            Text('Leçon introuvable', style: display(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Cette leçon n\'est plus disponible.',
                textAlign: TextAlign.center, style: body(14, color: OC.muted)),
          ]),
        ),
      ),
    );
  }
}
