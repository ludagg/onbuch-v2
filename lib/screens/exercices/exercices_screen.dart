import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/exercise.dart';
import '../../models/tutor_request.dart';
import '../../services/exercise_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

// ── Palette + icône par matière (cohérent avec le reste de l'app) ─────────────
const _palette = [
  Color(0xFF1E9E63), Color(0xFF7A5AE0), Color(0xFF2D6CDF),
  Color(0xFFC9781C), Color(0xFFE07A0C), Color(0xFF0E9AA0), Color(0xFFC0392B),
];
Color _subjectColor(String name) =>
    _palette[name.toLowerCase().codeUnits.fold(0, (a, b) => a + b) % _palette.length];

IconData _subjectIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('math')) return Icons.calculate_rounded;
  if (n.contains('phys') || n.contains('chim')) return Icons.science_rounded;
  if (n.contains('svt') || n.contains('bio') || n.contains('nature')) return Icons.biotech_rounded;
  if (n.contains('philo')) return Icons.psychology_rounded;
  if (n.contains('franç') || n.contains('lettre') || n.contains('littér')) return Icons.menu_book_rounded;
  if (n.contains('angl') || n.contains('espagnol') || n.contains('allemand') || n.contains('langue')) return Icons.translate_rounded;
  if (n.contains('hist') || n.contains('géo') || n.contains('geo')) return Icons.public_rounded;
  if (n.contains('info') || n.contains('numér')) return Icons.computer_rounded;
  if (n.contains('éco') || n.contains('eco') || n.contains('gestion') || n.contains('compta')) return Icons.trending_up_rounded;
  return Icons.auto_stories_rounded;
}

void _openPdf(BuildContext context, String url, String title, String subtitle, {String? offlineId}) {
  if (url.trim().isEmpty) return;
  context.push('/annales/pdf', extra: {
    'url': url, 'title': title, 'subtitle': subtitle,
    if (offlineId != null) 'offlineId': offlineId,
  });
}

// ═══ Écran 1 : choix de la matière ═══════════════════════════════════════════
class ExercicesScreen extends StatefulWidget {
  const ExercicesScreen({super.key});
  @override
  State<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends State<ExercicesScreen> {
  final _svc = ExerciseService();
  bool _loading = true;
  String? _examen, _serie;
  List<ExerciseChapter> _chapters = [];
  Map<String, ExerciseStatus> _progress = {};
  String? _first = AuthService.cachedFirstName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      final p = await DatabaseService().getUserProfile(user.$id);
      _examen = (p?['examen'] ?? '').toString();
      _serie = (p?['serie'] ?? '').toString();
      final f = DatabaseService.splitFullName(user.name)['firstName'] as String?;
      if (f != null && f.isNotEmpty) _first = f;
    }
    final results = await Future.wait([_svc.getChapters(), _svc.loadProgress()]);
    if (!mounted) return;
    setState(() {
      _chapters = (results[0] as List<ExerciseChapter>)
          .where((c) => c.appliesToClass(_examen, _serie))
          .toList();
      _progress = results[1] as Map<String, ExerciseStatus>;
      _loading = false;
    });
  }

  /// Matières distinctes (ordre = 1er chapitre rencontré).
  List<String> get _subjects {
    final seen = <String>{};
    final out = <String>[];
    for (final c in _chapters) {
      final s = c.subject.trim();
      if (s.isNotEmpty && seen.add(s.toLowerCase())) out.add(s);
    }
    return out;
  }

  int get _done => _progress.values.where((s) => s != ExerciseStatus.none).length;
  int get _found => _progress.values.where((s) => s == ExerciseStatus.found).length;

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Exercices'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              children: [
                // Léo demande la matière
                Row(children: [
                  const LeoMascot(size: 64, mood: LeoMood.encourage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_first == null ? 'On s\'entraîne ?' : 'On s\'entraîne, $_first ?',
                          style: display(18, weight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Quelle matière tu veux travailler aujourd\'hui ?',
                          style: body(13, color: OC.o700, weight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 18),

                if (_done > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: OC.paper, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.line, width: 1.5),
                    ),
                    child: Row(children: [
                      Icon(Icons.checklist_rounded, size: 18, color: OC.good),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Tu as traité $_done exercice${_done > 1 ? 's' : ''} · $_found trouvé${_found > 1 ? 's' : ''}',
                        style: body(13, weight: FontWeight.w600, color: OC.ink2))),
                    ]),
                  ),
                  const SizedBox(height: 18),
                ],

                if (subjects.isEmpty)
                  const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'Bientôt disponible',
                    message: 'Les exercices de ta classe arrivent très vite. Reviens bientôt !',
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      for (var i = 0; i < subjects.length; i++)
                        Appear(index: i, child: _subjectCard(subjects[i])),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _subjectCard(String subject) {
    final c = _subjectColor(subject);
    final n = _chapters.where((x) => x.subject.trim().toLowerCase() == subject.toLowerCase()).length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/exercices/chapitres', extra: {'subject': subject, 'examen': _examen, 'serie': _serie}),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OC.paper, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(_subjectIcon(subject), color: c, size: 22),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('$n chapitre${n > 1 ? 's' : ''}', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

// ═══ Écran 2 : chapitres d'une matière ═══════════════════════════════════════
class ExerciseChaptersScreen extends StatefulWidget {
  final String subject;
  final String? examen, serie;
  const ExerciseChaptersScreen({super.key, required this.subject, this.examen, this.serie});
  @override
  State<ExerciseChaptersScreen> createState() => _ExerciseChaptersScreenState();
}

class _ExerciseChaptersScreenState extends State<ExerciseChaptersScreen> {
  final _svc = ExerciseService();
  bool _loading = true;
  List<ExerciseChapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _svc.getChapters();
    if (!mounted) return;
    setState(() {
      _chapters = all
          .where((c) =>
              c.subject.trim().toLowerCase() == widget.subject.toLowerCase() &&
              c.appliesToClass(widget.examen, widget.serie))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _subjectColor(widget.subject);
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, widget.subject),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : _chapters.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'Aucun chapitre',
                  message: 'Les chapitres de cette matière arrivent bientôt.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    for (var i = 0; i < _chapters.length; i++)
                      Appear(index: i, child: _chapterTile(_chapters[i], c)),
                  ],
                ),
    );
  }

  Widget _chapterTile(ExerciseChapter ch, Color c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/exercices/fiches', extra: ch),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.layers_rounded, size: 20, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ch.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w700)),
            if (ch.description != null) ...[
              const SizedBox(height: 2),
              Text(ch.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
            ],
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}

// ═══ Écran 3 : fiches d'un chapitre ══════════════════════════════════════════
class ExerciseSheetsScreen extends StatefulWidget {
  final ExerciseChapter chapter;
  const ExerciseSheetsScreen({super.key, required this.chapter});
  @override
  State<ExerciseSheetsScreen> createState() => _ExerciseSheetsScreenState();
}

class _ExerciseSheetsScreenState extends State<ExerciseSheetsScreen> {
  final _svc = ExerciseService();
  bool _loading = true;
  List<ExerciseSheet> _sheets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([_svc.getSheets(widget.chapter.id), _svc.loadProgress()]);
    if (!mounted) return;
    setState(() {
      _sheets = results[0] as List<ExerciseSheet>;
      _loading = false;
    });
  }

  Future<void> _setStatus(ExerciseSheet s, ExerciseStatus st) async {
    setState(() {}); // le cache du service est optimiste
    await _svc.setStatus(s, st);
    if (mounted) setState(() {});
  }

  void _askLeo(ExerciseSheet s) {
    context.push('/tutor/correction', extra: TutorRequest(
      examUrl: s.statementPdfUrl,
      mode: 'exam_help',
      subject: s.subject.isEmpty ? widget.chapter.subject : s.subject,
      titleHint: s.title,
      question: 'Aide-moi à résoudre cet exercice, étape par étape.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, widget.chapter.title),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : _sheets.isEmpty
              ? const EmptyState(
                  icon: Icons.description_outlined,
                  title: 'Aucune fiche',
                  message: 'Les fiches d\'exercices de ce chapitre arrivent bientôt.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    for (var i = 0; i < _sheets.length; i++)
                      Appear(index: i, child: _sheetCard(_sheets[i])),
                  ],
                ),
    );
  }

  Widget _sheetCard(ExerciseSheet s) {
    final st = _svc.statusOf(s.id);
    final sub = [widget.chapter.subject, widget.chapter.title].where((e) => e.isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.title, style: body(14.5, weight: FontWeight.w800))),
          _statusBadge(st),
        ]),
        if (s.difficulty.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
            child: Text(s.difficulty, style: body(10.5, weight: FontWeight.w700, color: OC.o700)),
          ),
        ],
        const SizedBox(height: 12),
        // Énoncé + correction
        Row(children: [
          Expanded(child: _btn('Énoncé', Icons.description_rounded, true,
              () => _openPdf(context, s.statementPdfUrl, s.title, sub, offlineId: 'exo_${s.id}'))),
          const SizedBox(width: 10),
          Expanded(child: _btn('Correction', Icons.check_circle_outline_rounded, false,
              s.hasCorrection ? () => _openPdf(context, s.correctionPdfUrl!, 'Correction · ${s.title}', sub, offlineId: 'cor_${s.id}') : null)),
        ]),
        const SizedBox(height: 10),
        // As-tu trouvé ?
        Row(children: [
          Text('As-tu trouvé ?', style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
          const Spacer(),
          _toggle('Oui ✅', st == ExerciseStatus.found, OC.good, () => _setStatus(s, ExerciseStatus.found)),
          const SizedBox(width: 8),
          _toggle('Non', st == ExerciseStatus.notFound, OC.bad, () => _setStatus(s, ExerciseStatus.notFound)),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _askLeo(s),
          child: Row(children: [
            Icon(Icons.auto_awesome_rounded, size: 15, color: OC.o600),
            const SizedBox(width: 6),
            Text('Bloqué ? Demande à Léo', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBadge(ExerciseStatus st) {
    switch (st) {
      case ExerciseStatus.found:
        return Icon(Icons.check_circle_rounded, size: 20, color: OC.good);
      case ExerciseStatus.notFound:
        return Icon(Icons.cancel_rounded, size: 20, color: OC.bad);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _btn(String label, IconData icon, bool primary, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: primary ? OC.ink : OC.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary ? OC.ink : OC.line2, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: primary ? Colors.white : OC.ink2),
            const SizedBox(width: 6),
            Text(label, style: body(12.5, weight: FontWeight.w700, color: primary ? Colors.white : OC.ink2)),
          ]),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool on, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? color : OC.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? color : OC.line2, width: 1.5),
        ),
        child: Text(label, style: body(12, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
      ),
    );
  }
}
