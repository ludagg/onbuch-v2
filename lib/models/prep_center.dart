/// Centre de préparation aux concours (géré par l'admin).
class PrepCenter {
  final String id;
  final String name;
  final String city;
  final String? description;
  final String? specialties; // liste séparée par des virgules
  final String? imageUrl;
  final String? phone; // WhatsApp / téléphone
  final String? link; // site / inscription
  final String? address;
  final String? eventTitle; // prochain événement
  final DateTime? eventDate;
  final int order;

  const PrepCenter({
    required this.id,
    required this.name,
    required this.city,
    this.description,
    this.specialties,
    this.imageUrl,
    this.phone,
    this.link,
    this.address,
    this.eventTitle,
    this.eventDate,
    this.order = 0,
  });

  List<String> get specialtyList => (specialties ?? '')
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory PrepCenter.fromMap(Map<String, dynamic> d, {required String id}) {
    DateTime? dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    final ord = d['order'];
    return PrepCenter(
      id: id,
      name: (d['name'] ?? 'Centre').toString(),
      city: (d['city'] ?? '').toString(),
      description: _s(d['description']),
      specialties: _s(d['specialties']),
      imageUrl: _s(d['imageUrl']),
      phone: _s(d['phone']),
      link: _s(d['link']),
      address: _s(d['address']),
      eventTitle: _s(d['eventTitle']),
      eventDate: dt(d['eventDate']),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
