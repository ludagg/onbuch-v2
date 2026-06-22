import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/cours_packs_service.dart';
import '../../services/cours_offline_service.dart';

/// Disponible hors-ligne — téléchargement réel (cache texte) du pack.
class PackOfflineScreen extends StatefulWidget {
  final String? subjectId;
  const PackOfflineScreen({super.key, this.subjectId});

  @override
  State<PackOfflineScreen> createState() => _PackOfflineScreenState();
}

class _PackOfflineScreenState extends State<PackOfflineScreen> {
  final _off = CoursOffline.instance;

  @override
  void initState() {
    super.initState();
    _off.init().then((_) => _packs.load());
  }

  final _packs = CoursPacks.instance;

  Pack? get _pack => _packs.byId(widget.subjectId ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: ListenableBuilder(
          listenable: _packs,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Disponible hors-ligne', style: display(16, weight: FontWeight.w700)),
            Text(_pack == null ? 'Pack' : 'Pack ${_pack!.name}', style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_packs, _off]),
        builder: (context, _) {
          final p = _pack;
          if (p == null) {
            if (_packs.loading) return const Center(child: CircularProgressIndicator(color: OC.o500));
            return Center(child: Text('Pack indisponible.', style: body(14, color: OC.muted)));
          }
          final downloaded = _off.isDownloaded(p.id);
          final active = _off.downloading && _off.activeSubject == p.id;
          final total = p.modules.length;
          final done = active ? _off.done : (downloaded ? total : 0);
          final pct = total == 0 ? 0.0 : done / total;
          final coursDone = downloaded || (active && done >= total);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  SizedBox(width: 56, height: 56, child: OBRing(pct: pct, size: 56, color: OC.o500,
                      center: Text('${(pct * 100).round()}%', style: body(12, weight: FontWeight.w800)))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(downloaded ? 'Téléchargé ✓' : (active ? 'Téléchargement… $done/$total leçons' : 'Pas encore téléchargé'),
                        style: body(13.5, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.cloud_off_rounded, size: 13, color: OC.muted),
                      const SizedBox(width: 4),
                      Text('$total chapitres · lecture sans réseau', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
                    ]),
                  ])),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: OC.blueBg, borderRadius: BorderRadius.circular(13)),
                child: Row(children: [
                  Icon(Icons.bolt_rounded, size: 18, color: OC.blue),
                  const SizedBox(width: 9),
                  Expanded(child: Text('Léger : seul le texte des cours est mis en cache, lisible sans réseau.',
                      style: body(12.5, weight: FontWeight.w600, color: OC.ink2))),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Contenu du pack', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 11),
              _item(Icons.menu_book_rounded, 'Cours & textes', coursDone ? 'Terminé' : (active ? 'En cours' : 'En attente'),
                  coursDone ? 2 : (active ? 1 : 0), active ? '${(pct * 100).round()}%' : null),
              _item(Icons.play_circle_outline_rounded, 'Vidéos (${p.videos})', 'Bientôt', 0, null),
              _item(Icons.quiz_outlined, 'Quiz & fiches', 'En ligne', 0, null),
            ],
          );
        },
      ),
      bottomSheet: ListenableBuilder(
        listenable: Listenable.merge([_packs, _off]),
        builder: (context, _) {
          final p = _pack;
          if (p == null) return const SizedBox.shrink();
          final downloaded = _off.isDownloaded(p.id);
          final active = _off.downloading && _off.activeSubject == p.id;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
            child: GestureDetector(
              onTap: active
                  ? null
                  : () async {
                      if (downloaded) {
                        await _off.remove(p.id);
                      } else {
                        await _off.download(p);
                      }
                    },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: (downloaded || active) ? null : OC.grad,
                  color: (downloaded || active) ? OC.paper : null,
                  borderRadius: BorderRadius.circular(14),
                  border: (downloaded || active) ? Border.all(color: OC.line, width: 1.5) : null,
                ),
                alignment: Alignment.center,
                child: active
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: OC.o500))
                    : Text(downloaded ? 'Supprimer le téléchargement' : 'Télécharger le pack',
                        style: body(14, weight: FontWeight.w700, color: downloaded ? OC.ink : Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _item(IconData icon, String title, String state, int status, String? badge) {
    final (color, bg) = switch (status) {
      2 => (OC.good, OC.goodBg),
      1 => (OC.o600, OC.o50),
      _ => (OC.muted, OC.panel),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
      child: Row(children: [
        Icon(icon, size: 21, color: status == 0 ? OC.muted : OC.ink),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: body(13.5, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(state, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
        ])),
        if (status == 2) Icon(Icons.check_circle_rounded, color: OC.good, size: 20)
        else Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(badge ?? '—', style: body(10.5, weight: FontWeight.w800, color: color)),
        ),
      ]),
    );
  }
}
