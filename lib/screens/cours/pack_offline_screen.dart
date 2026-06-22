import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

// ── MOCK (valeurs/libellés EXACTS du wireframe — écran 9). Aucune API. ────────
const _kDl = (pct: 0.60, done: 'Téléchargement… 23/38 leçons', size: '14 Mo sur 24 Mo · ~1 min', pack: 'Pack Maths · Tle D');
const _kItems = <({IconData icon, String title, String state, int status})>[
  (icon: Icons.menu_book_rounded, title: 'Cours & textes', state: 'Terminé', status: 0),
  (icon: Icons.play_circle_outline_rounded, title: 'Vidéos (14)', state: 'En cours', status: 1),
  (icon: Icons.quiz_outlined, title: 'Quiz & fiches', state: 'En attente', status: 2),
];

/// Disponible hors-ligne (téléchargement du pack entier) — écran 9.
class PackOfflineScreen extends StatefulWidget {
  const PackOfflineScreen({super.key});

  @override
  State<PackOfflineScreen> createState() => _PackOfflineScreenState();
}

class _PackOfflineScreenState extends State<PackOfflineScreen> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Disponible hors-ligne', style: display(16, weight: FontWeight.w700)),
          Text(_kDl.pack, style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
            child: Row(children: [
              SizedBox(width: 56, height: 56, child: OBRing(pct: _kDl.pct, size: 56, color: OC.o500,
                  center: Text('${(_kDl.pct * 100).round()}%', style: body(12, weight: FontWeight.w800)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_paused ? 'En pause' : _kDl.done, style: body(13.5, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 13, color: OC.muted),
                  const SizedBox(width: 4),
                  Text(_kDl.size, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
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
              Expanded(child: Text('Léger : vidéos compressées, lisibles sans réseau.', style: body(12.5, weight: FontWeight.w600, color: OC.ink2))),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Contenu du pack', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          for (final it in _kItems) _item(it),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: GestureDetector(
          onTap: () => setState(() => _paused = !_paused),
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
            alignment: Alignment.center,
            child: Text(_paused ? 'Reprendre le téléchargement' : 'Mettre en pause', style: body(14, weight: FontWeight.w700, color: OC.ink)),
          ),
        ),
      ),
    );
  }

  Widget _item(({IconData icon, String title, String state, int status}) it) {
    final (color, bg) = switch (it.status) {
      0 => (OC.good, OC.goodBg),
      1 => (OC.o600, OC.o50),
      _ => (OC.muted, OC.panel),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
      child: Row(children: [
        Icon(it.icon, size: 21, color: it.status == 2 ? OC.muted : OC.ink),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.title, style: body(13.5, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(it.state, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
        ])),
        if (it.status == 0) Icon(Icons.check_circle_rounded, color: OC.good, size: 20)
        else Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(it.status == 1 ? '60%' : '—', style: body(10.5, weight: FontWeight.w800, color: color)),
        ),
      ]),
    );
  }
}
