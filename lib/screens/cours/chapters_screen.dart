import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

class ChaptersScreen extends StatefulWidget {
  final Subject? subject;
  const ChaptersScreen({super.key, this.subject});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final _db = DatabaseService();
  List<Chapter> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sub = widget.subject;
    if (sub == null) {
      setState(() => _loading = false);
      return;
    }
    final all = await _db.getChapters();
    if (mounted) {
      setState(() {
        _chapters = all.where((c) => c.subjectId == sub.id).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, sub?.name ?? 'Chapitres'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                if (sub != null)
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: sub.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                      child: Center(child: Text(sub.code, style: display(16, weight: FontWeight.w700, color: sub.color))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sub.name, style: display(19, weight: FontWeight.w700)),
                      Text('${_chapters.length} chapitre${_chapters.length > 1 ? 's' : ''}',
                          style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
                    ])),
                  ]),
                const SizedBox(height: 18),
                if (_chapters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                    child: Row(children: [
                      const Icon(Icons.menu_book_rounded, size: 18, color: OC.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Les chapitres de cette matière arrivent bientôt.',
                          style: body(13, color: OC.muted, weight: FontWeight.w500))),
                    ]),
                  )
                else
                  ...List.generate(_chapters.length, (i) => _chapterTile(_chapters[i], i + 1, sub)),
              ],
            ),
    );
  }

  Widget _chapterTile(Chapter c, int num, Subject? sub) {
    final color = sub?.color ?? OC.o500;
    return GestureDetector(
      onTap: () => context.push('/cours-chapter', extra: {'chapter': c, 'subject': sub?.name ?? ''}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('$num', style: mono(15, weight: FontWeight.w700, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title, style: body(14, weight: FontWeight.w700).copyWith(height: 1.2)),
            if (c.videoUrl != null || c.pdfUrl != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                if (c.pdfUrl != null) ...[const Icon(Icons.picture_as_pdf_rounded, size: 13, color: OC.muted), const SizedBox(width: 4)],
                if (c.videoUrl != null) ...[const Icon(Icons.play_circle_outline_rounded, size: 13, color: OC.muted), const SizedBox(width: 4)],
                Text('Ressources', style: body(11, color: OC.muted, weight: FontWeight.w600)),
              ]),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}
