import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class AideScreen extends StatelessWidget {
  const AideScreen({super.key});

  static const _faq = [
    ('Comment fonctionne le Tuteur IA ?', 'Photographie ou écris un exercice : le Tuteur le corrige étape par étape. Tu as 3 corrections gratuites par jour, puis des crédits.'),
    ('Mes données sont-elles en sécurité ?', 'Tes informations restent privées et ne servent qu\'à améliorer ton expérience sur OnBuch.'),
    ('Comment recharger des crédits ?', 'Depuis Crédits, choisis un pack et paie via MTN MoMo ou Orange Money (bientôt disponible).'),
    ('Les résultats d\'examen sont-ils officiels ?', 'OnBuch relaie les dates et publications officielles. Vérifie toujours auprès de ton établissement.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Aide & support'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Besoin d\'aide ?', style: display(20, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('On te répond rapidement.', style: body(13, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(children: [
            _contact(FontAwesomeIcons.whatsapp.data, 'WhatsApp', OC.wa, OC.goodBg),
            const SizedBox(width: 11),
            _contact(Icons.mail_outline_rounded, 'E-mail', OC.blue, OC.blueBg),
          ]),
          const SizedBox(height: 22),
          Text('Questions fréquentes', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          ..._faq.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    iconColor: OC.o600,
                    collapsedIconColor: OC.muted,
                    title: Text(f.$1, style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.3)),
                    children: [
                      Align(alignment: Alignment.centerLeft,
                          child: Text(f.$2, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5))),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _contact(IconData icon, String label, Color c, Color bg) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
          child: Column(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: c, size: 24)),
            const SizedBox(height: 9),
            Text(label, style: body(13, weight: FontWeight.w700)),
          ]),
        ),
      );
}
