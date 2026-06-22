import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../appwrite_config.dart';
import '../models/annale.dart';
import '../services/annale_store.dart';

/// Feuille d'actions sur un document (appui long) : Partager, Favori, Hors-ligne.
Future<void> showAnnaleActions(BuildContext context, Annale a, {VoidCallback? onChanged}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: OC.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _AnnaleActionsSheet(annale: a, onChanged: onChanged),
  );
}

class _AnnaleActionsSheet extends StatefulWidget {
  final Annale annale;
  final VoidCallback? onChanged;
  const _AnnaleActionsSheet({required this.annale, this.onChanged});

  @override
  State<_AnnaleActionsSheet> createState() => _AnnaleActionsSheetState();
}

class _AnnaleActionsSheetState extends State<_AnnaleActionsSheet> {
  bool _fav = false;
  bool _off = false;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fav = await AnnaleStore.instance.isFavorite(widget.annale.id);
    final off = await AnnaleStore.instance.isOffline(widget.annale.id);
    if (mounted) setState(() { _fav = fav; _off = off; _loaded = true; });
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m, style: body(13, color: Colors.white)), backgroundColor: OC.ink,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Future<void> _share() async {
    Navigator.pop(context);
    final a = widget.annale;
    final link = '$onbuchShareBaseUrl/a/${a.id}';
    await Share.share('${a.title}\n$link', subject: a.title);
  }

  Future<void> _toggleFav() async {
    final now = await AnnaleStore.instance.toggleFavorite(widget.annale);
    if (!mounted) return;
    setState(() => _fav = now);
    widget.onChanged?.call();
    _toast(now ? 'Ajouté aux favoris ✓' : 'Retiré des favoris');
  }

  Future<void> _toggleOffline() async {
    setState(() => _busy = true);
    final target = !_off;
    final ok = await AnnaleStore.instance.setOffline(widget.annale, target);
    if (!mounted) return;
    setState(() { _off = target && ok; _busy = false; });
    widget.onChanged?.call();
    if (target) {
      _toast(ok ? 'Disponible hors-ligne ✓' : 'Téléchargement impossible.');
    } else {
      _toast('Retiré du hors-ligne');
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.annale;
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 14),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(15, weight: FontWeight.w700))),
        ),
        _tile(Icons.ios_share_rounded, 'Partager', OC.blue, _share),
        _tile(
          _fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          _fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
          const Color(0xFFA6701A),
          _loaded ? _toggleFav : null,
        ),
        _tile(
          _busy ? Icons.hourglass_top_rounded : (_off ? Icons.download_done_rounded : Icons.download_rounded),
          _busy ? 'Téléchargement…' : (_off ? 'Disponible hors-ligne' : 'Rendre dispo hors-ligne'),
          OC.waInk,
          (_loaded && !_busy) ? _toggleOffline : null,
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _tile(IconData icon, String label, Color c, VoidCallback? onTap) => ListTile(
        enabled: onTap != null,
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: c, size: 21),
        ),
        title: Text(label, style: body(14, weight: FontWeight.w700)),
        onTap: onTap,
      );
}
