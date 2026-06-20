import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/tutor_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();
  final _tutor = TutorService();

  // Cache mémoire partagé : conserve l'affichage entre deux visites de l'écran,
  // pour ne pas « recharger » le nom et les infos à chaque navigation.
  static String _name = 'Élève OnBuch';
  static String _initial = '🙂';
  static String _classeExamen = '—';
  static String _school = '';
  static String _city = '';
  static String _phone = '';
  static int _credits = 0;
  static int _corrections = 0;

  @override
  void initState() {
    super.initState();
    // Affichage instantané du nom connu (sans attendre le réseau). Si le nom
    // en cache diffère de ce qui est affiché (1re charge ou changement de
    // compte), on repart propre pour ne pas montrer les infos d'un autre élève.
    final cached = AuthService.cachedFullName;
    if (cached != null && cached.isNotEmpty && cached != _name) {
      _name = cached;
      _initial = cached.substring(0, 1).toUpperCase();
      _classeExamen = '—';
      _school = '';
      _city = '';
      _phone = '';
      _credits = 0;
      _corrections = 0;
    }
    _load();
  }

  Future<void> _load() async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;
    final profile = await _db.getUserProfile(user.$id);
    final quota = await _tutor.getQuota();
    final count = await _tutor.correctionsCount();
    if (!mounted) return;

    var name = user.name.trim();
    if (name.isEmpty) {
      final f = (profile?['firstName'] ?? '').toString().trim();
      final l = (profile?['lastName'] ?? '').toString().trim();
      name = [f, l].where((s) => s.isNotEmpty).join(' ').trim();
    }
    if (name.isEmpty) name = 'Élève OnBuch';

    final classe = (profile?['classe'] ?? '').toString().trim();
    final examen = (profile?['examen'] ?? '').toString().trim();
    final serie = (profile?['serie'] ?? '').toString().trim();
    final ce = [
      [classe, if (serie.isNotEmpty) serie].where((s) => s.toString().isNotEmpty).join(' '),
      examen,
    ].where((s) => s.isNotEmpty).join(' · ');

    setState(() {
      _name = name;
      _initial = name.substring(0, 1).toUpperCase();
      _classeExamen = ce.isEmpty ? '—' : ce;
      _school = (profile?['school'] ?? '').toString().trim();
      _city = (profile?['city'] ?? '').toString().trim();
      _phone = (profile?['phoneNumber'] ?? '').toString().trim();
      _credits = quota.credits;
      _corrections = count;
    });
  }

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
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 19),
            color: OC.ink2,
            tooltip: 'Modifier mon profil',
            onPressed: () async {
              await context.push('/edit-profile');
              if (mounted) _load();
            },
          ),
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
                  child: Center(child: Text(_initial, style: display(28, weight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_name, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(20, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_classeExamen, style: body(13, color: OC.ink2, weight: FontWeight.w500)),
                ])),
              ]),
              const SizedBox(height: 16),
              HRule(),
              const SizedBox(height: 16),
              // Credits
              Row(children: [
                _Stat('Crédits Tuteur', '$_credits', OC.o500),
                const SizedBox(width: 10),
                _Stat('Corrections IA', '$_corrections', OC.blue),
                const SizedBox(width: 10),
                _Stat('Annales', '—', OC.waInk),
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
            _ProfileRow(Icons.school_outlined, 'Classe & examen', _classeExamen, OC.o500, OC.o50),
            if (_school.isNotEmpty)
              _ProfileRow(Icons.account_balance_outlined, 'Établissement',
                  [_school, if (_city.isNotEmpty) _city].join(' · '), OC.waInk, OC.goodBg),
            _ProfileRow(Icons.history_rounded, 'Historique résultats', 'Voir mes anciens résultats', OC.blue, OC.blueBg),
          ]),
          const SizedBox(height: 16),

          // Préférences
          _Section('Préférences', [
            if (_phone.isNotEmpty)
              _ProfileRow(FontAwesomeIcons.whatsapp, 'WhatsApp', _phone, OC.wa, OC.goodBg),
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
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/splash');
            },
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
