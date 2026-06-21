import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';

/// Résultat d'un quiz (section E) : score visuel, statistiques, questions à
/// revoir, et relances (revoir le cours / recommencer).
class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic>? data;
  const QuizResultScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final d = data ?? const {};
    final questions = (d['questions'] as List?)?.cast<QuizQuestion>() ?? const <QuizQuestion>[];
    final answers = (d['answers'] as Map?)?.cast<int, int>() ?? const <int, int>{};
    final seconds = (d['seconds'] as int?) ?? 0;
    final chapter = d['chapter'] as Chapter?;
    final subject = (d['subject'] as String?) ?? '';

    final total = questions.length;
    var correct = 0;
    final wrong = <int>[];
    for (var i = 0; i < total; i++) {
      if (answers[i] == questions[i].answer) {
        correct++;
      } else {
        wrong.add(i);
      }
    }
    final pct = total == 0 ? 0.0 : correct / total;
    final good = pct >= 0.6;
    final msg = pct >= 0.8 ? 'Bravo, tu maîtrises !' : (pct >= 0.5 ? 'Bien — encore un effort.' : 'Revois le cours et réessaie.');

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Résultat'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // Score
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: good ? OC.goodBg : OC.warnBg, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              LeoMascot(size: 88, mood: good ? LeoMood.celebrate : LeoMood.encourage),
              const SizedBox(height: 8),
              SizedBox(
                width: 96, height: 96,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 96, height: 96,
                    child: CircularProgressIndicator(
                      value: pct, strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation(good ? OC.good : OC.warn),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text('${(pct * 100).round()}%', style: display(20, weight: FontWeight.w800, color: good ? OC.waInk : OC.warn)),
                ]),
              ),
              const SizedBox(height: 14),
              Text('$correct / $total', style: display(24, weight: FontWeight.w800, color: good ? OC.waInk : OC.warn)),
              const SizedBox(height: 4),
              Text(msg, style: body(13, color: OC.ink2, weight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(children: [
            _stat('$correct', 'Justes', OC.good),
            const SizedBox(width: 10),
            _stat('${wrong.length}', 'Erreurs', OC.bad),
            const SizedBox(width: 10),
            _stat(_fmt(seconds), 'Temps', OC.ink2),
          ]),
          const SizedBox(height: 20),

          // À revoir
          if (wrong.isNotEmpty) ...[
            Text('À revoir', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 10),
            ...wrong.map((i) => _reviewCard(i + 1, questions[i])),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.emoji_events_rounded, size: 20, color: OC.good),
                const SizedBox(width: 10),
                Expanded(child: Text('Sans-faute ! Tu maîtrises ce chapitre.',
                    style: body(13, weight: FontWeight.w700, color: OC.waInk))),
              ]),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(color: OC.paper, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: OC.line2, width: 1.5), foregroundColor: OC.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => chapter == null
                  ? context.go('/cours')
                  : context.pushReplacement('/cours-chapter', extra: {'chapter': chapter, 'subject': subject}),
              child: const Text('Revoir le cours', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => chapter == null
                  ? context.go('/cours')
                  : context.pushReplacement('/cours-quiz', extra: {'chapter': chapter, 'subject': subject}),
              child: const Text('Recommencer', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
          child: Column(children: [
            Text(value, style: display(18, weight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _reviewCard(int num, QuizQuestion q) {
    final correct = q.answer >= 0 && q.answer < q.options.length ? q.options[q.answer] : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Q$num · ${q.question}', style: body(13, weight: FontWeight.w700).copyWith(height: 1.3)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.check_circle_rounded, size: 16, color: OC.good),
          const SizedBox(width: 7),
          Expanded(child: Text('Réponse : $correct', style: body(12.5, weight: FontWeight.w700, color: OC.waInk))),
        ]),
        if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(q.explanation!, style: body(12, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
        ],
      ]),
    );
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
