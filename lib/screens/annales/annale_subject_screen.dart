import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../models/annale.dart';
import '../../services/database_service.dart';

/// Liste des documents (épreuves, cours, fiches, TD) d'une matière, depuis la
/// collection `annales` (admin). Filtres par tags (type + année) et pagination
/// au défilement. Corrigé/vidéo facultatifs (non bloquant).
class AnnaleSubjectScreen extends StatefulWidget {
  final String subject;
  final String? exam;
  final String? filiere;
  const AnnaleSubjectScreen({super.key, required this.subject, this.exam, this.filiere});

  @override
  State<AnnaleSubjectScreen> createState() => _AnnaleSubjectScreenState();
}

class _AnnaleSubjectScreenState extends State<AnnaleSubjectScreen> {
  final _scroll = ScrollController();
  List<Annale> _all = [];
  bool _loading = true;

  static const _pageSize = 10;
  int _shown = _pageSize;
  bool _loadingMore = false;

  String? _type; // null = tous ; 'pdf'|'corrige'|'video'
  String? _year; // null = toutes

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final exam = (widget.exam ?? '').trim();
    final items = exam.isEmpty
        ? <Annale>[]
        : await DatabaseService().getAnnales(exam: exam, subject: widget.subject);
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<Annale> get _filtered => _all.where((e) {
        if (_type == 'pdf' && !e.hasPdf) return false;
        if (_type == 'corrige' && !e.hasCorrige) return false;
        if (_type == 'video' && !e.hasVideo) return false;
        if (_year != null && e.year != _year) return false;
        return true;
      }).toList();

  List<String> get _years {
    final s = _all.map((e) => e.year).where((y) => y.isNotEmpty).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return s;
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 320) {
      final total = _filtered.length;
      if (_shown >= total) return;
      setState(() => _loadingMore = true);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _shown = (_shown + _pageSize).clamp(0, total);
          _loadingMore = false;
        });
      });
    }
  }

  void _resetPaging() => _shown = _pageSize;

  // Ouvre une ressource dans le lecteur intégré (PDF ou vidéo).
  void _openResource(String kind, String url, Annale a) {
    final subtitle = [widget.exam, widget.filiere].where((e) => (e ?? '').isNotEmpty).join(' · ');
    final extra = {'url': url, 'title': a.title, 'subtitle': subtitle};
    context.push(kind == 'video' ? '/annales/video' : '/annales/pdf', extra: extra);
  }

  void _openResources(Annale a) {
    final res = <(IconData, String, Color, String, String)>[
      if (a.hasPdf) (Icons.picture_as_pdf_rounded, 'Sujet (PDF)', const Color(0xFFC0392B), 'pdf', a.fileUrl),
      if (a.hasCorrige) (Icons.check_circle_rounded, 'Corrigé (PDF)', const Color(0xFF1E9E63), 'pdf', a.corrigeUrl),
      if (a.hasVideo) (Icons.play_circle_rounded, 'Vidéo corrigée', const Color(0xFF7A5AE0), 'video', a.videoUrl),
    ];
    if (res.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document bientôt disponible.', style: body(13, color: Colors.white)), backgroundColor: OC.ink),
      );
      return;
    }
    if (res.length == 1) {
      _openResource(res.first.$4, res.first.$5, a);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 14),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Align(alignment: Alignment.centerLeft, child: Text(a.title, style: display(15, weight: FontWeight.w700))),
          ),
          for (final r in res)
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: r.$3.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(11)),
                child: Icon(r.$1, color: r.$3, size: 21),
              ),
              title: Text(r.$2, style: body(14, weight: FontWeight.w700)),
              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
              onTap: () {
                Navigator.pop(context);
                _openResource(r.$4, r.$5, a);
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

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
      body: _loading
          ? ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: List.generate(6, (_) => const SkeletonRow()))
          : Column(children: [
              if (_all.isNotEmpty) _filters(),
              if (_all.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(children: [
                    SubjLogo(widget.subject, size: 26),
                    const SizedBox(width: 9),
                    Text('${filtered.length} document${filtered.length > 1 ? 's' : ''}',
                        style: body(12.5, color: OC.muted, weight: FontWeight.w700)),
                  ]),
                ),
              Expanded(
                child: _all.isEmpty
                    ? _empty()
                    : filtered.isEmpty
                        ? _noMatch()
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: visible.length + (hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= visible.length) return const Padding(padding: EdgeInsets.only(top: 2, bottom: 12), child: SkeletonRow());
                              return _card(visible[i]);
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
      if (_years.isNotEmpty) ...[
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(children: [
            chip('Toutes années', _year == null, () => setState(() { _year = null; _resetPaging(); })),
            for (final y in _years) chip(y, _year == y, () => setState(() { _year = y; _resetPaging(); })),
          ]),
        ),
      ],
      const SizedBox(height: 12),
    ]);
  }

  Widget _card(Annale a) {
    final sub = [a.category, if (a.session.isNotEmpty) a.session].join(' · ');
    return GestureDetector(
      onTap: () => _openResources(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(13)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_rounded, size: 17, color: OC.o600),
              if (a.year.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(a.year, style: body(10.5, weight: FontWeight.w800, color: OC.o700)),
              ],
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: body(13.5, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(sub, style: body(11, color: OC.muted, weight: FontWeight.w600)),
              ],
              const SizedBox(height: 7),
              Row(children: [
                for (final f in a.formats) Padding(padding: const EdgeInsets.only(right: 5), child: _TypePill(f)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            a.premium
                ? PillBadge('PREMIUM', color: const Color(0xFFA6701A), bg: const Color(0xFFFBF0DD), icon: Icons.lock_outline_rounded)
                : PillBadge('GRATUIT', color: OC.waInk, bg: OC.goodBg),
            const SizedBox(height: 12),
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
          ]),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.folder_open_rounded, size: 46, color: OC.faint),
            const SizedBox(height: 12),
            Text('Aucun document pour le moment', style: display(18, weight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Les épreuves, cours et fiches de ${widget.subject} apparaîtront ici dès qu\'ils seront ajoutés.',
                textAlign: TextAlign.center, style: body(13.5, color: OC.muted).copyWith(height: 1.4)),
          ]),
        ),
      );

  Widget _noMatch() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.filter_alt_off_rounded, size: 44, color: OC.faint),
            const SizedBox(height: 12),
            Text('Aucun document pour ce filtre', style: display(17, weight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Essaie une autre année ou un autre type.', textAlign: TextAlign.center, style: body(13.5, color: OC.muted)),
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
