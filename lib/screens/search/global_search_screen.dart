import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/article.dart';
import '../../models/course.dart';
import '../../models/concours.dart';
import '../../models/annale.dart';
import '../../services/database_service.dart';

/// Recherche globale transverse : annales, cours, actualités et concours.
class GlobalSearchScreen extends StatefulWidget {
  /// Filtre initial (ex. `annales` depuis la page Annales). Null = « Tout ».
  final String? scope;
  const GlobalSearchScreen({super.key, this.scope});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

enum _Kind { annale, cours, actu, concours }

class _Hit {
  final String title, subtitle;
  final _Kind kind;
  final Object payload; // Annale / Chapter / Article / Concours
  final String? subjectName;
  const _Hit(this.title, this.subtitle, this.kind, this.payload, {this.subjectName});
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _db = DatabaseService();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  List<Article> _articles = [];
  List<Concours> _concours = [];
  List<Annale> _annales = [];
  Map<String, Subject> _subjectById = {};
  List<Chapter> _chapters = [];
  bool _loading = true;
  String _query = '';
  int _filter = 0; // 0 Tout, 1 Annales, 2 Cours, 3 Actus, 4 Concours

  static const _filters = ['Tout', 'Annales', 'Cours', 'Actus', 'Concours'];

  static const _scopeFilter = {'annales': 1, 'cours': 2, 'actus': 3, 'concours': 4};

  @override
  void initState() {
    super.initState();
    _filter = _scopeFilter[widget.scope] ?? 0;
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _db.getArticles(limit: 60),
      _db.getSubjects(),
      _db.getChapters(),
      _db.getConcours(),
      _db.searchAnnales(),
    ]);
    if (!mounted) return;
    setState(() {
      _articles = results[0] as List<Article>;
      _subjectById = {for (final s in results[1] as List<Subject>) s.id: s};
      _chapters = results[2] as List<Chapter>;
      _concours = results[3] as List<Concours>;
      _annales = results[4] as List<Annale>;
      _loading = false;
    });
  }

  List<_Hit> get _hits {
    final qn = _normalize(_query);
    if (qn.isEmpty) return const [];
    final terms = qn.split(' ').where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return const [];

    final scored = <(_Hit, double)>[];
    void consider(_Hit hit, String primary, String secondary) {
      final s = _score(qn, terms, _normalize(primary), _normalize(secondary));
      if (s > 0) scored.add((hit, s));
    }

    if (_filter == 0 || _filter == 1) {
      for (final a in _annales) {
        final sub = [a.subject, a.exam, if (a.year.isNotEmpty) a.year].where((e) => e.isNotEmpty).join(' · ');
        consider(
          _Hit(a.title.isEmpty ? a.subject : a.title, sub.isEmpty ? 'annale' : sub, _Kind.annale, a),
          '${a.title} ${a.subject}', '${a.exam} ${a.category} ${a.year}',
        );
      }
    }
    if (_filter == 0 || _filter == 2) {
      for (final c in _chapters) {
        final sub = _subjectById[c.subjectId];
        consider(
          _Hit(c.title, '${sub?.name ?? 'Cours'} · leçon', _Kind.cours, c, subjectName: sub?.name ?? ''),
          c.title, sub?.name ?? '',
        );
      }
    }
    if (_filter == 0 || _filter == 3) {
      for (final a in _articles) {
        consider(_Hit(a.title, '${a.category} · actualité', _Kind.actu, a), a.title, a.category);
      }
    }
    if (_filter == 0 || _filter == 4) {
      for (final c in _concours) {
        consider(
          _Hit(c.name, '${c.organizer.isEmpty ? 'Concours' : c.organizer} · concours', _Kind.concours, c),
          c.name, c.organizer,
        );
      }
    }

    // Classement : du plus pertinent au moins pertinent.
    scored.sort((x, y) => y.$2.compareTo(x.$2));
    return [for (final s in scored) s.$1];
  }

  // ── Recherche élastique : normalisation + score de pertinence ────────────────

  /// Minuscule + suppression des accents + réduction aux alphanumériques.
  static String _normalize(String s) {
    s = s.toLowerCase();
    const map = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
      'û': 'u', 'ü': 'u', 'ù': 'u', 'ú': 'u',
      'ç': 'c', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
    };
    final b = StringBuffer();
    for (final ch in s.split('')) {
      b.write(map[ch] ?? ch);
    }
    return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Score de pertinence d'un document (primaire = titre, secondaire = annexes).
  /// Plus c'est haut, plus c'est pertinent. 0 = non pertinent (écarté).
  static double _score(String qn, List<String> terms, String primary, String secondary) {
    double score = 0;
    // Correspondances globales sur le titre (phrase entière).
    if (primary == qn) {
      score += 120;
    } else if (primary.startsWith(qn)) {
      score += 60;
    } else if (primary.contains(qn)) {
      score += 32;
    }
    if (secondary.contains(qn)) score += 8;

    final pTokens = primary.split(' ').where((t) => t.isNotEmpty).toList();
    final sTokens = secondary.split(' ').where((t) => t.isNotEmpty).toList();

    var matched = 0;
    for (final term in terms) {
      double best = 0;
      // Titre.
      if (primary.contains(term)) best = 18;
      for (final tok in pTokens) {
        if (tok == term) {
          if (best < 26) best = 26;
        } else if (tok.startsWith(term)) {
          if (best < 17) best = 17;
        } else if (term.length >= 3) {
          final d = _fuzzy(tok, term);
          if (d >= 0) {
            final v = 15 - d * 4;
            if (v > best) best = v.toDouble();
          }
        }
      }
      // Champ secondaire (poids moindre).
      if (best < 7) {
        if (secondary.contains(term)) {
          if (best < 7) best = 7;
        } else {
          for (final tok in sTokens) {
            if (tok.startsWith(term)) {
              if (best < 6) best = 6;
            } else if (term.length >= 3) {
              final d = _fuzzy(tok, term);
              if (d >= 0) {
                final v = 5 - d * 2;
                if (v > best) best = v.toDouble();
              }
            }
          }
        }
      }
      if (best > 0) {
        matched++;
        score += best;
      }
    }

    if (matched == 0) return 0;
    if (matched == terms.length) {
      score += 12; // bonus : tous les mots de la requête sont présents
    } else {
      score *= matched / terms.length; // pénalise les mots manquants
    }
    return score;
  }

  /// Distance d'édition entre [a] et [b] si elle est tolérable, sinon -1.
  /// Tolérance : 1 faute pour un mot court, 2 pour un mot long.
  static int _fuzzy(String a, String b) {
    final maxD = b.length <= 4 ? 1 : 2;
    if ((a.length - b.length).abs() > maxD) return -1;
    final d = _lev(a, b, maxD);
    return d <= maxD ? d : -1;
  }

  /// Levenshtein avec coupure anticipée à [maxD].
  static int _lev(String a, String b, int maxD) {
    final n = a.length, m = b.length;
    if (n == 0) return m;
    if (m == 0) return n;
    var prev = List<int>.generate(m + 1, (i) => i);
    for (var i = 1; i <= n; i++) {
      final cur = List<int>.filled(m + 1, 0);
      cur[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= m; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var v = cur[j - 1] + 1;
        if (prev[j] + 1 < v) v = prev[j] + 1;
        if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
        cur[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > maxD) return maxD + 1; // au-delà de la tolérance → on coupe
      prev = cur;
    }
    return prev[m];
  }

  void _open(_Hit h) {
    switch (h.kind) {
      case _Kind.annale:
        context.push('/annales/detail', extra: h.payload as Annale);
        break;
      case _Kind.cours:
        context.push('/cours-chapter', extra: {'chapter': h.payload as Chapter, 'subject': h.subjectName ?? ''});
        break;
      case _Kind.actu:
        context.push('/article', extra: h.payload as Article);
        break;
      case _Kind.concours:
        context.push('/concours-detail', extra: h.payload as Concours);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              ),
              Expanded(child: Container(
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.ink, width: 1.6)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(Icons.search_rounded, size: 18, color: OC.ink2),
                  const SizedBox(width: 9),
                  Expanded(child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    style: body(14, color: OC.ink),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Annale, cours, actu, concours…',
                      hintStyle: body(14, color: OC.muted),
                    ),
                  )),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() { _ctrl.clear(); _query = ''; }),
                      child: Icon(Icons.close_rounded, size: 18, color: OC.muted),
                    ),
                ]),
              )),
            ]),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final on = i == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = i),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: on ? OC.ink : OC.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: on ? OC.ink : OC.line2, width: 1.5),
                    ),
                    child: Text(_filters[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: OC.o500))
              : _query.trim().isEmpty
                  ? const EmptyState(
                      art: LeoMascot(size: 104, mood: LeoMood.wave),
                      icon: Icons.search_rounded,
                      title: 'Cherche dans OnBuch',
                      message: 'Annales, cours, actualités, concours — tout au même endroit.',
                    )
                  : hits.isEmpty
                      ? EmptyState(icon: Icons.search_off_rounded, title: 'Aucun résultat', message: 'Rien pour « $_query ».')
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                          children: [
                            Text('${hits.length} résultat${hits.length > 1 ? 's' : ''}', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            for (var i = 0; i < hits.length; i++) Appear(index: i, child: _hitRow(hits[i])),
                          ],
                        )),
        ]),
      ),
    );
  }

  Widget _hitRow(_Hit h) {
    final (icon, c) = switch (h.kind) {
      _Kind.annale => (Icons.description_rounded, const Color(0xFFC0392B)),
      _Kind.actu => (Icons.article_outlined, OC.blue),
      _Kind.concours => (Icons.track_changes_rounded, const Color(0xFF0E9AA0)),
      _Kind.cours => (Icons.menu_book_rounded, OC.o600),
    };
    return GestureDetector(
      onTap: () => _open(h),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 21, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(h.subtitle, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}
