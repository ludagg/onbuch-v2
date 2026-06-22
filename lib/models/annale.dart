/// Un document d'annales géré par l'admin (collection `annales`).
/// Souple : le corrigé et la vidéo sont **facultatifs**, et le `category`
/// couvre aussi les cours, fiches de révision et TD.
class Annale {
  final String id;
  final String exam;
  final String track;
  final String subject;
  final String category; // Épreuve / Cours / Fiche de révision / TD / Autre
  final String year;
  final String session;
  final String title;
  final String fileUrl; // PDF principal (sujet / cours / fiche) — peut être vide
  final String corrigeUrl; // facultatif
  final String videoUrl; // facultatif
  final bool premium;
  final DateTime createdAt;

  const Annale({
    required this.id,
    required this.exam,
    required this.track,
    required this.subject,
    required this.category,
    required this.year,
    required this.session,
    required this.title,
    required this.fileUrl,
    required this.corrigeUrl,
    required this.videoUrl,
    required this.premium,
    required this.createdAt,
  });

  bool get hasPdf => fileUrl.trim().isNotEmpty;
  bool get hasCorrige => corrigeUrl.trim().isNotEmpty;
  bool get hasVideo => videoUrl.trim().isNotEmpty;

  /// Formats disponibles, dérivés des liens présents (jamais bloquant).
  List<String> get formats => [
        if (hasPdf) 'pdf',
        if (hasCorrige) 'corrige',
        if (hasVideo) 'video',
      ];

  /// Le document concerne-t-il une série donnée ? Tolérant aux imports : le
  /// `track` peut être le **code** (« D »), le **libellé complet** (« D — … »),
  /// ou **vide** (document général, applicable à toutes les séries).
  bool appliesToSerie(String code, String label) {
    final t = track.trim().toLowerCase();
    if (t.isEmpty) return true; // général
    final c = code.trim().toLowerCase();
    final l = label.trim().toLowerCase();
    if (c.isNotEmpty && t == c) return true;
    if (l.isNotEmpty && t == l) return true;
    // « D — … » : le libellé commence par le code du track.
    if (t.length <= 4 && (l.startsWith('$t ') || l.startsWith('$t—') || l.startsWith('$t —'))) return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam': exam,
        'track': track,
        'subject': subject,
        'category': category,
        'year': year,
        'session': session,
        'title': title,
        'fileUrl': fileUrl,
        'corrigeUrl': corrigeUrl,
        'videoUrl': videoUrl,
        'premium': premium,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Annale.fromJson(Map<String, dynamic> j) =>
      Annale.fromMap(j, id: (j['id'] ?? '').toString(), createdAt: (j['createdAt'] ?? '').toString());

  static String _s(dynamic v) => (v ?? '').toString().trim();

  factory Annale.fromMap(Map<String, dynamic> d, {required String id, String? createdAt}) => Annale(
        id: id,
        exam: _s(d['exam']),
        track: _s(d['track']),
        subject: _s(d['subject']),
        category: _s(d['category']).isEmpty ? 'Épreuve' : _s(d['category']),
        year: _s(d['year']),
        session: _s(d['session']),
        title: _s(d['title']),
        fileUrl: _s(d['fileUrl']),
        corrigeUrl: _s(d['corrigeUrl']),
        videoUrl: _s(d['videoUrl']),
        premium: d['premium'] == true,
        createdAt: DateTime.tryParse(_s(createdAt)) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}
