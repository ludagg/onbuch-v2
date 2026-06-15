import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class AuthPhoneScreen extends StatelessWidget {
  const AuthPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // AppBar row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: OC.ink,
                onPressed: () => context.go('/onboarding/3'),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text('O', style: display(28, weight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Bienvenue 👋', style: display(26, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Entre ton numéro. On t\'envoie un code par SMS — pas de mot de passe à retenir.',
                  style: body(15, color: OC.ink2).copyWith(height: 1.45),
                ),
                const SizedBox(height: 26),
                // Phone field
                OBField(
                  label: 'Numéro de téléphone',
                  placeholder: '6 78 •• •• ••',
                  icon: Icons.phone_android_rounded,
                  focused: true,
                  trailing: Text('+237', style: body(13, weight: FontWeight.w700, color: OC.muted)),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => context.go('/auth/otp'),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: OC.grad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Recevoir le code', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                    ]),
                  ),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(child: Divider(color: OC.line, thickness: 1.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OU', style: body(12, weight: FontWeight.w700, color: OC.muted)),
                  ),
                  const Expanded(child: Divider(color: OC.line, thickness: 1.5)),
                ]),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OC.line2, width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.g_mobiledata_rounded, size: 22, color: OC.blue),
                    const SizedBox(width: 8),
                    Text('Continuer avec Google', style: body(14, weight: FontWeight.w700, color: OC.ink)),
                  ]),
                ),
                const SizedBox(height: 24),
                Text(
                  'En continuant, tu acceptes nos Conditions et notre Politique de confidentialité. Données hébergées localement.',
                  textAlign: TextAlign.center,
                  style: body(11.5, color: OC.muted).copyWith(height: 1.45),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
