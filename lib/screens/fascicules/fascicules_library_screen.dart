import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/skeletons.dart';
import '../../models/fascicule.dart';
import '../../services/database_service.dart';

/// Bibliothèque « Nos fascicules » : les livres PDF OnBuch (cours + exercices
/// complets), publiés par l'admin. Ouvre le PDF dans le lecteur des annales.
class FasciculesLibraryScreen extends StatefulWidget {
  const FasciculesLibraryScreen({super.key});
  @override
  State<FasciculesLibraryScreen> createState() => _FasciculesLibraryScreenState();
}

class _FasciculesLibraryScreenState extends State<FasciculesLibraryScreen> {
  final _svc = DatabaseService();
  bool _loading = true;
  bool _error = false;
  List<Fascicule> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (mounted) setState(() { _loading = !force; _error = false; });
    try {
      final list = await _svc.getFascicules(force: force);
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = true; _loading = false; });
    }
  }

  void _open(Fascicule f) {
    if (!f.hasPdf) return;
    context.push('/annales/pdf', extra: {
      'url': f.pdfUrl,
      'title': f.title,
      'subtitle': f.shelfSubtitle.isEmpty ? 'Fascicule OnBuch' : f.shelfSubtitle,
      'offlineId': 'fascicule:${f.id}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Nos fascicules'),
      body: RefreshIndicator(
        color: OC.o600,
        onRefresh: () => _load(force: true),
        child: _loading
            ? const _LoadingGrid()
            : _error && _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 40),
                      ErrorState(onRetry: () => _load(force: true)),
                    ])
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                        SizedBox(height: 30),
                        EmptyState(
                          icon: Icons.menu_book_rounded,
                          title: 'Bientôt disponibles',
                          message:
                              'Les fascicules OnBuch (cours complets + exercices corrigés) apparaîtront ici dès leur publication.',
                        ),
                      ])
                    : _grid(),
      ),
    );
  }

  Widget _grid() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('La bibliothèque OnBuch',
                  style: display(22, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Des bouquins complets pour réviser et s\'entraîner : cours développé, méthodes et exercices corrigés.',
                style: body(13.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.4),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _FasciculeCard(f: _items[i], onTap: () => _open(_items[i])),
              childCount: _items.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _FasciculeCard extends StatelessWidget {
  final Fascicule f;
  final VoidCallback onTap;
  const _FasciculeCard({required this.f, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: OC.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.line),
                boxShadow: [
                  BoxShadow(color: OC.ink.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: f.hasCover
                  ? Image.network(
                      f.coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (c, child, p) =>
                          p == null ? child : _CoverFallback(f: f),
                      errorBuilder: (c, e, s) => _CoverFallback(f: f),
                    )
                  : _CoverFallback(f: f),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(f.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: body(13.5, weight: FontWeight.w800).copyWith(height: 1.15)),
        if (f.shelfSubtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(children: [
            Flexible(
              child: Text(f.shelfSubtitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
            ),
            if (f.pages > 0) ...[
              Text('  ·  ', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
              Text('${f.pages} p.', style: body(11.5, color: OC.o600, weight: FontWeight.w700)),
            ],
          ]),
        ],
      ]),
    );
  }
}

/// Couverture de repli (charte OnBuch) si l'image est absente / ne charge pas.
class _CoverFallback extends StatelessWidget {
  final Fascicule f;
  const _CoverFallback({required this.f});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [OC.ink, OC.ink2],
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.functions_rounded, color: Colors.white, size: 18),
        ),
        const Spacer(),
        Text(f.subject.isEmpty ? 'Fascicule' : f.subject,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: body(11, color: Colors.white70, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(f.level.isEmpty ? f.title : f.level,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: display(16, weight: FontWeight.w800).copyWith(color: Colors.white, height: 1.1)),
      ]),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (c, i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: OC.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OC.line),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Skeleton(width: 120, height: 12, radius: 4),
        const SizedBox(height: 6),
        const Skeleton(width: 70, height: 10, radius: 4),
      ]),
    );
  }
}
