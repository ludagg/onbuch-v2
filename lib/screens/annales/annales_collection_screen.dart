import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/annale.dart';
import '../../services/annales_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';

/// Type de collection d'annales (accès rapides de la bibliothèque).
enum AnnaleCollection { offline, recent, favorites }

/// Page « Hors-ligne / Récents / Favoris » des annales, alimentée par
/// [AnnalesStore] (persistance locale).
class AnnalesCollectionScreen extends StatefulWidget {
  final AnnaleCollection kind;
  const AnnalesCollectionScreen({super.key, required this.kind});

  @override
  State<AnnalesCollectionScreen> createState() => _AnnalesCollectionScreenState();
}

class _AnnalesCollectionScreenState extends State<AnnalesCollectionScreen> {
  final _store = AnnalesStore.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  String get _title => switch (widget.kind) {
        AnnaleCollection.offline => 'Hors-ligne',
        AnnaleCollection.recent => 'Récents',
        AnnaleCollection.favorites => 'Favoris',
      };

  ({IconData icon, Color color, String empty, String emptyMsg}) get _cfg => switch (widget.kind) {
        AnnaleCollection.offline => (
            icon: Icons.download_done_rounded,
            color: OC.waInk,
            empty: 'Rien hors-ligne',
            emptyMsg: 'Télécharge une annale pour la consulter sans connexion.',
          ),
        AnnaleCollection.recent => (
            icon: Icons.access_time_rounded,
            color: OC.blue,
            empty: 'Aucun récent',
            emptyMsg: 'Les annales que tu ouvres apparaîtront ici.',
          ),
        AnnaleCollection.favorites => (
            icon: Icons.bookmark_rounded,
            color: const Color(0xFFA6701A),
            empty: 'Aucun favori',
            emptyMsg: 'Mets une annale en favori pour la retrouver vite.',
          ),
      };

  void _openRef(AnnaleRef ref) =>
      context.push('/annales/detail', extra: ref).then((_) {
        if (mounted) setState(() {}); // rafraîchit après un éventuel changement
      });

  void _openOffline(OfflineAnnale o) {
    context.push('/annales/pdf', extra: PdfArgs(
      title: o.title,
      subtitle: [o.exam, o.year].where((s) => s.isNotEmpty).join(' · '),
      localPath: o.path,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    final List<dynamic> items = switch (widget.kind) {
      AnnaleCollection.offline => _store.downloads,
      AnnaleCollection.recent => _store.recents,
      AnnaleCollection.favorites => _store.favorites,
    };

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, _title),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? EmptyState(icon: cfg.icon, title: cfg.empty, message: cfg.emptyMsg,
                  actionLabel: 'Parcourir les annales', onAction: () => context.go('/annales'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    if (it is OfflineAnnale) {
                      return _Tile(
                        title: it.title,
                        sub: [it.exam, it.track, it.year].where((s) => s.isNotEmpty).join(' · '),
                        trailingIcon: cfg.icon, trailingColor: cfg.color,
                        onTap: () => _openOffline(it),
                        onRemove: () async {
                          await _store.removeDownload(it.id);
                          if (mounted) setState(() {});
                        },
                      );
                    }
                    final ref = it as AnnaleRef;
                    return _Tile(
                      title: ref.title.isEmpty ? ref.subject : ref.title,
                      sub: [ref.exam, ref.track, ref.year].where((s) => s.isNotEmpty).join(' · '),
                      trailingIcon: cfg.icon, trailingColor: cfg.color,
                      onTap: () => _openRef(ref),
                    );
                  },
                ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title, sub;
  final IconData trailingIcon;
  final Color trailingColor;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _Tile({
    required this.title, required this.sub,
    required this.trailingIcon, required this.trailingColor, required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.picture_as_pdf_rounded, size: 21, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(14, weight: FontWeight.w700)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
            ],
          ])),
          const SizedBox(width: 8),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 30, height: 30, alignment: Alignment.center,
                decoration: BoxDecoration(color: OC.bad.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.delete_outline_rounded, size: 16, color: OC.bad),
              ),
            )
          else
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
