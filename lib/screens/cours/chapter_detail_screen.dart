import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/rich_answer.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';
import '../../services/tutor_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/launch.dart';

/// Lecteur de leçon (refonte « Nomad Educ ») : vidéo + fiche de cours générée
/// par l'IA (affichée dans l'écran) + accès au quiz. Mène au QCM du chapitre.
class ChapterDetailScreen extends StatefulWidget {
  final Chapter? chapter;
  final String? subjectName;
  const ChapterDetailScreen({super.key, this.chapter, this.subjectName});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  final _db = DatabaseService();
  final _tutor = TutorService();
  late Future<String> _lesson = _loadLesson();

  Future<String> _loadLesson() async {
    final c = widget.chapter;
    if (c == null) throw 'Chapitre introuvable.';
    _db.markChapterViewed(c.id); // progression (non bloquant)
    AnalyticsService.logEvent('lesson_open', {'chapter': c.title, 'subject': widget.subjectName ?? ''});
    final cached = await _db.getLesson(c.id);
    if (cached != null && cached.trim().isNotEmpty) return cached;
    final subj = widget.subjectName ?? '';
    return _tutor.analyzeExercise(
      text: 'Chapitre : ${c.title}${subj.isNotEmpty ? ' ($subj, Terminale)' : ''}',
      subject: subj,
      mode: 'lesson',
      chapterId: c.id,
    );
  }

  void _retry() => setState(() => _lesson = _loadLesson());

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final subj = widget.subjectName ?? '';
    if (c == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'Chapitre'),
        body: const Center(child: Text('Chapitre introuvable.')),
      );
    }
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, subj.isNotEmpty ? subj : 'Chapitre'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (subj.isNotEmpty)
            Text(subj.toUpperCase(), style: body(11, weight: FontWeight.w800, color: OC.o600).copyWith(letterSpacing: 0.1 * 11)),
          const SizedBox(height: 6),
          Text(c.title, style: display(23, weight: FontWeight.w700).copyWith(height: 1.15)),
          if (c.description != null) ...[
            const SizedBox(height: 8),
            Text(c.description!, style: body(13.5, color: OC.ink2).copyWith(height: 1.5)),
          ],
          const SizedBox(height: 18),

          // Vidéo de cours (si fournie)
          if (c.videoUrl != null) ...[
            GestureDetector(
              onTap: () => openUrl(context, c.videoUrl),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: OC.o500, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.4), blurRadius: 16)]),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // La fiche de cours (IA)
          Row(children: [
            const Icon(Icons.menu_book_rounded, size: 18, color: OC.o600),
            const SizedBox(width: 8),
            Text('Le cours', style: body(13.5, weight: FontWeight.w800, color: OC.ink2)),
          ]),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: _lesson,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return _lessonLoading();
              if (snap.hasError) return _lessonError(snap.error);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
                child: RichAnswer(snap.data ?? ''),
              );
            },
          ),

          if (c.pdfUrl != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => openUrl(context, c.pdfUrl),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFC0392B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.picture_as_pdf_rounded, size: 21, color: Color(0xFFC0392B))),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Fiche PDF', style: body(14, weight: FontWeight.w700))),
                  const Icon(Icons.open_in_new_rounded, size: 17, color: OC.muted),
                ]),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: const BoxDecoration(color: OC.paper, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
          child: Row(children: [
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Fiche disponible pour ta révision.', style: body(13, weight: FontWeight.w600, color: Colors.white)),
                backgroundColor: OC.ink, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              )),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: OC.line2, width: 1.5)),
                child: const Icon(Icons.download_for_offline_outlined, size: 22, color: OC.ink2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => context.push('/cours-quiz', extra: {'chapter': c, 'subject': subj}),
              child: Container(
                height: 50,
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Terminer → Quiz', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ]),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _lessonLoading() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          const LeoMascot(size: 64, mood: LeoMood.thinking),
          const SizedBox(height: 10),
          Text('Léo prépare ta fiche…', style: body(13.5, weight: FontWeight.w600, color: OC.ink2)),
          const SizedBox(height: 4),
          Text('Définitions, formules et exemples clairs.',
              textAlign: TextAlign.center, style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ]),
      );

  Widget _lessonError(Object? e) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          const Icon(Icons.error_outline_rounded, size: 30, color: OC.bad),
          const SizedBox(height: 8),
          Text('$e', textAlign: TextAlign.center, style: body(13, color: OC.ink2).copyWith(height: 1.4)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
              child: Text('Réessayer', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      );
}
