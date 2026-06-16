import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class CoursScreen extends StatefulWidget {
  const CoursScreen({super.key});

  @override
  State<CoursScreen> createState() => _CoursScreenState();
}

class _CoursScreenState extends State<CoursScreen> {
  final _db = DatabaseService();
  List<Subject> _subjects = [];
  List<Chapter> _chapters = [];
  Set<String> _viewed = {};
  String? _classe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await _db.getSubjects();
    final chapters = await _db.getChapters();
    final viewed = await _db.getViewedChapterIds();
    String? classe;
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      final p = await _db.getUserProfile(user.$id);
      classe = p?['classe']?.toString();
    }
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _chapters = chapters;
        _viewed = viewed;
        _classe = classe;
        _loading = false;
      });
    }
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
                Text('Le programme${_classe != null && _classe!.isNotEmpty ? ' · $_classe' : ''} — fiches générées par l\'IA.',
                    style: body(13.5, color: OC.ink2).copyWith(height: 1.4)),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator(color: OC.o500)))
                else if (_subjects.isEmpty)
                  _hint('Les matières arrivent bientôt.')
                else
                  Builder(builder: (_) {
                    var visible = _subjects.where((s) => s.appliesTo(_classe)).toList();
                    if (visible.isEmpty) visible = _subjects;
                    return Wrap(
                      spacing: 12, runSpacing: 12,
                      children: visible.map((s) => _subjectCard(s, w)).toList(),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(Subject s, double w) {
    final chs = _chapters.where((c) => c.subjectId == s.id).toList();
    final total = chs.length;
    final done = chs.where((c) => _viewed.contains(c.id)).length;
    final pct = total == 0 ? 0.0 : done / total;
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
          const SizedBox(height: 6),
          Text('$done/$total chapitre${total > 1 ? 's' : ''}', style: body(12, color: OC.muted, weight: FontWeight.w600)),
          if (total > 0) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 5,
                backgroundColor: OC.line,
                valueColor: AlwaysStoppedAnimation(s.color),
              ),
            ),
          ],
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
