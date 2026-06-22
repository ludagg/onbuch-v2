import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/credits_service.dart';

/// Feuille « J'ai un code » : l'utilisateur saisit un code reçu après un
/// paiement Mobile Money validé. Le rachat est vérifié côté serveur, puis les
/// crédits sont ajoutés. Retourne le nombre de crédits ajoutés (ou null).
class RedeemCodeSheet extends StatefulWidget {
  const RedeemCodeSheet({super.key});

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: OC.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const RedeemCodeSheet(),
      ),
    );
  }

  @override
  State<RedeemCodeSheet> createState() => _RedeemCodeSheetState();
}

class _RedeemCodeSheetState extends State<RedeemCodeSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Entre ton code.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final added = await CreditsService.redeemCode(code);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(added);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('+$added crédits ajoutés ✓', style: body(13, weight: FontWeight.w600, color: Colors.white)),
        backgroundColor: OC.good,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.confirmation_number_outlined, color: OC.o600, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saisir un code', style: display(18, weight: FontWeight.w700)),
            Text('Reçu après un paiement validé', style: body(12, color: OC.muted, weight: FontWeight.w500)),
          ])),
        ]),
        const SizedBox(height: 18),
        TextField(
          controller: _ctrl,
          autofocus: true,
          enabled: !_busy,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _busy ? null : _submit(),
          style: mono(18, weight: FontWeight.w700).copyWith(letterSpacing: 2),
          decoration: InputDecoration(
            hintText: 'OBXXXXXX',
            hintStyle: mono(18, color: OC.faint, weight: FontWeight.w700).copyWith(letterSpacing: 2),
            filled: true, fillColor: OC.paper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.line, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.o500, width: 1.8)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.error_outline_rounded, size: 16, color: OC.bad),
            const SizedBox(width: 6),
            Expanded(child: Text(_error!, style: body(12.5, color: OC.bad, weight: FontWeight.w600))),
          ]),
        ],
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _busy ? null : _submit,
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              gradient: _busy ? null : OC.grad,
              color: _busy ? OC.line2 : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Text('Valider le code', style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}
