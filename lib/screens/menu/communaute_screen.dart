import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/social_link.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

class CommunauteScreen extends StatefulWidget {
  const CommunauteScreen({super.key});

  @override
  State<CommunauteScreen> createState() => _CommunauteScreenState();
}

class _CommunauteScreenState extends State<CommunauteScreen> {
  final Future<List<SocialLink>> _future = DatabaseService().getSocialLinks();

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
          const SizedBox(height: 16),
          // Inviter des amis (boucle de croissance)
          GestureDetector(
            onTap: () => shareApp(context),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: OC.grad,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Inviter des amis', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Fais grandir ta classe avec OnBuch', style: body(12, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w500)),
                ])),
                const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          // Réseaux sociaux (pilotés par l'admin)
          FutureBuilder<List<SocialLink>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: OC.o500))),
                );
              }
              final links = snap.data ?? const <SocialLink>[];
              if (links.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nos réseaux', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 10),
                ...links.map(_socialRow),
              ]);
            },
          ),
        ],
      ),
    );
  }

  Widget _socialRow(SocialLink s) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openUrl(context, s.url),
        child: Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
          child: Row(children: [
            Container(
              width: 46, height: 46, alignment: Alignment.center,
              decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: FaIcon(s.faIcon, color: s.color, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.label, style: body(14.5, weight: FontWeight.w700)),
              if (s.description != null) ...[
                const SizedBox(height: 2),
                Text(s.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(12, color: OC.muted, weight: FontWeight.w500)),
              ],
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.o100, width: 1.5)),
              child: Text('Rejoindre', style: body(12, weight: FontWeight.w700, color: OC.o700)),
            ),
          ]),
        ),
      );
}
