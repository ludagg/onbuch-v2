import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class CommunauteScreen extends StatelessWidget {
  const CommunauteScreen({super.key});

  static const _socials = [
    (Icons.chat_bubble_rounded, 'WhatsApp', 'Groupe d\'entraide · 12k membres', Color(0xFF25D366)),
    (Icons.send_rounded, 'Telegram', 'Annonces & annales · 8k abonnés', Color(0xFF2AABEE)),
    (Icons.music_note_rounded, 'TikTok', '@onbuch · astuces de révision', Colors.black),
    (Icons.facebook_rounded, 'Facebook', 'Page officielle OnBuch', Color(0xFF1877F2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Communauté'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Reste connecté', style: display(20, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Rejoins des milliers d\'élèves camerounais sur OnBuch.',
              style: body(13, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 18),
          ..._socials.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: (s.$4).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                      child: Icon(s.$1, color: s.$4, size: 24)),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$2, style: body(14.5, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(s.$3, style: body(12, color: OC.muted, weight: FontWeight.w500)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.o100, width: 1.5)),
                    child: Text('Rejoindre', style: body(12, weight: FontWeight.w700, color: OC.o700)),
                  ),
                ]),
              )),
          const SizedBox(height: 6),
          Text('Les liens directs arrivent dans une prochaine mise à jour.',
              textAlign: TextAlign.center, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}
