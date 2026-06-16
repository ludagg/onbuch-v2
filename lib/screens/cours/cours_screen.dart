import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

class CoursScreen extends StatefulWidget {
  const CoursScreen({super.key});

  @override
  State<CoursScreen> createState() => _CoursScreenState();
}

class _CoursScreenState extends State<CoursScreen> {
  final _db = DatabaseService();
  List<Subject> _subjects = [];
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await _db.getSubjects();
    final chapters = await _db.getChapters();
    final counts = <String, int>{};
    for (final c in chapters) {
      counts[c.subjectId] = (counts[c.subjectId] ?? 0) + 1;
    }
    if (mounted) setState(() { _subjects = subjects; _counts = counts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 40 - 12) / 2;
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: OC.bg,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 18,
            title: const OBWordmark(size: 23),
            actions: obTopActions(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cours', style: display(24, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Le programme par matière, avec des fiches générées par l\'IA.',
                    style: body(13.5, color: OC.ink2).copyWith(height: 1.4)),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator(color: OC.o500)))
                else if (_subjects.isEmpty)
                  _hint('Les matières arrivent bientôt.')
                else
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: _subjects.map((s) => _subjectCard(s, w)).toList(),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(Subject s, double w) {
    final n = _counts[s.id] ?? 0;
    return GestureDetector(
      onTap: () => context.push('/cours-subject', extra: s),
      child: Container(
        width: w,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: s.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(s.code, style: display(17, weight: FontWeight.w700, color: s.color))),
          ),
          const SizedBox(height: 12),
          Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: body(14.5, weight: FontWeight.w700).copyWith(height: 1.15)),
          const SizedBox(height: 3),
          Text('$n chapitre${n > 1 ? 's' : ''}', style: body(12, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _hint(String t) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          const Icon(Icons.menu_book_rounded, size: 18, color: OC.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: body(13, color: OC.muted, weight: FontWeight.w500))),
        ]),
      );
}
