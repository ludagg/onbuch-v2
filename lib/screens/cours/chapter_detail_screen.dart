import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../models/tutor_request.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

class ChapterDetailScreen extends StatefulWidget {
  final Chapter? chapter;
  final String? subjectName;
  const ChapterDetailScreen({super.key, this.chapter, this.subjectName});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  final _db = DatabaseService();
  bool _busy = false;

  Future<void> _follow() async {
    final c = widget.chapter;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    _db.markChapterViewed(c.id); // progression (non bloquant)
    final cached = await _db.getLesson(c.id); // cache : null si à générer
    if (!mounted) return;
    setState(() => _busy = false);
    final subj = widget.subjectName ?? '';
    context.push('/tutor/correction', extra: TutorRequest(
      question: 'Chapitre : ${c.title}${subj.isNotEmpty ? ' ($subj, Terminale)' : ''}',
      subject: subj,
      titleHint: c.title,
      mode: 'lesson',
      chapterId: c.id,
      presetAnswer: cached,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    if (c == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'Chapitre'),
        body: const Center(child: Text('Chapitre introuvable.')),
      );
    }
    final subj = widget.subjectName ?? '';
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, subj.isNotEmpty ? subj : 'Chapitre'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (subj.isNotEmpty)
            Text(subj.toUpperCase(),
                style: body(11, weight: FontWeight.w800, color: OC.o600).copyWith(letterSpacing: 0.1 * 11)),
          const SizedBox(height: 6),
          Text(c.title, style: display(23, weight: FontWeight.w700).copyWith(height: 1.15)),
          if (c.description != null) ...[
            const SizedBox(height: 10),
            Text(c.description!, style: body(14, color: OC.ink2).copyWith(height: 1.5)),
          ],
          const SizedBox(height: 22),

          GestureDetector(
            onTap: _busy ? null : _follow,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: OC.grad,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: _busy
                      ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Suivre ce cours avec le Tuteur IA', style: body(15, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Fiche structurée : définitions, formules, exemples.',
                      style: body(12.5, color: Colors.white.withValues(alpha: 0.9))),
                ])),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ]),
            ),
          ),

          if (c.pdfUrl != null || c.videoUrl != null) ...[
            const SizedBox(height: 20),
            Text('Ressources', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 10),
            if (c.pdfUrl != null)
              _resource(context, Icons.picture_as_pdf_rounded, 'Fiche PDF', const Color(0xFFC0392B), c.pdfUrl!),
            if (c.videoUrl != null)
              _resource(context, Icons.play_circle_outline_rounded, 'Vidéo du cours', const Color(0xFF7A5AE0), c.videoUrl!),
          ],
        ],
      ),
    );
  }

  Widget _resource(BuildContext context, IconData icon, String label, Color color, String url) => GestureDetector(
        onTap: () => openUrl(context, url),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 21, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: body(14, weight: FontWeight.w700))),
            const Icon(Icons.open_in_new_rounded, size: 17, color: OC.muted),
          ]),
        ),
      );
}
