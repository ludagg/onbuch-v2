import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Profil', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 19), color: OC.ink2, onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(children: [
          // Avatar + identity
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: OC.gradSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: OC.o100, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                  child: Center(child: Text('A', style: display(28, weight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NDJAMÉ Aïcha', style: display(20, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Terminale D · Baccalauréat 2026', style: body(13, color: OC.ink2, weight: FontWeight.w500)),
                ]),
              ]),
              const SizedBox(height: 16),
              HRule(),
              const SizedBox(height: 16),
              // Credits
              Row(children: [
                _Stat('Crédits Tuteur', '8', OC.o500),
                const SizedBox(width: 10),
                _Stat('Annales téléchargées', '12', OC.waInk),
                const SizedBox(width: 10),
                _Stat('Corrections IA', '34', OC.blue),
              ]),
              const SizedBox(height: 14),
              Container(
                width: double.infinity, height: 46,
                decoration: BoxDecoration(
                  gradient: OC.grad,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 7),
                  Text('Recharger des crédits', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          // Mon parcours
          _Section('Mon parcours', [
            _ProfileRow(Icons.school_outlined, 'Classe & examen', 'Terminale D · Baccalauréat', OC.o500, OC.o50),
            _ProfileRow(Icons.history_rounded, 'Historique résultats', 'Voir mes anciens résultats', OC.blue, OC.blueBg),
            _ProfileRow(Icons.menu_book_rounded, 'Mes annales', '12 téléchargées', OC.waInk, OC.goodBg),
          ]),
          const SizedBox(height: 16),

          // Préférences
          _Section('Préférences', [
            _ProfileRow(Icons.language_rounded, 'Langue', 'Français', OC.muted, OC.panel),
            _ProfileRow(Icons.notifications_outlined, 'Notifications', 'Alertes résultats activées', OC.muted, OC.panel),
            _ProfileRow(Icons.people_outline_rounded, 'Mode parent', 'Configurer un accès', OC.muted, OC.panel),
          ]),
          const SizedBox(height: 16),

          // Compte
          _Section('Compte', [
            _ProfileRow(Icons.shield_outlined, 'Mes données', 'Hébergées localement', OC.muted, OC.panel),
            _ProfileRow(Icons.help_outline_rounded, 'Aide & support', 'Contact & FAQ', OC.muted, OC.panel),
          ]),
          const SizedBox(height: 16),

          // Sign out
          GestureDetector(
            onTap: () => context.go('/splash'),
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.bad.withValues(alpha:0.3), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout_rounded, color: OC.bad, size: 18),
                const SizedBox(width: 8),
                Text('Se déconnecter', style: body(14, weight: FontWeight.w700, color: OC.bad)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color c;
  const _Stat(this.label, this.value, this.c);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: display(22, weight: FontWeight.w700, color: c)),
      const SizedBox(height: 4),
      Text(label, style: body(10, color: OC.ink2, weight: FontWeight.w600), textAlign: TextAlign.center),
    ]));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _Section(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: body(13, weight: FontWeight.w800, color: OC.ink2)),
      const SizedBox(height: 10),
      OBCard(
        padding: EdgeInsets.zero,
        child: Column(children: rows.asMap().entries.map((e) => Column(children: [
          if (e.key > 0) const Divider(height: 1, color: OC.line, thickness: 1),
          e.value,
        ])).toList()),
      ),
    ]);
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color c, bg;
  const _ProfileRow(this.icon, this.label, this.sub, this.c, this.bg);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: body(14, weight: FontWeight.w700)),
          Text(sub, style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ])),
        const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
      ]),
    );
  }
}
