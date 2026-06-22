import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/cours_packs_service.dart';

/// Panier & paiement en CRÉDITS OnBuch — données réelles (achat vérifié serveur).
class CoursCartScreen extends StatefulWidget {
  const CoursCartScreen({super.key});

  @override
  State<CoursCartScreen> createState() => _CoursCartScreenState();
}

class _CoursCartScreenState extends State<CoursCartScreen> {
  final _store = CoursPacks.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _pay() async {
    if (_busy) return;
    final n = _store.cart.length;
    setState(() => _busy = true);
    final err = await _store.checkout();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      _toast('Achat réussi · $n pack${n > 1 ? 's' : ''} débloqué${n > 1 ? 's' : ''} ✓', OC.good);
      context.pop();
    } else if (err.toLowerCase().contains('insuffisant')) {
      _insufficient();
    } else {
      _toast(err, OC.bad);
    }
  }

  void _toast(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
        backgroundColor: bg, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  void _insufficient() => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: OC.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Crédits insuffisants', style: display(18, weight: FontWeight.w700)),
          content: Text('Il te faut ${_store.bundlePrice} crédits (solde : ${_store.credits}). Recharge pour débloquer ces packs.',
              style: body(13.5, color: OC.ink2).copyWith(height: 1.4)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Plus tard', style: body(13.5, weight: FontWeight.w700, color: OC.muted))),
            TextButton(onPressed: () { Navigator.pop(ctx); context.push('/credits'); },
                child: Text('Recharger', style: body(13.5, weight: FontWeight.w800, color: OC.o600))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: ListenableBuilder(
          listenable: _store,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mon panier', style: display(16, weight: FontWeight.w700)),
            Text('${_store.cart.length} pack${_store.cart.length > 1 ? 's' : ''}', style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final cart = _store.cart;
          if (cart.isEmpty) return _empty();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              for (final p in cart) _cartRow(p),
              const SizedBox(height: 6),
              if (_store.hasBundle) _bundleCard(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  Icon(Icons.bolt_rounded, size: 20, color: OC.o500),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Ton solde', style: body(13, weight: FontWeight.w700))),
                  Text('${_store.credits} crédits', style: display(16, weight: FontWeight.w700, color: OC.o600)),
                ]),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.push('/credits'),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: OC.o600),
                  const SizedBox(width: 6),
                  Text('Recharger des crédits', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
                ]),
              ),
            ],
          );
        },
      ),
      bottomSheet: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (_store.cart.isEmpty) return const SizedBox.shrink();
          final enough = _store.credits >= _store.bundlePrice;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
            child: GestureDetector(
              onTap: _busy ? null : (enough ? _pay : () => context.push('/credits')),
              child: Container(
                height: 54,
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(enough ? 'Payer ${_store.bundlePrice} crédits' : 'Recharger pour payer (${_store.bundlePrice} cr)',
                        style: body(15, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cartRow(Pack p) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center, child: Text(p.code, style: display(13, weight: FontWeight.w800, color: OC.o600))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.level.isEmpty ? p.name : '${p.name} · ${p.level}', style: body(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Premium · accès illimité', style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Text('${p.price} cr', style: display(15, weight: FontWeight.w700)),
          const SizedBox(width: 4),
          IconButton(visualDensity: VisualDensity.compact, icon: Icon(Icons.close_rounded, size: 18, color: OC.muted),
              onPressed: _busy ? null : () => _store.removeFromCart(p.id)),
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
            Text('Bundle ${_store.cart.length} matières', style: body(13.5, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('-30 % au lieu de ${_store.cartSubtotal} crédits', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
          Text('${_store.bundlePrice} cr', style: display(18, weight: FontWeight.w700, color: OC.o600)),
        ]),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shopping_bag_outlined, size: 46, color: OC.faint),
            const SizedBox(height: 12),
            Text('Panier vide', style: display(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Ajoute des packs premium depuis le catalogue.', textAlign: TextAlign.center, style: body(13, color: OC.muted)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.go('/cours'),
              child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)), alignment: Alignment.center,
                  child: Text('Voir le catalogue', style: body(13.5, weight: FontWeight.w700, color: Colors.white))),
            ),
          ]),
        ),
      );
}
