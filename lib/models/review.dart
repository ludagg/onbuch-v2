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
