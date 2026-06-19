import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../theme/app_theme.dart';
import '../services/billing_service.dart';

/// Feuille de recharge de crédits Tuteur via **Google Play Billing**.
/// Les crédits sont des biens numériques : le Play Store impose son système
/// de facturation. L'attribution réelle se fait après vérification serveur.
class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: OC.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const PaywallSheet(),
    );
  }

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  final _billing = BillingService.instance;
  List<ProductDetails> _products = const [];
  bool _loading = true;
  bool _available = false;
  bool _busy = false;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _billing.onCredited = (n) {
      if (!mounted) return;
      _toast('+$n crédits ajoutés ✓');
      Navigator.of(context).pop(true);
    };
    _billing.onError = (m) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(m, bad: true);
    };
    _billing.onPending = () {
      if (!mounted) return;
      _toast('Paiement en cours…');
    };
    _billing.start();
    _load();
  }

  @override
  void dispose() {
    _billing.onCredited = null;
    _billing.onError = null;
    _billing.onPending = null;
    super.dispose();
  }

  Future<void> _load() async {
    final available = await _billing.isAvailable();
    var products = <ProductDetails>[];
    if (available) {
      try {
        products = await _billing.loadProducts();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _available = available;
      _products = products;
      _selected = products.isNotEmpty ? products[products.length > 1 ? 1 : 0].id : null;
      _loading = false;
    });
  }

  Future<void> _buy() async {
    final id = _selected;
    if (id == null) return;
    final p = _products.firstWhere((e) => e.id == id);
    setState(() => _busy = true);
    try {
      await _billing.buy(p);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('Achat impossible : $e', bad: true);
      }
    }
  }

  void _toast(String msg, {bool bad = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: bad ? OC.bad : OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 5, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 16),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5)),
          child: const Icon(Icons.bolt_rounded, size: 28, color: OC.o500),
        ),
        const SizedBox(height: 12),
        Text('Recharger des crédits', style: display(21, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Continue tes corrections IA — ou reviens demain (3 gratuites/jour).',
            textAlign: TextAlign.center, style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        const SizedBox(height: 18),
        if (_loading)
          const Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator(color: OC.o500))
        else if (!_available || _products.isEmpty)
          _unavailable()
        else ...[
          Row(children: _products.map(_packTile).toList()),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _busy ? null : _buy,
            child: Opacity(
              opacity: _busy ? 0.7 : 1,
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  gradient: OC.grad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text('Acheter avec Google Play', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Paiement sécurisé via Google Play · sans abonnement',
              textAlign: TextAlign.center, style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ],
      ]),
    );
  }

  Widget _packTile(ProductDetails p) {
    final n = BillingService.creditProducts[p.id] ?? 0;
    final sel = p.id == _selected;
    final i = _products.indexOf(p);
    return Expanded(child: Padding(
      padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
      child: GestureDetector(
        onTap: () => setState(() => _selected = p.id),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          decoration: BoxDecoration(
            color: sel ? OC.o50 : OC.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? OC.o500 : OC.line, width: sel ? 2 : 1.5),
          ),
          child: Column(children: [
            Text(p.price, style: display(15, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('$n crédits', style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
      ),
    ));
  }

  Widget _unavailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Icon(Icons.storefront_outlined, size: 26, color: OC.muted),
        const SizedBox(height: 10),
        Text('Achats indisponibles', style: body(14, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'La boutique n\'est accessible que depuis une version installée via le Play Store, avec les produits configurés.',
          textAlign: TextAlign.center,
          style: body(12.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.4),
        ),
      ]),
    );
  }
}
