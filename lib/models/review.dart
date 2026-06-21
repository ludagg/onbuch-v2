/// Un élément de révision espacée (collection `review_queue`).
class ReviewItem {
  final String id;
  final String chapterId;
  final String subject;
  final String topic;
  final DateTime dueAt;

  const ReviewItem({
    required this.id,
    required this.chapterId,
    required this.subject,
    required this.topic,
    required this.dueAt,
  });

  factory ReviewItem.fromDoc(String id, Map<String, dynamic> d) => ReviewItem(
        id: id,
        chapterId: (d['chapterId'] ?? '').toString(),
        subject: (d['subject'] ?? '').toString(),
        topic: (d['topic'] ?? '').toString(),
        dueAt: DateTime.tryParse((d['dueAt'] ?? '').toString()) ?? DateTime.now(),
      );

  bool get isDue => !dueAt.isAfter(DateTime.now());
}

/// Maîtrise d'un chapitre (collection `topic_mastery`), pour le coach.
class MasteryItem {
  final String chapterId;
  final String subject;
  final String topic;
  final double mastery; // 0..1
  final int attempts;

  const MasteryItem({
    required this.chapterId,
    required this.subject,
    required this.topic,
    required this.mastery,
    required this.attempts,
  });

  factory MasteryItem.fromDoc(Map<String, dynamic> d) => MasteryItem(
        chapterId: (d['chapterId'] ?? '').toString(),
        subject: (d['subject'] ?? '').toString(),
        topic: (d['topic'] ?? '').toString(),
        mastery: ((d['mastery'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble(),
        attempts: (d['attempts'] as num?)?.toInt() ?? 0,
      );
}

