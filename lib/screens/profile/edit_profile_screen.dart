import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Édition du profil élève : nom, classe/examen, série, établissement, ville,
/// WhatsApp, sexe. Réutilise les champs de l'onboarding et `updateUserProfile`.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();

  final _nameCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _ecoleCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  int _level = 3;
  int _exam = 0;
  String? _gender;
  String _email = '';
  bool _loading = true;
  bool _saving = false;

  static const _levels = ['3ème', '2nde', '1ère', 'Terminale', 'Sup. / Fac'];
  static const _exams = ['Baccalauréat', 'Probatoire', 'GCE A Level', 'BTS', 'Concours (ENS…)'];
  static const _genders = ['Fille', 'Garçon', 'Autre'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _serieCtrl, _ecoleCtrl, _villeCtrl, _phoneCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final user = await _auth.getCurrentUser();
    Map<String, dynamic>? p;
    if (user != null) p = await _db.getUserProfile(user.$id);
    if (!mounted) return;
    setState(() {
      _email = user?.email ?? '';
      _nameCtrl.text = user?.name.trim() ?? '';
      if (p != null) {
        _serieCtrl.text = (p['serie'] ?? '').toString();
        _ecoleCtrl.text = (p['school'] ?? '').toString();
        _villeCtrl.text = (p['city'] ?? '').toString();
        _phoneCtrl.text = (p['phoneNumber'] ?? '').toString();
        final classe = (p['classe'] ?? '').toString();
        final examen = (p['examen'] ?? '').toString();
        final g = (p['gender'] ?? '').toString();
        final li = _levels.indexOf(classe);
        final ei = _exams.indexOf(examen);
        if (li >= 0) _level = li;
        if (ei >= 0) _exam = ei;
        if (_genders.contains(g)) _gender = g;
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Indique ton nom.', bad: true);
      return;
    }
    final user = await _auth.getCurrentUser();
    if (user == null) {
      _toast('Connecte-toi pour modifier ton profil.', bad: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (name != user.name) await _auth.updateName(name);
      await _db.createUserProfile(user.$id, {
        ...DatabaseService.splitFullName(name),
        'email': _email.isNotEmpty ? _email : user.email,
        'classe': _levels[_level],
        'examen': _exams[_exam],
        'serie': _serieCtrl.text.trim(),
        'school': _ecoleCtrl.text.trim(),
        'city': _villeCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        if (_gender != null) 'gender': _gender,
      });
      if (!mounted) return;
      _toast('Profil mis à jour ✓');
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('Échec de l\'enregistrement : $e', bad: true);
      }
    }
  }

  void _toast(String m, {bool bad = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: bad ? OC.bad : OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Modifier mon profil'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _field('Nom & prénom', _nameCtrl, 'NDJAMÉ Aïcha', Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _field('Numéro WhatsApp', _phoneCtrl, '+237 6XX XX XX XX', FontAwesomeIcons.whatsapp.data, keyboard: TextInputType.phone),
                const SizedBox(height: 18),
                _label('Ta classe / niveau'),
                const SizedBox(height: 10),
                _chips(_levels, _level, (i) => setState(() => _level = i)),
                const SizedBox(height: 18),
                _label('Examen / concours visé'),
                const SizedBox(height: 10),
                _chips(_exams, _exam, (i) => setState(() => _exam = i)),
                const SizedBox(height: 18),
                _field('Série', _serieCtrl, 'D — Sciences & Mathématiques', Icons.workspace_premium_outlined),
                const SizedBox(height: 14),
                _field('Établissement', _ecoleCtrl, 'Lycée de Bonabéri', Icons.account_balance_outlined),
                const SizedBox(height: 14),
                _field('Ville', _villeCtrl, 'Douala', Icons.location_on_outlined),
                const SizedBox(height: 18),
                _label('Sexe'),
                const SizedBox(height: 10),
                Wrap(spacing: 9, runSpacing: 9, children: List.generate(_genders.length, (i) {
                  final on = _gender == _genders[i];
                  return _chip(_genders[i], on, () => setState(() => _gender = on ? null : _genders[i]));
                })),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: OC.grad,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text('Enregistrer', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _label(String t) => Text(t, style: body(13, weight: FontWeight.w800, color: OC.ink2));

  Widget _chips(List<String> items, int active, ValueChanged<int> onTap) => Wrap(
        spacing: 9, runSpacing: 9,
        children: List.generate(items.length, (i) => _chip(items[i], i == active, () => onTap(i))),
      );

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: on ? OC.o50 : OC.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
          ),
          child: Text(label, style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
        ),
      );

  Widget _field(String label, TextEditingController c, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: body(13, weight: FontWeight.w700, color: OC.ink2)),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        keyboardType: keyboard,
        textCapitalization: keyboard == TextInputType.phone ? TextCapitalization.none : TextCapitalization.words,
        style: body(15, color: OC.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: body(14, color: OC.muted),
          prefixIcon: Icon(icon, color: OC.muted, size: 19),
          filled: true,
          fillColor: OC.paper,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OC.o500, width: 2)),
        ),
      ),
    ]);
  }
}
