import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Feuille de paiement (recharge de crédits Tuteur). Le paiement réel
/// (MTN MoMo / Orange Money) reste à brancher sur un prestataire.
class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
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
  int _selectedPack = 1;
  int _selectedPayment = 0;

  static const _packs = [('5 crédits', '100 F'), ('15 crédits', '250 F'), ('40 crédits', '500 F')];

  void _pay() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Paiement mobile bientôt disponible.', style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: OC.ink, behavior: SnackBarBehavior.floating,
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
        Row(children: List.generate(_packs.length, (i) {
          final p = _packs[i];
          final sel = i == _selectedPack;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPack = i),
              child: Stack(clipBehavior: Clip.none, children: [
                if (sel) Positioned(top: -9, left: 0, right: 0, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(999)),
                  child: Text('POPULAIRE', style: body(9, weight: FontWeight.w800, color: Colors.white)),
                ))),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: sel ? OC.o50 : OC.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? OC.o500 : OC.line, width: sel ? 2 : 1.5),
                  ),
                  child: Column(children: [
                    Text(p.$2, style: display(15, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(p.$1, style: body(11, color: OC.muted, weight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ));
        })),
        const SizedBox(height: 18),
        Text('Payer avec', style: body(12, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        Row(children: [
          _PayMethod(OC.mtn, 'MTN', 'MTN MoMo', _selectedPayment == 0, () => setState(() => _selectedPayment = 0)),
          const SizedBox(width: 10),
          _PayMethod(OC.orange, 'Or.', 'Orange Money', _selectedPayment == 1, () => setState(() => _selectedPayment = 1)),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pay,
          child: Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Payer ${_packs[_selectedPack].$2} · ${_selectedPayment == 0 ? 'MTN MoMo' : 'Orange Money'}',
                  style: body(14, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text('Micro-paiement ponctuel · sans abonnement', style: body(11, color: OC.muted, weight: FontWeight.w500)),
      ]),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final Color c;
  final String abbr, name;
  final bool selected;
  final VoidCallback onTap;
  const _PayMethod(this.c, this.abbr, this.name, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? OC.o500 : OC.line, width: selected ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(abbr, style: body(9, weight: FontWeight.w900, color: c == OC.mtn ? Colors.black : Colors.white))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: body(12.5, weight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: selected ? OC.o500 : Colors.transparent,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: OC.line2, width: 2),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null,
          ),
        ]),
      ),
    ));
  }
}
