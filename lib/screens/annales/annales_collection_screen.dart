import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/annale_actions.dart';
import '../../models/annale.dart';
import '../../services/annale_store.dart';

/// Type de collection d'annales (accès rapides de la bibliothèque).
enum AnnaleCollection { recent, favorites, offline }

/// Page « Récents / Favoris » des annales, alimentée par le stockage local.
class AnnalesCollectionScreen extends StatefulWidget {
  final AnnaleCollection kind;
  const AnnalesCollectionScreen({super.key, required this.kind});

  @override
  State<AnnalesCollectionScreen> createState() => _AnnalesCollectionScreenState();
}

class _AnnalesCollectionScreenState extends State<AnnalesCollectionScreen> {
  List<Annale> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = switch (widget.kind) {
      AnnaleCollection.favorites => await AnnaleStore.instance.favorites(),
      AnnaleCollection.offline => await AnnaleStore.instance.offline(),
      AnnaleCollection.recent => await AnnaleStore.instance.recents(),
    };
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  String get _title => switch (widget.kind) {
        AnnaleCollection.favorites => 'Favoris',
        AnnaleCollection.offline => 'Hors-ligne',
        AnnaleCollection.recent => 'Récents',
      };

  ({IconData icon, Color color, String empty, String emptyMsg}) get _cfg => switch (widget.kind) {
        AnnaleCollection.favorites => (
            icon: Icons.bookmark_rounded,
            color: const Color(0xFFA6701A),
            empty: 'Aucun favori',
            emptyMsg: 'Mets une épreuve en favori (icône signet) pour la retrouver vite.',
          ),
        AnnaleCollection.offline => (
            icon: Icons.download_done_rounded,
            color: OC.waInk,
            empty: 'Rien hors-ligne',
            emptyMsg: 'Rends une épreuve dispo hors-ligne pour la consulter sans réseau, dans l\'app.',
          ),
        AnnaleCollection.recent => (
            icon: Icons.access_time_rounded,
            color: OC.blue,
            empty: 'Aucun récent',
            emptyMsg: 'Les documents que tu ouvres apparaîtront ici.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, _title),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : _items.isEmpty
              ? EmptyState(icon: cfg.icon, title: cfg.empty, message: cfg.emptyMsg,
                  actionLabel: 'Parcourir les annales', onAction: () => context.go('/annales'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = _items[i];
                    return _AnnaleTile(
                      annale: a,
                      trailingIcon: cfg.icon,
                      trailingColor: cfg.color,
                      onTap: () async {
                        await context.push('/annales/detail', extra: a);
                        if (mounted) _load(); // rafraîchit (favori retiré, récent màj)
                      },
                      onLongPress: () => showAnnaleActions(context, a, onChanged: _load),
                    );
                  },
                ),
    );
  }
}

class _AnnaleTile extends StatelessWidget {
  final Annale annale;
  final IconData trailingIcon;
  final Color trailingColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _AnnaleTile({required this.annale, required this.trailingIcon, required this.trailingColor, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final sub = [annale.subject, if (annale.track.isNotEmpty) annale.track, if (annale.year.isNotEmpty) annale.year].join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
            child: Icon(annale.hasVideo && !annale.hasPdf ? Icons.play_circle_outline_rounded : Icons.picture_as_pdf_rounded, size: 21, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(annale.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Container(
            width: 30, height: 30, alignment: Alignment.center,
            decoration: BoxDecoration(color: trailingColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(trailingIcon, size: 16, color: trailingColor),
          ),
        ]),
      ),
    );
  }
}
