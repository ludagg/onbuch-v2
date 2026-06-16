import 'dart:convert';

/// Une question de QCM.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer; // index de la bonne option
  final String? explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.explanation,
  });
}

/// Parse un QCM depuis le texte JSON produit par le Tuteur (tolérant aux
/// balises de code ou texte autour).
List<QuizQuestion>? parseQuiz(String raw) {
  try {
    final m = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    if (m == null) return null;
    final j = jsonDecode(m.group(0)!) as Map<String, dynamic>;
    final qs = j['questions'];
    if (qs is! List) return null;
    final out = <QuizQuestion>[];
    for (final q in qs) {
      if (q is! Map) continue;
      final opts = (q['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (q['q'] == null || opts.length < 2) continue;
      final ans = (q['answer'] as num?)?.toInt() ?? 0;
      out.add(QuizQuestion(
        question: q['q'].toString(),
        options: opts,
        answer: ans.clamp(0, opts.length - 1),
        explanation: q['explanation']?.toString(),
      ));
    }
    return out.isEmpty ? null : out;
  } catch (_) {
    return null;
  }
}
