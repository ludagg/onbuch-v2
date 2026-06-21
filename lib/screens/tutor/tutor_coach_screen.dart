import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/exam.dart';
import '../../models/course.dart';
import '../../models/review.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Tableau de bord « Coach » de Léo (Phase 4) : compte à rebours examen,
/// points faibles, plan de la semaine, révisions du jour, et démarrage de
/// session. S'appuie sur `topic_mastery`, `review_queue`, `exams` et le profil.
class TutorCoachScreen extends StatefulWidget {
  const TutorCoachScreen({super.key});

  @override
  State<TutorCoachScreen> createState() => _TutorCoachScreenState();
}

class _TutorCoachScreenState extends State<TutorCoachScreen> {
  final _db = DatabaseService();

  bool _loading = true;
  String? _examen;
  String? _classe;
  String? _serie;
  List<Exam> _exams = [];
  List<MasteryItem> _weak = [];
  List<ReviewItem> _due = [];
  List<Chapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exams = await _db.getExams();
    final weak = await _db.weakChapters(limit: 6);
    final due = await _db.dueReviews(limit: 6);
    final chapters = await _db.getChapters();
    final user = await AuthService().getCurrentUser();
    Map<String, dynamic>? p;
    if (user != null) p = await _db.getUserProfile(user.$id);
    if (mounted) {
      setState(() {
        _exams = exams;
        _weak = weak;
        _due = due;
        _chapters = chapters;
        _examen = p?['examen']?.toString();
        _classe = p?['classe']?.toString();
        _serie = p?['serie']?.toString();
        _loading = false;
      });
    }
  }

  String _norm(String s) =>
      s.toLowerCase().trim();

  Exam? get _matchedExam {
    final ex = _norm(_examen ?? '');
    if (ex.isEmpty || _exams.isEmpty) return null;
    final key = ex.split(' ').first;
    Exam? best;
    for (final e in _exams) {
      final lab = _norm(e.label);
      final ok = key.length >= 3 && (lab.contains(key.substring(0, key.length > 5 ? 5 : key.length)));
      if (!ok) continue;
      final t = e.countdownTarget;
      if (t == null) continue;
      if (best == null || t.isBefore(best.countdownTarget!)) best = e;
    }
    return best;
  }

  int? get _daysToExam {
    final e = _matchedExam;
    final t = e?.countdownTarget;
    if (t == null) return null;
    final d = t.difference(DateTime.now()).inHours / 24.0;
    return d.ceil();
  }

  String get _subtitle {
    final bits = <String>[];
    if (_classe != null && _classe!.isNotEmpty) bits.add(_classe!);
    if (_serie != null && _serie!.isNotEmpty) bits.add('série ${_serie!}');
    return bits.isEmpty ? 'Ton coach de révision' : bits.join(' · ');
  }

  Chapter? _chapterById(String id) {
    for (final c in _chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _openQuiz(String chapterId, String subject) async {
    final ch = _chapterById(chapterId);
    if (ch == null) return;
    await context.push('/cours-quiz', extra: {'chapter': ch, 'subject': subject});
    if (mounted) _load();
  }

  /// Le focus de la semaine : union (révisions dues + points faibles), dédupliqué.
  List<({String chapterId, String subject, String topic})> get _weekFocus {
    final out = <({String chapterId, String subject, String topic})>[];
    final seen = <String>{};
    for (final r in _due) {
      if (seen.add(r.chapterId)) out.add((chapterId: r.chapterId, subject: r.subject, topic: r.topic));
    }
    for (final m in _weak) {
      if (seen.add(m.chapterId)) out.add((chapterId: m.chapterId, subject: m.subject, topic: m.topic));
    }
    return out.take(3).toList();
  }

  void _startSession() {
    final f = _weekFocus;
    if (f.isNotEmpty) {
      _openQuiz(f.first.chapterId, f.first.subject);
    } else {
      context.go('/cours');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/tutor'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mon coach', style: display(17, weight: FontWeight.w700)),
          Text(_subtitle, style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _hero(),
                const SizedBox(height: 16),
                _weekPlan(),
                if (_due.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _sectionTitle('Révisions du jour', _due.length),
                  const SizedBox(height: 10),
                  ..._due.map((r) => _row(Icons.refresh_rounded, r.topic.isNotEmpty ? r.topic : 'Chapitre',
                      r.subject.isNotEmpty ? '${r.subject} · à réviser' : 'à réviser', () => _openQuiz(r.chapterId, r.subject))),
                ],
                if (_weak.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _sectionTitle('Points faibles', _weak.length),
                  const SizedBox(height: 10),
                  ..._weak.map(_weakRow),
                ],
                if (_due.isEmpty && _weak.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: EmptyState(
                      art: LeoMascot(size: 92, mood: LeoMood.encourage),
                      icon: Icons.insights_rounded,
                      title: 'Fais un premier quiz',
                      message: 'Dès que tu passes des QCM, Léo repère tes points faibles et te programme des révisions.',
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: GestureDetector(
                  onTap: _startSession,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: OC.grad,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Démarrer ma session', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _hero() {
    final days = _daysToExam;
    final exam = _matchedExam;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (days != null && days >= 0 && exam != null) ...[
            Text('J-$days', style: display(34, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('avant ${exam.label}', style: body(13, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w600)),
          ] else ...[
            Text('Prépare ton examen', style: display(20, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(_examen != null && _examen!.isNotEmpty ? _examen! : 'Programme MINESEC',
                style: body(13, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w600)),
          ],
        ])),
        const SizedBox(width: 10),
        const LeoMascot(size: 64, mood: LeoMood.encourage),
      ]),
    );
  }

  Widget _weekPlan() {
    final focus = _weekFocus;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.o50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_rounded, size: 18, color: OC.o600),
          const SizedBox(width: 8),
          Text('Plan de la semaine', style: body(13.5, weight: FontWeight.w800, color: OC.o700)),
        ]),
        const SizedBox(height: 8),
        if (focus.isEmpty)
          Text('Passe quelques QCM et Léo te composera un plan ciblé.',
              style: body(12.5, color: OC.o700, weight: FontWeight.w500).copyWith(height: 1.4))
        else
          Text('Concentre-toi sur : ${focus.map((f) => f.topic.isNotEmpty ? f.topic : f.subject).join(' · ')}.',
              style: body(12.5, color: OC.o700, weight: FontWeight.w600).copyWith(height: 1.4)),
      ]),
    );
  }

  Widget _sectionTitle(String t, int n) => Row(children: [
        Text(t, style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
          child: Text('$n', style: body(11, weight: FontWeight.w800, color: OC.o700)),
        ),
      ]);

  Widget _row(IconData icon, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _weakRow(MasteryItem m) {
    final pct = (m.mastery * 100).round();
    final col = m.mastery >= 0.6 ? OC.good : (m.mastery >= 0.4 ? OC.warn : OC.bad);
    return GestureDetector(
      onTap: () => _openQuiz(m.chapterId, m.subject),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          OBRing(pct: m.mastery, size: 38, color: col, track: OC.line,
              center: Text('$pct%', style: mono(9, weight: FontWeight.w800, color: col))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.topic.isNotEmpty ? m.topic : 'Chapitre', maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(m.subject.isNotEmpty ? '${m.subject} · à renforcer' : 'à renforcer', style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}
