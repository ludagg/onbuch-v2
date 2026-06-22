import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Accueil du module Cours, réorganisé autour des « packs » (matières) :
/// recherche, catégories (niveaux), carrousel des packs populaires et liste
/// complète des packs avec anneaux de progression.
class CoursScreen extends StatefulWidget {
  const CoursScreen({super.key});

  @override
  State<CoursScreen> createState() => _CoursScreenState();
}

class _CoursScreenState extends State<CoursScreen> {
  final _db = DatabaseService();
  List<Subject> _subjects = [];
  List<Chapter> _chapters = [];
  Set<String> _viewed = {};
  String? _classe;
  bool _loading = true;
  String _cat = 'Tout';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await _db.getSubjects();
    final chapters = await _db.getChapters();
    final viewed = await _db.getViewedChapterIds();
    String? classe;
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      final p = await _db.getUserProfile(user.$id);
      classe = p?['classe']?.toString();
    }
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _chapters = chapters;
        _viewed = viewed;
        _classe = classe;
        _loading = false;
      });
    }
  }

  List<Subject> get _visible {
    final v = _subjects.where((s) => s.appliesTo(_classe)).toList();
    return v.isEmpty ? _subjects : v;
  }

  /// Catégories dérivées des niveaux des matières visibles (ordre d'apparition).
  List<String> get _categories {
    final out = <String>['Tout'];
    for (final s in _visible) {
      for (final raw in s.levels.split(RegExp(r'[,;]'))) {
        final l = raw.trim();
        if (l.isNotEmpty && !out.any((e) => e.toLowerCase() == l.toLowerCase())) {
          out.add(l);
        }
      }
    }
    return out;
  }

  /// Packs filtrés par la catégorie active.
  List<Subject> get _filtered {
    if (_cat == 'Tout') return _visible;
    final c = _cat.toLowerCase();
    return _visible.where((s) => s.levels.toLowerCase().contains(c)).toList();
  }

  /// Packs « populaires » : ceux qui ont le plus de chapitres (proxy, en
  /// l'absence d'un champ de popularité réel).
  List<Subject> get _popular {
    final l = _visible.where((s) => _chaptersOf(s.id).isNotEmpty).toList();
    l.sort((a, b) => _chaptersOf(b.id).length.compareTo(_chaptersOf(a.id).length));
    return l.take(5).toList();
  }

  List<Chapter> _chaptersOf(String subjectId) {
    final l = _chapters.where((c) => c.subjectId == subjectId).toList();
    l.sort((a, b) => a.order.compareTo(b.order));
    return l;
  }

  int _doneOf(List<Chapter> chs) => chs.where((c) => _viewed.contains(c.id)).length;

  Future<void> _openPack(Subject s) async {
    await context.push('/cours-subject', extra: s);
    if (mounted) _load();
  }

  String? _level(Subject s) {
    final parts = s.levels.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    return parts.isEmpty ? null : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final totalCh = _chapters.length;
    final doneCh = _chapters.where((c) => _viewed.contains(c.id)).length;
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: OC.bg,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 18,
          title: const OBWordmark(size: 23),
          actions: obTopActions(context),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cours', style: display(24, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(_classe != null && _classe!.isNotEmpty ? '$_classe · MINESEC' : 'Programme MINESEC',
                  style: body(13, color: OC.ink2, weight: FontWeight.w500)),
              const SizedBox(height: 16),

              // Recherche transverse
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/cours-search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: OC.line2, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(Icons.search_rounded, size: 19, color: OC.muted),
                    const SizedBox(width: 11),
                    Text('Trouve un pack ou une matière…', style: body(13.5, color: OC.muted, weight: FontWeight.w500)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              if (_loading)
                Column(children: const [
                  Skeleton(width: double.infinity, height: 64, radius: 20),
                  SizedBox(height: 18),
                  SkeletonCard(),
                  SizedBox(height: 18),
                  SkeletonList(count: 3),
                ])
              else if (_subjects.isEmpty)
                const EmptyState(
                  art: LeoMascot(size: 96, mood: LeoMood.wave),
                  icon: Icons.menu_book_rounded,
                  title: 'Bientôt disponible',
                  message: 'Les matières de ton programme arriveront ici.',
                )
              else ...[
                _progressStrip(totalCh, doneCh),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),

        if (!_loading && _subjects.isNotEmpty) ...[
          // Catégories
          if (_categories.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return GestureDetector(
                      onTap: () => setState(() => _cat = cat),
                      child: OBChip(cat, active: cat == _cat),
                    );
                  },
                ),
              ),
            ),

          // Packs populaires
          if (_popular.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SecHead(title: 'Packs populaires', action: null),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 192,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _popular.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _popularCard(_popular[i]),
                ),
              ),
            ),
          ],

          // Tous les packs (filtrés par catégorie)
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SecHead(title: 'Tous les packs', action: null),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => Appear(index: i, child: _packRow(_filtered[i])),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Bandeau de progression ────────────────────────────────────────────────
  Widget _progressStrip(int total, int done) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [OC.darkHero, OC.darkHero2]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        OBRing(pct: pct, size: 52, color: OC.o500, track: Colors.white24,
            center: Text('${(pct * 100).round()}%', style: mono(13, weight: FontWeight.w800, color: Colors.white))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ta progression', style: body(13.5, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('$done leçon${done > 1 ? 's' : ''} terminée${done > 1 ? 's' : ''} sur $total',
              style: body(12, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  // ── Carte « pack populaire » (carrousel horizontal) ───────────────────────
  Widget _popularCard(Subject s) {
    final chs = _chaptersOf(s.id);
    final total = chs.length;
    final pct = total == 0 ? 0.0 : _doneOf(chs) / total;
    final lvl = _level(s);
    return GestureDetector(
      onTap: () => _openPack(s),
      child: Container(
        width: 224,
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PackCover(subject: s, height: 96,
              radius: const BorderRadius.vertical(top: Radius.circular(17))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lvl != null ? '${s.name} · $lvl' : s.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(14, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(total == 0 ? 'Bientôt' : '$total chapitre${total > 1 ? 's' : ''}',
                    style: body(11.5, color: OC.muted, weight: FontWeight.w600))),
                OBRing(
                  pct: pct, size: 30,
                  color: total == 0 ? OC.line2 : s.color,
                  track: OC.line,
                  center: total == 0
                      ? Text('–', style: mono(9, weight: FontWeight.w800, color: OC.muted))
                      : Text('${(pct * 100).round()}', style: mono(8, weight: FontWeight.w800, color: s.color)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Ligne « pack » (liste « Tous les packs ») ─────────────────────────────
  Widget _packRow(Subject s) {
    final chs = _chaptersOf(s.id);
    final total = chs.length;
    final pct = total == 0 ? 0.0 : _doneOf(chs) / total;
    final lvl = _level(s);
    return GestureDetector(
      onTap: () => _openPack(s),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          SizedBox(width: 64, child: PackCover(subject: s, height: 64)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14.5, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              if (lvl != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(6)),
                  child: Text(lvl, style: body(10, weight: FontWeight.w800, color: OC.o700)),
                ),
                const SizedBox(width: 8),
              ],
              Text(total == 0 ? 'Bientôt disponible' : '$total chapitre${total > 1 ? 's' : ''}',
                  style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
            ]),
          ])),
          const SizedBox(width: 10),
          OBRing(
            pct: pct, size: 36,
            color: total == 0 ? OC.line2 : s.color,
            track: OC.line,
            center: total == 0
                ? Text('–', style: mono(11, weight: FontWeight.w800, color: OC.muted))
                : Text('${(pct * 100).round()}%', style: mono(9, weight: FontWeight.w800, color: s.color)),
          ),
        ]),
      ),
    );
  }
}
