import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _level = 3; // Terminale
  int _exam = 0;  // Baccalauréat
  bool _saving = false;

  final _authService = AuthService();
  final _databaseService = DatabaseService();

  final _serieCtrl = TextEditingController();
  final _ecoleCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  String? _gender;

  static const _levels = ['3ème', '2nde', '1ère', 'Terminale', 'Sup. / Fac'];
  static const _exams  = ['Baccalauréat', 'Probatoire', 'GCE A Level', 'BTS', 'Concours (ENS…)'];
  static const _genders = ['Fille', 'Garçon', 'Autre'];

  @override
  void dispose() {
    _serieCtrl.dispose();
    _ecoleCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      if (mounted) context.go('/welcome');
      return;
    }

    setState(() => _saving = true);
    try {
      // On inclut l'identité (firstName/lastName/email) en plus des champs
      // profil : ainsi le document est valide même s'il doit être créé ici
      // (champs requis de la collection `users`), pas seulement mis à jour.
      final serie = _serieCtrl.text.trim();
      final ecole = _ecoleCtrl.text.trim();
      final ville = _villeCtrl.text.trim();
      await _databaseService.createUserProfile(
        user.$id,
        {
          ...DatabaseService.splitFullName(user.name),
          'email': user.email,
          'classe': _levels[_level],
          'examen': _exams[_exam],
          if (serie.isNotEmpty) 'serie': serie,
          if (ecole.isNotEmpty) 'school': ecole,
          if (ville.isNotEmpty) 'city': ville,
          if (_gender != null) 'gender': _gender,
        },
      );
      if (mounted) context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : $e'),
          backgroundColor: OC.bad,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController c, String hint, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: body(13, weight: FontWeight.w700, color: OC.ink2)),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        textCapitalization: TextCapitalization.words,
        style: body(15, color: OC.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: body(14, color: OC.muted),
          prefixIcon: Icon(icon, color: OC.muted, size: 20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(children: [
              ProgressDots(count: 3, active: 2),
              const Spacer(),
              Text('Étape 3/3', style: body(13, weight: FontWeight.w700, color: OC.muted)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Parle-nous de toi', style: display(25, weight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text('Pour adapter ton tuteur et tes alertes. Modifiable à tout moment.',
                    style: body(14.5, color: OC.ink2).copyWith(height: 1.4)),
                const SizedBox(height: 22),

                // Level picker
                Text('Ta classe / niveau', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 11),
                Wrap(spacing: 9, runSpacing: 9, children: List.generate(_levels.length, (i) {
                  final on = i == _level;
                  return GestureDetector(
                    onTap: () => setState(() => _level = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? OC.o50 : OC.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
                      ),
                      child: Text(_levels[i], style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
                    ),
                  );
                })),
                const SizedBox(height: 22),

                // Exam picker
                Text('Examen / concours visé', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 11),
                Wrap(spacing: 9, runSpacing: 9, children: List.generate(_exams.length, (i) {
                  final on = i == _exam;
                  return GestureDetector(
                    onTap: () => setState(() => _exam = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? OC.o50 : OC.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
                      ),
                      child: Text(_exams[i], style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
                    ),
                  );
                })),
                const SizedBox(height: 22),

                // Infos complémentaires (optionnel)
                Text('Infos complémentaires (optionnel)', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 4),
                Text('Ça nous aide à améliorer OnBuch pour les élèves comme toi.',
                    style: body(12, color: OC.muted, weight: FontWeight.w500)),
                const SizedBox(height: 12),
                _field('Série', _serieCtrl, 'D — Sciences & Mathématiques', Icons.workspace_premium_outlined),
                const SizedBox(height: 14),
                _field('Établissement', _ecoleCtrl, 'Lycée de Bonabéri', Icons.account_balance_outlined),
                const SizedBox(height: 14),
                _field('Ville', _villeCtrl, 'Douala', Icons.location_on_outlined),
                const SizedBox(height: 16),
                Text('Sexe', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 10),
                Wrap(spacing: 9, runSpacing: 9, children: List.generate(_genders.length, (i) {
                  final on = _gender == _genders[i];
                  return GestureDetector(
                    onTap: () => setState(() => _gender = on ? null : _genders[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? OC.o50 : OC.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
                      ),
                      child: Text(_genders[i], style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
                    ),
                  );
                })),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
            decoration: const BoxDecoration(
              color: OC.paper,
              border: Border(top: BorderSide(color: OC.line, width: 1.5)),
            ),
            child: Column(children: [
              GestureDetector(
                onTap: _saving ? null : _saveAndContinue,
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: _saving
                      ? const Center(child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Entrer dans OnBuch', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                        ]),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Center(child: Text('Plus tard', style: body(13.5, weight: FontWeight.w600, color: OC.muted))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
