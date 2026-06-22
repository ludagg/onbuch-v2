import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ── MOCK (valeurs/libellés EXACTS du wireframe — écran 10). Aucune API. ───────
const _kItems = <({String code, String name, String sub, String price})>[
  (code: 'Ph', name: 'Physique-Chimie · Tle D', sub: 'Premium · accès illimité', price: '800 F'),
  (code: 'SV', name: 'SVT · Tle D', sub: 'Premium · accès illimité', price: '800 F'),
  (code: 'An', name: 'Anglais · Tle D', sub: 'Premium · accès illimité', price: '500 F'),
];
const _kBundle = (title: 'Bundle 3 matières', sub: '-30 % au lieu de 2 100 F', price: '1 500 F');
// TODO: le paiement réel se fera en CRÉDITS OnBuch (décision produit) ; la
// maquette montre MoMo, conservée ici en attendant le backend.
const _kMethods = ['MTN MoMo', 'Orange Money'];
const _kPayLabel = 'Payer 1 500 F →';

/// Panier & paiement — écran 10.
class CoursCartScreen extends StatefulWidget {
  const CoursCartScreen({super.key});

  @override
  State<CoursCartScreen> createState() => _CoursCartScreenState();
}

class _CoursCartScreenState extends State<CoursCartScreen> {
  int _method = 0; // méthode sélectionnée (état visuel local)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mon panier', style: display(16, weight: FontWeight.w700)),
          Text('${_kItems.length} packs', style: body(11, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final it in _kItems) _cartRow(it),
          const SizedBox(height: 6),
          _bundleCard(),
          const SizedBox(height: 20),
          Text('Payer avec', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(child: _methodTile(0, _kMethods[0], const Color(0xFFF5B700))),
            const SizedBox(width: 11),
            Expanded(child: _methodTile(1, _kMethods[1], const Color(0xFFFF6600))),
          ]),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: GestureDetector(
          onTap: () {/* TODO nav */},
          child: Container(
            height: 54,
            decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(_kPayLabel, style: body(15, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _cartRow(({String code, String name, String sub, String price}) it) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(it.code, style: display(13, weight: FontWeight.w800, color: OC.o600)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.name, style: body(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(it.sub, style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Text(it.price, style: display(15, weight: FontWeight.w700)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_left_rounded, size: 20, color: OC.faint),
        ]),
      );

  Widget _bundleCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [OC.o50, OC.paper], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.o100, width: 1.5),
        ),
        child: Row(children: [
          const Text('🎁', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_kBundle.title, style: body(13.5, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(_kBundle.sub, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
          Text(_kBundle.price, style: display(18, weight: FontWeight.w700, color: OC.o600)),
        ]),
      );

  Widget _methodTile(int i, String label, Color color) {
    final sel = _method == i;
    return GestureDetector(
      onTap: () => setState(() => _method = i),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.10) : OC.paper,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: sel ? color : OC.line, width: sel ? 2 : 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          const SizedBox(width: 9),
          Text(label, style: body(13, weight: FontWeight.w700, color: sel ? OC.ink : OC.ink2)),
        ]),
      ),
    );
  }
}
