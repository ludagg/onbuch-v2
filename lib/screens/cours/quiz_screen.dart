import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../services/database_service.dart';
import '../../services/tutor_service.dart';
import '../../services/analytics_service.dart';

/// Quiz/QCM (refonte « Nomad Educ ») : une question à la fois, minuteur, barre
/// de progression, puis écran de résultat.
class QuizScreen extends StatefulWidget {
  final Chapter? chapter;
  final String? subjectName;
  const QuizScreen({super.key, this.chapter, this.subjectName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _db = DatabaseService();
  final _tutor = TutorService();

  List<QuizQuestion>? _questions;
  Object? _error;
  bool _loading = true;

  int _index = 0;
  final Map<int, int> _answers = {};
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final c = widget.chapter;
    if (c == null) {
      setState(() { _loading = false; _error = 'Chapitre introuvable.'; });
      return;
    }
    setState(() { _loading = true; _error = null; _index = 0; _answers.clear(); _seconds = 0; });
    try {
      var qs = await _db.getQuiz(c.id);
      qs ??= parseQuiz(await _tutor.analyzeExercise(text: 'Chapitre : ${c.title}', mode: 'quiz', chapterId: c.id));
      if (qs == null || qs.isEmpty) throw 'Quiz indisponible pour le moment. Réessaie.';
      if (!mounted) return;
      setState(() { _questions = qs; _loading = false; });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _next() {
    final qs = _questions!;
    if (_index < qs.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    final c = widget.chapter;
    if (c != null) _db.markChapterViewed(c.id);
    final qs = _questions ?? const <QuizQuestion>[];
    final correct = [for (var i = 0; i < qs.length; i++) if (_answers[i] == qs[i].answer) 1].length;
    AnalyticsService.logEvent('quiz_completed', {'total': qs.length, 'correct': correct});
    context.pushReplacement('/cours-quiz-result', extra: {
      'questions': _questions,
      'answers': Map<int, int>.from(_answers),
      'seconds': _seconds,
      'chapter': c,
      'subject': widget.subjectName ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: _loading ? _loadingView() : (_error != null ? _errorView() : _quizView()),
      ),
    );
  }

  Widget _loadingView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: OC.o500, strokeWidth: 3)),
            const SizedBox(height: 18),
            Text('Préparation du quiz…', style: body(14.5, weight: FontWeight.w600, color: OC.ink2)),
            const SizedBox(height: 6),
            Text('Quelques secondes pour générer les questions.',
                textAlign: TextAlign.center, style: body(12.5, color: OC.muted)),
          ]),
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 42, color: OC.bad),
            const SizedBox(height: 12),
            Text('$_error', textAlign: TextAlign.center, style: body(14, color: OC.ink2).copyWith(height: 1.4)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
                child: Text('Réessayer', style: body(14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      );

  Widget _quizView() {
    final qs = _questions!;
    final q = qs[_index];
    final answered = _answers.containsKey(_index);
    final last = _index == qs.length - 1;
    return Column(children: [
      // Top bar : back + timer + index
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/cours'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_outlined, size: 14, color: OC.o600),
              const SizedBox(width: 5),
              Text(_fmt(_seconds), style: mono(12.5, weight: FontWeight.w700, color: OC.o700)),
            ]),
          ),
          const SizedBox(width: 10),
          Text('Q ${_index + 1}/${qs.length}', style: body(12.5, weight: FontWeight.w800, color: OC.ink2)),
        ]),
      ),
      // Progress
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_index + 1) / qs.length, minHeight: 6,
            backgroundColor: OC.panel, valueColor: const AlwaysStoppedAnimation(OC.o500),
          ),
        ),
      ),
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QUESTION ${_index + 1}', style: body(10.5, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 0.06 * 10.5)),
              const SizedBox(height: 8),
              Text(q.question, style: body(15, weight: FontWeight.w700, color: OC.ink).copyWith(height: 1.35)),
            ]),
          ),
          const SizedBox(height: 16),
          ...List.generate(q.options.length, (oi) => _option(oi, q)),
        ],
      )),
      // Bottom
      Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(color: OC.paper, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: GestureDetector(
          onTap: answered ? _next : null,
          child: Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(
              gradient: answered ? OC.grad : null,
              color: answered ? null : OC.line2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(last ? 'Terminer' : 'Valider', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _option(int oi, QuizQuestion q) {
    final selected = _answers[_index] == oi;
    return GestureDetector(
      onTap: () => setState(() => _answers[_index] = oi),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? OC.o50 : OC.paper,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? OC.o500 : OC.line2, width: selected ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 26, height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? OC.o500 : Colors.transparent,
              border: Border.all(color: selected ? OC.o500 : OC.line2, width: 2),
            ),
            child: Text(String.fromCharCode(65 + oi),
                style: body(11.5, weight: FontWeight.w800, color: selected ? Colors.white : OC.ink2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(q.options[oi], style: body(13.5, weight: FontWeight.w600, color: OC.ink).copyWith(height: 1.3))),
        ]),
      ),
    );
  }
}
