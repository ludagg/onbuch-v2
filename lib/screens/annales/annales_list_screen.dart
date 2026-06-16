import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/annale.dart';
import '../../models/annales_filter.dart';
import '../../services/annales_service.dart';
import 'annales_folder_screen.dart' show AnnaleRow;

/// Liste paginée d'épreuves correspondant à un [AnnalesFilter] (scroll infini).
class AnnalesListScreen extends StatefulWidget {
  final AnnalesFilter filter;
  const AnnalesListScreen({super.key, required this.filter});

  @override
  State<AnnalesListScreen> createState() => _AnnalesListScreenState();
}

class _AnnalesListScreenState extends State<AnnalesListScreen> {
  final _service = AnnalesService();
  final _scroll = ScrollController();
  final List<Annale> _items = [];

  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _firstDone = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final res = await _service.fetchDocuments(widget.filter, page: _page, limit: 20);
    if (!mounted) return;
    setState(() {
      _items.addAll(res.items);
      _total = res.total;
      _hasMore = res.hasNextPage && res.items.isNotEmpty;
      _page += 1;
      _loading = false;
      _firstDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.filter.label, style: display(16, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (_firstDone) Text('$_total résultat${_total > 1 ? 's' : ''}', style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _firstDone && _items.isEmpty
          ? _empty()
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              itemCount: _items.length + 1,
              itemBuilder: (context, i) {
                if (i < _items.length) return AnnaleRow(_items[i]);
                // Pied : loader ou fin de liste.
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Center(child: CircularProgressIndicator(color: OC.o600)),
                  );
                }
                if (!_hasMore && _items.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: Text('— fin —', style: body(11.5, color: OC.faint, weight: FontWeight.w600))),
                  );
                }
                return const SizedBox(height: 40);
              },
            ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_off_rounded, size: 46, color: OC.faint),
            const SizedBox(height: 12),
            Text('Aucune épreuve trouvée', style: display(16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Essayez d\'élargir votre recherche ou vos filtres.',
                textAlign: TextAlign.center, style: body(13, color: OC.muted, weight: FontWeight.w500)),
          ]),
        ),
      );
}
