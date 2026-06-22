import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';

/// Liste des épreuves d'une matière (FRONT seulement, données simulées).
/// Filtres par tags (type + année) et pagination au défilement. Le branchement
/// sur la collection `annales` viendra ensuite.
class AnnaleSubjectScreen extends StatefulWidget {
  final String subject;
  final String? exam;
  final String? filiere;
  const AnnaleSubjectScreen({super.key, required this.subject, this.exam, this.filiere});

  @override
  State<AnnaleSubjectScreen> createState() => _AnnaleSubjectScreenState();
}

class _Epreuve {
  final int year;
  final String session;
  final List<String> formats; // 'pdf' | 'corrige' | 'video'
  final bool premium;
  _Epreuve(this.year, this.session, this.formats, this.premium);
}

class _AnnaleSubjectScreenState extends State<AnnaleSubjectScreen> {
  final _scroll = ScrollController();
  final List<_Epreuve> _all = [];

  static const _pageSize = 8;
  int _shown = _pageSize;
  bool _loadingMore = false;

  String? _type; // null = tous ; sinon 'pdf'|'corrige'|'video'
  int? _year; // null = toutes

  @override
  void initState() {
    super.initState();
    _generate();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  // Données simulées déterministes (mêmes résultats pour une matière donnée).
  void _generate() {
    final rnd = Random(widget.subject.hashCode);
    const sessions = ['Session normale', 'Rattrapage'];
    for (var y = 2025; y >= 2014; y--) {
      final n = 1 + rnd.nextInt(3); // 1 à 3 épreuves / an
      for (var i = 0; i < n; i++) {
        final formats = <String>['pdf'];
        if (rnd.nextBool()) formats.add('corrige');
        if (rnd.nextInt(3) == 0) formats.add('video');
        _all.add(_Epreuve(y, sessions[i % sessions.length], formats, rnd.nextInt(3) == 0));
      }
    }
  }

  List<_Epreuve> get _filtered => _all.where((e) {
        if (_type != null && !e.formats.contains(_type)) return false;
        if (_year != null && e.year != _year) return false;
        return true;
      }).toList();

  List<int> get _years {
    final s = _all.map((e) => e.year).toSet().toList()..sort((a, b) => b.compareTo(a));
    return s;
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 320) {
      final total = _filtered.length;
      if (_shown >= total) return;
      setState(() => _loadingMore = true);
      // Simule un chargement réseau paginé.
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() {
          _shown = (_shown + _pageSize).clamp(0, total);
          _loadingMore = false;
        });
      });
    }
  }

  void _resetPaging() => _shown = _pageSize;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final visible = filtered.take(_shown).toList();
    final hasMore = _shown < filtered.length;
    final crumb = [widget.exam, widget.filiere].where((e) => (e ?? '').isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.subject, style: display(17, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (crumb.isNotEmpty)
            Text(crumb, style: body(11, color: OC.muted, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: Column(children: [
        _filters(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(children: [
            SubjLogo(widget.subject, size: 26),
            const SizedBox(width: 9),
            Text('${filtered.length} épreuve${filtered.length > 1 ? 's' : ''}',
                style: body(12.5, color: OC.muted, weight: FontWeight.w700)),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _empty()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: visible.length + (hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= visible.length) return _loaderFooter();
                    return _epreuveCard(visible[i]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _filters() {
    Widget chip(String label, bool active, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 9),
          child: GestureDetector(onTap: onTap, child: OBChip(label, active: active)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
        child: Row(children: [
          chip('Tous', _type == null, () => setState(() { _type = null; _resetPaging(); })),
          chip('Sujets', _type == 'pdf', () => setState(() { _type = 'pdf'; _resetPaging(); })),
          chip('Corrigés', _type == 'corrige', () => setState(() { _type = 'corrige'; _resetPaging(); })),
          chip('Vidéos', _type == 'video', () => setState(() { _type = 'video'; _resetPaging(); })),
        ]),
      ),
      const SizedBox(height: 9),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
        child: Row(children: [
          chip('Toutes années', _year == null, () => setState(() { _year = null; _resetPaging(); })),
          for (final y in _years)
            chip('$y', _year == y, () => setState(() { _year = y; _resetPaging(); })),
        ]),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _epreuveCard(_Epreuve e) {
    return GestureDetector(
      onTap: () => context.push('/annales/detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          // Vignette « année »
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(13)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_rounded, size: 17, color: OC.o600),
              const SizedBox(height: 2),
              Text('${e.year}', style: body(10.5, weight: FontWeight.w800, color: OC.o700)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.subject} · ${e.year}',
                  style: body(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(e.session, style: body(11, color: OC.muted, weight: FontWeight.w600)),
              const SizedBox(height: 7),
              Row(children: [
                for (final f in e.formats) Padding(padding: const EdgeInsets.only(right: 5), child: _TypePill(f)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            e.premium
                ? PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD), icon: Icons.lock_outline_rounded)
                : PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
            const SizedBox(height: 12),
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
          ]),
        ]),
      ),
    );
  }

  Widget _loaderFooter() => const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 12),
        child: SkeletonRow(),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.filter_alt_off_rounded, size: 44, color: OC.faint),
            const SizedBox(height: 12),
            Text('Aucune épreuve pour ce filtre', style: display(17, weight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Essaie une autre année ou un autre type.',
                textAlign: TextAlign.center, style: body(13.5, color: OC.muted)),
          ]),
        ),
      );
}

class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill(this.type);

  @override
  Widget build(BuildContext context) {
    const map = {
      'pdf': ('PDF', Color(0xFFC0392B), Color(0xFFFAE7E4)),
      'video': ('Vidéo', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
      'corrige': ('Corrigé', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
    };
    final m = map[type] ?? map['pdf']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: m.$3, borderRadius: BorderRadius.circular(7)),
      child: Text(m.$1, style: body(10, weight: FontWeight.w800, color: m.$2)),
    );
  }
}
