import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/paywall_sheet.dart';
import '../../widgets/redeem_code_sheet.dart';
import '../../services/tutor_service.dart';
import '../../appwrite_config.dart';
import '../../utils/launch.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final _tutor = TutorService();
  TutorQuota? _quota;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final q = await _tutor.getQuota();
    if (mounted) setState(() => _quota = q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _quota;
    final free = q?.freeRemaining ?? 0;
    final credits = q?.credits ?? 0;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Crédits'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Solde
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SOLDE TUTEUR IA', style: body(10.5, weight: FontWeight.w800, color: const Color(0xFFFFB489)).copyWith(letterSpacing: 0.1 * 10.5)),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$credits', style: display(40, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Text('crédits', style: body(14, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)))),
              ]),
              const SizedBox(height: 6),
              Text('$free correction${free > 1 ? 's' : ''} gratuite${free > 1 ? 's' : ''} restante${free > 1 ? 's' : ''} aujourd\'hui',
                  style: body(13, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
            ]),
          ),
          const SizedBox(height: 16),
          // Recharge : sur le web → Mobile Money (bot Telegram) ; sur mobile →
          // Google Play Billing. (Conformité Play : aucun lien de paiement
          // externe affiché dans le build mobile.)
          if (kIsWeb)
            _cta(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Recharger via Orange / MTN',
              onTap: () => openUrl(context, onbuchCreditsBotUrl),
            )
          else
            _cta(
              icon: Icons.bolt_rounded,
              label: 'Recharger des crédits',
              onTap: () async { await PaywallSheet.show(context); if (mounted) _load(); },
            ),
          const SizedBox(height: 10),
          // « J'ai un code » : disponible partout (rachat d'un code obtenu
          // hors-app). Ne sollicite aucun paiement → conforme Play.
          GestureDetector(
            onTap: () async {
              final added = await RedeemCodeSheet.show(context);
              if (added != null && added > 0 && mounted) _load();
            },
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: OC.paper, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.confirmation_number_outlined, color: OC.o600, size: 19),
                const SizedBox(width: 8),
                Text('J\'ai un code', style: body(14, weight: FontWeight.w700, color: OC.ink)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text('Comment ça marche', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          _info(Icons.bolt_rounded, '3 corrections gratuites par jour', 'Réinitialisées chaque jour, sans rien payer.'),
          if (kIsWeb)
            _info(Icons.account_balance_wallet_rounded, 'Recharge par Mobile Money', 'Paie en Orange Money ou MTN MoMo, reçois un code et saisis-le ici.')
          else
            _info(Icons.shopping_bag_outlined, 'Des crédits à la demande', 'Recharge en un tap via Google Play, paiement sécurisé.'),
          _info(Icons.confirmation_number_outlined, 'Un code à échanger', 'Reçu un code ? Saisis-le via « J\'ai un code » pour créditer ton compte.'),
          _info(Icons.lock_outline_rounded, 'Sans abonnement', 'Tu paies seulement quand tu en as besoin.'),
        ],
      ),
    );
  }

  Widget _cta({required IconData icon, required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: OC.grad, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            Text(label, style: body(14, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      );

  Widget _info(IconData icon, String title, String sub) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: OC.o600)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: body(12, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.3)),
          ])),
        ]),
      );
}
