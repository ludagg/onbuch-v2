import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';
import '../../utils/launch.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  static const _kResultats = 'ob_notif_resultats';
  static const _kConseils = 'ob_notif_conseils';

  bool _notifsResultats = true;
  bool _notifsConseils = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _notifsResultats = p.getBool(_kResultats) ?? true;
        _notifsConseils = p.getBool(_kConseils) ?? true;
      });
    } catch (_) {}
  }

  Future<void> _setPref(String key, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(key, v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Paramètres'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _section('Compte', [
            _row(Icons.person_outline_rounded, 'Modifier mon profil', 'Nom, classe, infos', onTap: () => context.push('/edit-profile')),
            _row(Icons.lock_outline_rounded, 'Changer le mot de passe', 'Sécurité du compte', onTap: _changePassword),
          ]),
          const SizedBox(height: 16),
          _section('Notifications', [
            _toggle('Alertes résultats', 'Sois prévenu dès la publication', _notifsResultats, (v) {
              setState(() => _notifsResultats = v);
              _setPref(_kResultats, v);
            }),
            _toggle('Conseils & actus', 'Le fil OnBuch et les rappels', _notifsConseils, (v) {
              setState(() => _notifsConseils = v);
              _setPref(_kConseils, v);
            }),
          ]),
          const SizedBox(height: 16),
          _section('Préférences', [
            _row(Icons.language_rounded, 'Langue', 'Français'),
            _row(Icons.straighten_rounded, 'Programme', 'MINESEC · francophone'),
          ]),
          const SizedBox(height: 16),
          _section('À propos', [
            _row(Icons.ios_share_rounded, 'Inviter des amis', 'Partager OnBuch', onTap: () => shareApp(context)),
            _row(Icons.help_outline_rounded, 'Aide & support', 'Contact & FAQ', onTap: () => context.push('/aide')),
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
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _working ? null : _deleteAccount,
            child: Center(
              child: Text('Supprimer mon compte', style: body(13, weight: FontWeight.w600, color: OC.muted)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Changer le mot de passe ────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OC.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Changer le mot de passe', style: display(17, weight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _pwField(oldCtrl, 'Mot de passe actuel'),
          const SizedBox(height: 12),
          _pwField(newCtrl, 'Nouveau (8 caractères min.)'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: body(13.5, weight: FontWeight.w700, color: OC.ink2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Valider', style: body(13.5, weight: FontWeight.w700, color: OC.o600))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService().updatePassword(newCtrl.text, oldCtrl.text);
      _toast('Mot de passe mis à jour ✓');
    } catch (e) {
      _toast('$e', bad: true);
    }
  }

  Widget _pwField(TextEditingController c, String hint) => TextField(
        controller: c,
        obscureText: true,
        style: body(14, color: OC.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: body(13.5, color: OC.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.o500, width: 2)),
        ),
      );

  // ── Supprimer le compte ────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OC.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Supprimer ton compte ?', style: display(17, weight: FontWeight.w700)),
        content: Text('Ton compte sera désactivé et tu seras déconnecté. Cette action est irréversible.',
            style: body(13.5, color: OC.ink2).copyWith(height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: body(13.5, weight: FontWeight.w700, color: OC.ink2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Supprimer', style: body(13.5, weight: FontWeight.w700, color: OC.bad))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _working = true);
    try {
      await AuthService().deleteAccount();
      if (mounted) context.go('/splash');
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        _toast('$e', bad: true);
      }
    }
  }

  void _toast(String m, {bool bad = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: bad ? OC.bad : OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Construction ───────────────────────────────────────────────────────────
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

  Widget _row(IconData icon, String label, String sub, {VoidCallback? onTap}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: OC.muted)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: body(14, weight: FontWeight.w700)),
              Text(sub, style: body(12, color: OC.muted, weight: FontWeight.w500)),
            ])),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
          ]),
        ),
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
