import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../services/database_service.dart';
import '../../services/tutor_service.dart';

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
  final Map<int, int> _selected = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = widget.chapter;
    if (c == null) {
      setState(() { _loading = false; _error = 'Chapitre introuvable.'; });
      return;
    }
    setState(() { _loading = true; _error = null; _submitted = false; _selected.clear(); });
    try {
      var qs = await _db.getQuiz(c.id);
      if (qs == null) {
        final raw = await _tutor.analyzeExercise(
          text: 'Chapitre : ${c.title}', mode: 'quiz', chapterId: c.id);
        qs = parseQuiz(raw);
      }
      if (qs == null || qs.isEmpty) throw 'Quiz indisponible pour le moment. Réessaie.';
      if (mounted) setState(() { _questions = qs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  int get _score {
    final qs = _questions;
    if (qs == null) return 0;
    var n = 0;
    for (var i = 0; i < qs.length; i++) {
      if (_selected[i] == qs[i].answer) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Quiz'),
      body: _loading
          ? _loadingView()
          : _error != null
              ? _errorView()
              : _quizView(),
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
            const Icon(Icons.error_outline_rounded, size: 42, color: OC.bad),
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
    final subj = widget.subjectName ?? '';
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            if (widget.chapter != null) ...[
              if (subj.isNotEmpty)
                Text(subj.toUpperCase(), style: body(11, weight: FontWeight.w800, color: OC.o600).copyWith(letterSpacing: 0.1 * 11)),
              const SizedBox(height: 4),
              Text(widget.chapter!.title, style: display(20, weight: FontWeight.w700).copyWith(height: 1.15)),
              const SizedBox(height: 16),
            ],
            if (_submitted) _scoreBanner(qs.length),
            ...List.generate(qs.length, (i) => _questionCard(i, qs[i])),
          ],
        ),
      ),
      _bottomBar(qs.length),
    ]);
  }

  Widget _scoreBanner(int total) {
    final s = _score;
    final good = s >= (total / 2).ceil();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: good ? OC.goodBg : OC.warnBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(good ? Icons.emoji_events_rounded : Icons.school_rounded, size: 26, color: good ? OC.good : OC.warn),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Score : $s / $total', style: display(18, weight: FontWeight.w700, color: good ? OC.waInk : OC.warn)),
          const SizedBox(height: 2),
          Text(good ? 'Bien joué ! Continue comme ça.' : 'Revois le cours et réessaie.',
              style: body(12.5, weight: FontWeight.w500, color: OC.ink2)),
        ])),
      ]),
    );
  }

  Widget _questionCard(int qi, QuizQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Question ${qi + 1}', style: body(11.5, weight: FontWeight.w800, color: OC.o600)),
        const SizedBox(height: 6),
        Text(q.question, style: body(14.5, weight: FontWeight.w700).copyWith(height: 1.3)),
        const SizedBox(height: 12),
        ...List.generate(q.options.length, (oi) => _option(qi, oi, q)),
        if (_submitted && q.explanation != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(11), border: Border.all(color: OC.line, width: 1.5)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: OC.o600),
              const SizedBox(width: 8),
              Expanded(child: Text(q.explanation!, style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _option(int qi, int oi, QuizQuestion q) {
    final selected = _selected[qi] == oi;
    Color bg = OC.paper, border = OC.line2;
    Color txt = OC.ink;
    IconData? icon;
    Color iconC = OC.muted;

    if (_submitted) {
      if (oi == q.answer) {
        bg = OC.goodBg; border = OC.good; txt = OC.waInk; icon = Icons.check_circle_rounded; iconC = OC.good;
      } else if (selected) {
        bg = OC.badBg; border = OC.bad; txt = OC.bad; icon = Icons.cancel_rounded; iconC = OC.bad;
      }
    } else if (selected) {
      bg = OC.o50; border = OC.o500; txt = OC.o700;
    }

    return GestureDetector(
      onTap: _submitted ? null : () => setState(() => _selected[qi] = oi),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)),
        child: Row(children: [
          Expanded(child: Text(q.options[oi], style: body(13.5, weight: FontWeight.w600, color: txt).copyWith(height: 1.3))),
          if (icon != null) Icon(icon, size: 19, color: iconC)
          else Container(
            width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? OC.o500 : OC.line2, width: 2),
                color: selected ? OC.o500 : Colors.transparent),
            child: selected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }

  Widget _bottomBar(int total) {
    final allAnswered = _selected.length >= total;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(color: OC.paper, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
      child: SafeArea(top: false, child: GestureDetector(
        onTap: _submitted
            ? _load
            : (allAnswered ? () => setState(() => _submitted = true) : null),
        child: Container(
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            gradient: (_submitted || allAnswered) ? OC.grad : null,
            color: (_submitted || allAnswered) ? null : OC.line2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_submitted ? Icons.refresh_rounded : Icons.check_rounded, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            Text(_submitted ? 'Recommencer' : (allAnswered ? 'Valider' : 'Réponds à toutes les questions'),
                style: body(14, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      )),
    );
  }
}
