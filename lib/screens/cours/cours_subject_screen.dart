import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course.dart';

/// Liste des cours / fiches d'une matière, avec bascule « Cours » / « Fiches »
/// et regroupement optionnel par chapitre.
class CoursSubjectScreen extends StatefulWidget {
  final String subjectKey;
  final List<Course>? preloaded;
  const CoursSubjectScreen({super.key, required this.subjectKey, this.preloaded});

  @override
  State<CoursSubjectScreen> createState() => _CoursSubjectScreenState();
}

class _CoursSubjectScreenState extends State<CoursSubjectScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();

  late final CourseSubject _subject = _subjectFromKey(widget.subjectKey);
  List<Course>? _all; // null = chargement
  bool _fiches = false; // false = Cours, true = Fiches

  @override
  void initState() {
    super.initState();
    if (widget.preloaded != null) {
      _all = widget.preloaded;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final user = await _auth.getCurrentUser();
    final profile = user == null ? null : await _db.getUserProfile(user.$id);
    final list = await _db.getCoursesBySubject(
      _subject,
      classe: (profile?['classe'] ?? '').toString(),
      serie: (profile?['serie'] ?? '').toString(),
    );
    if (!mounted) return;
    setState(() => _all = list);
  }

  static CourseSubject _subjectFromKey(String key) {
    return CourseSubject.values.firstWhere(
      (s) => s.key == key.trim().toLowerCase(),
      orElse: () => CourseSubject.maths,
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final cours = all == null ? <Course>[] : all.where((c) => !c.isFiche).toList();
    final fiches = all == null ? <Course>[] : all.where((c) => c.isFiche).toList();
    final shown = _fiches ? fiches : cours;

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text(_subject.label, style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/cours'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Fil d'Ariane
          Row(children: [
            Text('Cours', style: body(12, color: OC.muted, weight: FontWeight.w600)),
            const Icon(Icons.chevron_right_rounded, size: 13, color: OC.faint),
            Text(_subject.label, style: body(12, weight: FontWeight.w600, color: OC.ink)),
          ]),
          const SizedBox(height: 14),

          // Segments Cours / Fiches
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _fiches = false),
              child: OBChip('Cours · ${cours.length}', active: !_fiches),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: () => setState(() => _fiches = true),
              child: OBChip('Fiches · ${fiches.length}', active: _fiches),
            ),
          ]),
          const SizedBox(height: 18),

          if (all == null)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator(color: OC.o500)),
            )
          else if (shown.isEmpty)
            _EmptyState(fiches: _fiches)
          else
            ..._buildGrouped(context, shown),
        ]),
      ),
    );
  }

  /// Construit la liste, regroupée par chapitre quand l'attribut est renseigné.
  List<Widget> _buildGrouped(BuildContext context, List<Course> items) {
    final widgets = <Widget>[];
    String? currentChapter;
    for (final c in items) {
      final chap = c.chapter;
      if (chap != null && chap != currentChapter) {
        currentChapter = chap;
        widgets.add(Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 14, bottom: 10),
          child: Text(chap, style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        ));
      }
      widgets.add(_CourseRow(course: c));
    }
    return widgets;
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;
  const _CourseRow({required this.course});

  @override
  Widget build(BuildContext context) {
    final c = course;
    return GestureDetector(
      onTap: () => context.go('/cours/lesson', extra: c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          SubjTile(c.subject.tileKey, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title,
                  style: body(13.5, weight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (c.summary != null) ...[
                const SizedBox(height: 3),
                Text(c.summary!,
                    style: body(11.5, color: OC.muted, weight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 5),
              Text('${c.readTimeMinutes} min de lecture',
                  style: body(10.5, color: OC.faint, weight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 8),
          if (c.premium)
            PillBadge('PREMIUM',
                color: const Color(0xFFA6701A),
                bg: const Color(0xFFFBF0DD),
                icon: Icons.lock_outline_rounded)
          else
            PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool fiches;
  const _EmptyState({required this.fiches});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(fiches ? Icons.sticky_note_2_outlined : Icons.menu_book_outlined,
              size: 44, color: OC.faint),
          const SizedBox(height: 12),
          Text(fiches ? 'Aucune fiche pour le moment' : 'Aucun cours pour le moment',
              style: display(16, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Le contenu de cette matière arrive bientôt.',
              textAlign: TextAlign.center, style: body(13.5, color: OC.muted)),
        ]),
      ),
    );
  }
}
