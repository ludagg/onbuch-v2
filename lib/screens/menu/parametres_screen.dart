import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _notifsResultats = true;
  bool _notifsConseils = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Paramètres'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _section('Notifications', [
            _toggle('Alertes résultats', 'Sois prévenu dès la publication', _notifsResultats, (v) => setState(() => _notifsResultats = v)),
            _toggle('Conseils & actus', 'Le fil OnBuch et les rappels', _notifsConseils, (v) => setState(() => _notifsConseils = v)),
          ]),
          const SizedBox(height: 16),
          _section('Préférences', [
            _row(Icons.language_rounded, 'Langue', 'Français'),
            _row(Icons.straighten_rounded, 'Programme', 'MINESEC · francophone'),
          ]),
          const SizedBox(height: 16),
          _section('Compte', [
            _row(Icons.shield_outlined, 'Confidentialité', 'Tes données restent privées'),
            _row(Icons.info_outline_rounded, 'Version', 'OnBuch 1.0.0'),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/splash');
            },
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: OC.paper, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.bad.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout_rounded, color: OC.bad, size: 18),
                const SizedBox(width: 8),
                Text('Se déconnecter', style: body(14, weight: FontWeight.w700, color: OC.bad)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: OC.line, thickness: 1),
              rows[i],
            ],
          ]),
        ),
      ]);

  Widget _row(IconData icon, String label, String sub) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: OC.muted)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: body(14, weight: FontWeight.w700)),
            Text(sub, style: body(12, color: OC.muted, weight: FontWeight.w500)),
          ])),
        ]),
      );

  Widget _toggle(String label, String sub, bool value, ValueChanged<bool> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: body(14, weight: FontWeight.w700)),
            Text(sub, style: body(12, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Switch(value: value, onChanged: onChanged, activeColor: OC.o500),
        ]),
      );
}
