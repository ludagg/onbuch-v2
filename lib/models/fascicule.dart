/// Fascicule = un livre PDF OnBuch (cours + exercices complets), publié par
/// l'admin (collection `fascicules`) et lu dans l'app via le lecteur PDF des
/// annales. Le PDF et la couverture sont stockés dans le bucket `annales_files`.
class Fascicule {
  final String id;
  final String title;        // ex. « Mathématiques — Terminale C »
  final String subject;      // ex. « Mathématiques »
  final String level;        // ex. « Terminale C »
  final String exam;         // ex. « Baccalauréat » — vide = tous
  final String track;        // séries, ex. « C,D,E,TI » — vide = toutes
  final String description;
  final String coverUrl;     // image de couverture (peut être vide)
  final String pdfUrl;       // PDF du fascicule
  final String author;
  final int pages;
  final bool premium;
  final int order;
  final bool active;
  final int price;           // prix en FCFA (0 = sur demande)
  final String benefits;     // avantages (1 par ligne) — facultatif

  const Fascicule({
    required this.id,
    required this.title,
    this.subject = '',
    this.level = '',
    this.exam = '',
    this.track = '',
    this.description = '',
    this.coverUrl = '',
    this.pdfUrl = '',
    this.author = '',
    this.pages = 0,
    this.premium = false,
    this.order = 0,
    this.active = true,
    this.price = 0,
    this.benefits = '',
  });

  bool get hasCover => coverUrl.trim().isNotEmpty;
  bool get hasPdf => pdfUrl.trim().isNotEmpty;

  /// Prix formaté (« 2 500 FCFA ») ou null si sur demande.
  String? get priceLabel {
    if (price <= 0) return null;
    final s = price.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b FCFA';
  }

  /// Liste d'avantages : ceux saisis par l'admin, sinon une liste par défaut.
  List<String> get benefitList {
    final custom = benefits
        .split(RegExp(r'[\n|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (custom.isNotEmpty) return custom;
    return const [
      'Cours complet, conforme au programme MINESEC',
      'Méthodes et astuces pour gagner des points',
      'Exercices d\'application + corrigés détaillés',
      'Sujets types d\'examen pour s\'entraîner',
    ];
  }

  /// Sous-titre court pour les cartes (matière/classe ou nb de pages).
  String get shelfSubtitle {
    final lvl = level.trim();
    if (lvl.isNotEmpty) return lvl;
    if (subject.trim().isNotEmpty) return subject.trim();
    return pages > 0 ? '$pages pages' : '';
  }

  /// Visible pour un couple (examen, série) donné. Tolérant : un champ vide =
  /// « tous ». Le `track` accepte plusieurs séries séparées par , / ;.
  bool appliesTo({String? exam, String? serie}) {
    final ex = (exam ?? '').trim().toLowerCase();
    final myEx = this.exam.trim().toLowerCase();
    if (myEx.isNotEmpty && ex.isNotEmpty && myEx != ex) return false;
    final raw = track.trim().toLowerCase();
    final s = (serie ?? '').trim().toLowerCase();
    if (raw.isEmpty || s.isEmpty) return true;
    for (final t in raw.split(RegExp(r'[,/;]')).map((x) => x.trim()).where((x) => x.isNotEmpty)) {
      if (t == s) return true;
      if (t.length <= 4 && (s.startsWith(t) || t.startsWith(s))) return true;
    }
    return false;
  }

  factory Fascicule.fromMap(Map<String, dynamic> m) {
    String s(dynamic v) => (v ?? '').toString();
    int i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    return Fascicule(
      id: s(m['\$id']),
      title: s(m['title']),
      subject: s(m['subject']),
      level: s(m['level']),
      exam: s(m['exam']),
      track: s(m['track']),
      description: s(m['description']),
      coverUrl: s(m['coverUrl']),
      pdfUrl: s(m['pdfUrl']),
      author: s(m['author']),
      pages: i(m['pages']),
      premium: m['premium'] == true,
      order: i(m['order']),
      active: m['active'] != false,
      price: i(m['price']),
      benefits: s(m['benefits']),
    );
  }
}
