/// Ressource de préparation aux concours (annales, guide, vidéo…), admin.
class ConcoursResource {
  final String id;
  final String title;
  final String type; // annales · guide · video · fiche · site
  final String? description;
  final String? url;
  final String? concours; // concours ciblé (optionnel)
  final int order;

  const ConcoursResource({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.url,
    this.concours,
    this.order = 0,
  });

  factory ConcoursResource.fromMap(Map<String, dynamic> d, {required String id}) {
    final ord = d['order'];
    return ConcoursResource(
      id: id,
      title: (d['title'] ?? '').toString(),
      type: (d['type'] ?? 'guide').toString().trim().toLowerCase(),
      description: _s(d['description']),
      url: _s(d['url']),
      concours: _s(d['concours']),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
