/// Une épreuve d'annale (gérée par l'admin, collection `annales`).
///
/// Un document = UNE ressource (sujet / corrigé / vidéo) rattachée à un
/// examen → série/spécialité → matière → année. La page de détail regroupe les
/// documents qui partagent (exam, track, subject, year).
class Annale {
  final String id;
  final String exam; // ex. « Baccalauréat » (clé de la taxonomie)
  final String track; // série/spécialité (libellé exact de la feuille), vide si non pertinent
  final String subject; // matière, ex. « Mathématiques »
  final String year; // ex. « 2024 »
  final String session; // ex. « Juin », « Session normale »
  final String type; // sujet | corrige | video
  final String title; // titre affiché
  final String? fileUrl; // PDF/vidéo — storage Appwrite ou lien externe
  final bool premium;
  final int order;

  const Annale({
    required this.id,
    required this.exam,
    this.track = '',
    required this.subject,
    this.year = '',
    this.session = '',
    this.type = 'sujet',
    this.title = '',
    this.fileUrl,
    this.premium = false,
    this.order = 0,
  });

  bool get isVideo => type == 'video';
  bool get isCorrige => type == 'corrige';
  bool get isSujet => !isVideo && !isCorrige;
  bool get hasFile => (fileUrl ?? '').trim().isNotEmpty;

  /// Clé d'une épreuve (regroupe sujet/corrigé/vidéo d'un même examen/série/
  /// matière/année). Sert d'identité pour les favoris et récents.
  String get groupKey => '$exam|$track|$subject|$year';

  factory Annale.fromMap(Map<String, dynamic> d, {required String id}) {
    final ord = d['order'];
    final t = (d['type'] ?? '').toString().trim().toLowerCase();
    return Annale(
      id: id,
      exam: (d['exam'] ?? '').toString().trim(),
      track: (d['track'] ?? '').toString().trim(),
      subject: (d['subject'] ?? '').toString().trim(),
      year: (d['year'] ?? '').toString().trim(),
      session: (d['session'] ?? '').toString().trim(),
      type: t.isEmpty ? 'sujet' : t,
      title: (d['title'] ?? '').toString().trim(),
      fileUrl: _s(d['fileUrl']),
      premium: d['premium'] == true,
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Référence légère d'une épreuve, passée à l'écran de détail via `extra`.
class AnnaleRef {
  final String exam;
  final String track;
  final String subject;
  final String year;
  final String title;

  const AnnaleRef({
    required this.exam,
    this.track = '',
    required this.subject,
    this.year = '',
    this.title = '',
  });

  String get groupKey => '$exam|$track|$subject|$year';

  Map<String, dynamic> toJson() => {
        'exam': exam,
        'track': track,
        'subject': subject,
        'year': year,
        'title': title,
      };

  factory AnnaleRef.fromJson(Map<String, dynamic> m) => AnnaleRef(
        exam: (m['exam'] ?? '').toString(),
        track: (m['track'] ?? '').toString(),
        subject: (m['subject'] ?? '').toString(),
        year: (m['year'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
      );
}

/// Arguments du lecteur PDF (passés via `extra`).
class PdfArgs {
  final String title;
  final String subtitle;
  final String? url; // lien réseau (Appwrite ou externe)
  final String? localPath; // fichier téléchargé (hors-ligne) — prioritaire

  const PdfArgs({required this.title, this.subtitle = '', this.url, this.localPath});
}
