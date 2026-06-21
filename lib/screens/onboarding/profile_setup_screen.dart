import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../widgets/series_picker.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Création du profil (étape 3 de l'onboarding), découpée en 3 sections courtes
/// guidées par Léo : parcours scolaire, ambitions universitaires, école & toi.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _sectionCount = 3;
  int _section = 0;
  bool _saving = false;
  // Sens de l'animation (1 = on avance, -1 = on recule) pour la transition.
  int _dir = 1;

  final _authService = AuthService();
  final _databaseService = DatabaseService();

  // ── Données du profil ───────────────────────────────────────────────────
  String _classe = 'Terminale';
  String _examen = 'Baccalauréat';
  String? _serie;

  String? _studyField;      // domaine d'études visé (aspiration)
  final _careerCtrl = TextEditingController(); // métier de rêve
  String? _destination;     // où étudier

  final _ecoleCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender;

  static const _classes = ['3ème', '2nde', '1ère', 'Terminale', 'Sup. / Fac'];
  static const _exams   = ['Baccalauréat', 'Probatoire', 'GCE A Level', 'BTS', 'Concours (ENS…)'];
  static const _fields  = [
    'Santé / Médecine', 'Ingénierie / Tech', 'Droit / Sciences Po',
    'Commerce / Gestion', 'Sciences', 'Lettres / Langues', 'Arts / Design',
    'Encore indécis·e',
  ];
  static const _destinations = [
    'Cameroun', 'Afrique', 'France', 'Amérique du N.', 'Europe', 'Pas encore décidé',
  ];
  static const _genders = ['Fille', 'Garçon', 'Autre'];

  @override
  void dispose() {
    _careerCtrl.dispose();
    _ecoleCtrl.dispose();
    _villeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Navigation entre sections ─────────────────────────────────────────────
  void _next() {
    if (_section < _sectionCount - 1) {
      setState(() { _dir = 1; _section++; });
    } else {
      _saveAndContinue();
    }
  }

  void _back() {
    if (_section > 0) {
      setState(() { _dir = -1; _section--; });
    } else if (context.canPop()) {
      context.pop();
    }
  }

  // ── Sauvegarde ─────────────────────────────────────────────────────────────
  Future<void> _saveAndContinue() async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      if (mounted) context.go('/welcome');
      return;
    }

    setState(() => _saving = true);

    final serie = _serie?.trim() ?? '';
    final career = _careerCtrl.text.trim();
    final ecole = _ecoleCtrl.text.trim();
    final ville = _villeCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    // Champs « cœur » (attributs déjà présents dans la collection `users`).
    final core = <String, dynamic>{
      ...DatabaseService.splitFullName(user.name),
      'email': user.email,
      'classe': _classe,
      'examen': _examen,
      if (serie.isNotEmpty) 'serie': serie,
      if (ecole.isNotEmpty) 'school': ecole,
      if (ville.isNotEmpty) 'city': ville,
      if (phone.isNotEmpty) 'phoneNumber': phone,
      if (_gender != null) 'gender': _gender,
    };

    // Champs « ambitions » (nouveaux attributs — voir
    // tools/setup_users_profile_attributes.sh). Optionnels.
    final aspirations = <String, dynamic>{
      if (_studyField != null) 'studyField': _studyField,
      if (career.isNotEmpty) 'careerGoal': career,
      if (_destination != null) 'studyDestination': _destination,
    };

    try {
      try {
        await _databaseService.createUserProfile(user.$id, {...core, ...aspirations});
      } catch (_) {
        // La collection n'a peut-être pas encore les attributs d'ambitions :
        // on ne bloque jamais la création de compte pour autant.
        if (aspirations.isEmpty) rethrow;
        await _databaseService.createUserProfile(user.$id, core);
      }
      if (mounted) context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : $e'),
          backgroundColor: OC.bad,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  // ── Léo + intro par section ────────────────────────────────────────────────
  ({LeoMood mood, String line, String title}) get _intro => switch (_section) {
        0 => (
            mood: LeoMood.wave,
            title: 'Ton parcours',
            line: 'Salut, moi c\'est Léo ! 🦁 Dis-moi où tu en es dans tes études.',
          ),
        1 => (
            mood: LeoMood.encourage,
            title: 'Tes ambitions',
            line: 'Et après ? Vise haut — ça peut toujours évoluer, aucune pression.',
          ),
        _ => (
            mood: LeoMood.celebrate,
            title: 'Toi & ton école',
            line: 'Dernière ligne droite ! Quelques infos et on entre dans OnBuch.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final intro = _intro;
    final isLast = _section == _sectionCount - 1;
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          // En-tête : retour + progression des sous-étapes.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(children: [
              IconButton(
                onPressed: _saving ? null : _back,
                icon: Icon(Icons.arrow_back_rounded, color: OC.ink, size: 22),
                tooltip: 'Retour',
              ),
              ProgressDots(count: _sectionCount, active: _section),
              const Spacer(),
              Text('Profil · ${_section + 1}/$_sectionCount',
                  style: body(13, weight: FontWeight.w700, color: OC.muted)),
            ]),
          ),

          // Bandeau Léo : mascotte + phrase contextuelle.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              LeoMascot(size: 56, mood: intro.mood),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OC.line, width: 1.5),
                  ),
                  child: Text(intro.line,
                      style: body(13, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.35)),
                ),
              ),
            ]),
          ),

          // Contenu de la section (transition douce gauche/droite).
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) {
                final offset = Tween<Offset>(
                  begin: Offset(0.12 * _dir, 0), end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: SingleChildScrollView(
                key: ValueKey(_section),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(intro.title, style: display(23, weight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ..._sectionBody(),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),

          // Pied : bouton principal + « Plus tard ».
          Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
            decoration: BoxDecoration(
              color: OC.paper,
              border: Border(top: BorderSide(color: OC.line, width: 1.5)),
            ),
            child: Column(children: [
              GestureDetector(
                onTap: _saving ? null : _next,
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: _saving
                      ? const Center(child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(isLast ? 'Entrer dans OnBuch' : 'Continuer',
                              style: body(14, weight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 8),
                          Icon(isLast ? Icons.arrow_forward_rounded : Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: isLast ? 17 : 14),
                        ]),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _saving ? null : () => context.go('/home'),
                child: Center(child: Text('Plus tard', style: body(13.5, weight: FontWeight.w600, color: OC.muted))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Corps de chaque section ────────────────────────────────────────────────
  List<Widget> _sectionBody() => switch (_section) {
        0 => [
            _groupLabel('Ta classe / niveau'),
            _choice(_classes, _classe, (v) => setState(() => _classe = v!)),
            const SizedBox(height: 20),
            _groupLabel('Examen / concours visé'),
            _choice(_exams, _examen, (v) => setState(() { _examen = v!; _serie = null; })),
            const SizedBox(height: 20),
            SeriesPicker(
              exam: _examen,
              value: _serie,
              label: 'Série / filière (optionnel)',
              onChanged: (v) => setState(() => _serie = v),
            ),
          ],
        1 => [
            _groupLabel('Quel domaine te fait vibrer ?'),
            _choice(_fields, _studyField, (v) => setState(() => _studyField = v), allowUnset: true),
            const SizedBox(height: 20),
            _field('Ton métier de rêve (optionnel)', _careerCtrl,
                'Médecin, ingénieur·e, avocat·e…', Icons.auto_awesome_outlined),
            const SizedBox(height: 20),
            _groupLabel('Où aimerais-tu étudier ?'),
            _choice(_destinations, _destination, (v) => setState(() => _destination = v), allowUnset: true),
          ],
        _ => [
            _field('Établissement (optionnel)', _ecoleCtrl, 'Lycée de Bonabéri',
                Icons.account_balance_outlined),
            const SizedBox(height: 16),
            _field('Ville (optionnel)', _villeCtrl, 'Douala', Icons.location_on_outlined),
            const SizedBox(height: 16),
            _field('Numéro WhatsApp (optionnel)', _phoneCtrl, '+237 6XX XX XX XX',
                Icons.chat_rounded, keyboard: TextInputType.phone),
            const SizedBox(height: 20),
            _groupLabel('Sexe (optionnel)'),
            _choice(_genders, _gender, (v) => setState(() => _gender = v), allowUnset: true),
          ],
      };

  // ── Widgets utilitaires ────────────────────────────────────────────────────
  Widget _groupLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Text(t, style: body(13.5, weight: FontWeight.w800, color: OC.ink2)),
      );

  /// Groupe de puces à sélection unique. [allowUnset] permet de désélectionner
  /// (champ optionnel) ; sinon une valeur reste toujours active.
  Widget _choice(List<String> opts, String? value, ValueChanged<String?> onChanged,
      {bool allowUnset = false}) {
    return Wrap(spacing: 9, runSpacing: 9, children: opts.map((o) {
      final on = value == o;
      return GestureDetector(
        onTap: () => onChanged(on && allowUnset ? null : o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: on ? OC.o50 : OC.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
          ),
          child: Text(o, style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
        ),
      );
    }).toList());
  }

  Widget _field(String label, TextEditingController c, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: body(13, weight: FontWeight.w700, color: OC.ink2)),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        keyboardType: keyboard,
        textCapitalization: keyboard == TextInputType.phone
            ? TextCapitalization.none
            : TextCapitalization.words,
        style: body(15, color: OC.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: body(14, color: OC.muted),
          prefixIcon: Icon(icon, color: OC.muted, size: 20),
          filled: true,
          fillColor: OC.paper,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.line2, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OC.o500, width: 2)),
        ),
      ),
    ]);
  }
}
