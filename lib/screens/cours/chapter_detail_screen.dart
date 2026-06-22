import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/rich_answer.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';
import '../../services/tutor_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/launch.dart';

/// Lecteur de chapitre à onglets : Cours (fiche IA) · Résumé (fiche de
/// révision) · Exercices · Vidéo · Exam PDF. Mène au QCM du chapitre.
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
  Future<String>? _summary; // chargé paresseusement à l'ouverture de l'onglet
  int _tab = 0;

  static const _tabs = ['Cours', 'Résumé', 'Exercices', 'Vidéo', 'Exam PDF'];

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

  Future<String> _loadSummary() {
    final c = widget.chapter!;
    final subj = widget.subjectName ?? '';
    return _tutor.summarizeCourse(
      text: 'Chapitre : ${c.title}${subj.isNotEmpty ? ' ($subj, Terminale)' : ''}',
      subject: subj,
      notify: false,
    );
  }

  void _retryLesson() => setState(() => _lesson = _loadLesson());
  void _retrySummary() => setState(() => _summary = _loadSummary());

  void _select(int i) {
    setState(() {
      _tab = i;
      if (i == 1 && _summary == null) _summary = _loadSummary();
    });
  }

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
          const SizedBox(height: 16),

          _tabBar(),
          const SizedBox(height: 16),

          _tabContent(c),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(color: OC.paper, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
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
                child: Icon(Icons.download_for_offline_outlined, size: 22, color: OC.ink2),
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

  // ── Onglets ───────────────────────────────────────────────────────────────
  Widget _tabBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == _tab;
          return GestureDetector(
            onTap: () => _select(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: on ? OC.o500 : OC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
              ),
              child: Text(_tabs[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
            ),
          );
        },
      ),
    );
  }

  Widget _tabContent(Chapter c) {
    switch (_tab) {
      case 1: // Résumé
        return FutureBuilder<String>(
          future: _summary,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loadingCard('Léo rédige ta fiche…', 'Points clés, formules et à-retenir.');
            }
            if (snap.hasError) return _errorCard(snap.error, _retrySummary);
            return _answerCard(snap.data ?? '');
          },
        );
      case 2: // Exercices (hors scope pour l'instant)
        return const EmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'Bientôt disponible',
          message: 'Les exercices de ce chapitre arrivent.',
          padding: EdgeInsets.fromLTRB(8, 30, 8, 20),
        );
      case 3: // Vidéo
        if (c.videoUrl == null) {
          return const EmptyState(
            icon: Icons.play_circle_outline_rounded,
            title: 'Pas de vidéo',
            message: 'Aucune vidéo pour ce chapitre.',
            padding: EdgeInsets.fromLTRB(8, 30, 8, 20),
          );
        }
        return GestureDetector(
          onTap: () => openUrl(context, c.videoUrl),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: OC.o500, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.4), blurRadius: 16)]),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        );
      case 4: // Exam PDF
        if (c.pdfUrl == null) {
          return const EmptyState(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Pas de PDF',
            message: 'Aucun document PDF pour ce chapitre.',
            padding: EdgeInsets.fromLTRB(8, 30, 8, 20),
          );
        }
        return GestureDetector(
          onTap: () => openUrl(context, c.pdfUrl),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFC0392B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 21, color: Color(0xFFC0392B))),
              const SizedBox(width: 12),
              Expanded(child: Text('Fiche PDF', style: body(14, weight: FontWeight.w700))),
              Icon(Icons.open_in_new_rounded, size: 17, color: OC.muted),
            ]),
          ),
        );
      default: // Cours
        return FutureBuilder<String>(
          future: _lesson,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loadingCard('Léo prépare ta fiche…', 'Définitions, formules et exemples clairs.');
            }
            if (snap.hasError) return _errorCard(snap.error, _retryLesson);
            return _answerCard(snap.data ?? '');
          },
        );
    }
  }

  // ── Cartes utilitaires ────────────────────────────────────────────────────
  Widget _answerCard(String content) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: RichAnswer(content),
      );

  Widget _loadingCard(String title, String subtitle) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          const LeoMascot(size: 64, mood: LeoMood.thinking),
          const SizedBox(height: 10),
          Text(title, style: body(13.5, weight: FontWeight.w600, color: OC.ink2)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ]),
      );

  Widget _errorCard(Object? e, VoidCallback onRetry) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          Icon(Icons.error_outline_rounded, size: 30, color: OC.bad),
          const SizedBox(height: 8),
          Text('$e', textAlign: TextAlign.center, style: body(13, color: OC.ink2).copyWith(height: 1.4)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
              child: Text('Réessayer', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      );
}
