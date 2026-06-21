import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class AuthOtpScreen extends StatelessWidget {
  const AuthOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: OC.ink,
              onPressed: () => context.go('/auth/phone'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5)),
                  child: const Icon(Icons.notifications_outlined, color: OC.o500, size: 26),
                ),
                const SizedBox(height: 22),
                Text('Entre le code', style: display(25, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'Code à 6 chiffres envoyé au ', style: body(15, color: OC.ink2)),
                  TextSpan(text: '+237 6 78 •• •• ••', style: body(15, weight: FontWeight.w700, color: OC.ink)),
                ])),
                const SizedBox(height: 26),
                const OTPRow(),
                const SizedBox(height: 20),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 16, color: OC.muted),
                  const SizedBox(width: 7),
                  Text('Renvoyer le code dans ', style: body(13.5, color: OC.muted)),
                  Text('0:42', style: mono(13.5, weight: FontWeight.w700, color: OC.ink2)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/auth/profile'),
                  child: Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(
                      gradient: OC.grad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Vérifier', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text('Mauvais numéro ? Modifier', style: body(13.5, weight: FontWeight.w600, color: OC.muted))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
