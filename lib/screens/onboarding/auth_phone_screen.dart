import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class AuthPhoneScreen extends StatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  State<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends State<AuthPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();

  final _authService = AuthService();
  final _databaseService = DatabaseService();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        // Connexion
        final uid = await _authService.signIn(
          _emailCtrl.text,
          _passwordCtrl.text,
        );
        if (!mounted) return;

        // Vérifier si le profil existe
        final hasProfile = await _databaseService.profileExists(uid);
        if (!mounted) return;
        context.go(hasProfile ? '/home' : '/auth/profile');
      } else {
        // Création de compte
        final uid = await _authService.register(
          _emailCtrl.text,
          _passwordCtrl.text,
          _nomCtrl.text.trim().isNotEmpty ? _nomCtrl.text.trim() : 'Utilisateur',
        );
        if (!mounted) return;

        // Pré-remplir le nom dans la base de données. Cette étape est
        // optionnelle : le profil sera de toute façon complété à l'écran
        // suivant. Si la base n'est pas joignable, on ne bloque pas
        // l'inscription qui, elle, a déjà réussi.
        if (_nomCtrl.text.trim().isNotEmpty) {
          try {
            await _databaseService.createUserProfile(
              uid,
              {'nom': _nomCtrl.text.trim()},
            );
          } catch (_) {
            // Pré-remplissage non critique — on continue.
          }
        }
        if (!mounted) return;
        context.go('/auth/profile');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e.toString(),
                style: body(13, color: Colors.white),
              ),
            ),
          ]),
          backgroundColor: OC.bad,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: OC.ink,
                onPressed: () => context.go('/onboarding/3'),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Titre
                  Text(
                    _isLogin ? 'Bienvenue 👋' : 'Créer un compte',
                    style: display(26, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Connecte-toi pour accéder à tes résultats, annales et tuteur IA.'
                        : 'Rejoins des milliers d\'élèves camerounais sur OnBuch.',
                    style: body(15, color: OC.ink2).copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 28),

                  // Champ Nom complet (inscription uniquement)
                  if (!_isLogin) ...[
                    _FieldLabel('Nom complet'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: body(15, color: OC.ink),
                      decoration: _inputDecoration(
                        hint: 'Jean-Pierre Mbarga',
                        icon: Icons.person_rounded,
                      ),
                      validator: (v) {
                        if (!_isLogin && (v == null || v.trim().isEmpty)) {
                          return 'Entre ton nom complet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Champ Email
                  _FieldLabel('Adresse e-mail'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: body(15, color: OC.ink),
                    decoration: _inputDecoration(
                      hint: 'exemple@gmail.com',
                      icon: Icons.email_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Entre ton adresse e-mail';
                      final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) return 'Adresse e-mail invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  _FieldLabel('Mot de passe'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: body(15, color: OC.ink),
                    decoration: _inputDecoration(
                      hint: _isLogin ? '••••••••' : 'Au moins 8 caractères',
                      icon: Icons.lock_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: OC.muted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Entre ton mot de passe';
                      if (!_isLogin && v.length < 8) return 'Minimum 8 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Bouton principal
                  GestureDetector(
                    onTap: _loading ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: OC.grad,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: OC.o500.withValues(alpha:0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )],
                      ),
                      child: _loading
                          ? const Center(child: SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(
                                _isLogin ? 'Se connecter' : 'Créer mon compte',
                                style: body(14, weight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle mode connexion / inscription
                  Center(
                    child: GestureDetector(
                      onTap: _toggleMode,
                      child: RichText(
                        text: TextSpan(
                          style: body(13.5, color: OC.ink2),
                          children: [
                            TextSpan(text: _isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? '),
                            TextSpan(
                              text: _isLogin ? 'Créer un compte' : 'Se connecter',
                              style: body(13.5, weight: FontWeight.w700, color: OC.o600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Séparateur
                  Row(children: [
                    const Expanded(child: Divider(color: OC.line, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OU', style: body(12, weight: FontWeight.w700, color: OC.muted)),
                    ),
                    const Expanded(child: Divider(color: OC.line, thickness: 1.5)),
                  ]),
                  const SizedBox(height: 18),

                  // Bouton Google (placeholder)
                  Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.line2, width: 1.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.g_mobiledata_rounded, size: 22, color: OC.blue),
                      const SizedBox(width: 8),
                      Text('Continuer avec Google', style: body(14, weight: FontWeight.w700, color: OC.ink)),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Mentions légales
                  Text(
                    'En continuant, tu acceptes nos Conditions et notre Politique de confidentialité. Données hébergées localement.',
                    textAlign: TextAlign.center,
                    style: body(11.5, color: OC.muted).copyWith(height: 1.45),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helpers UI ────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: body(14, color: OC.muted),
      prefixIcon: Icon(icon, color: OC.muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: OC.paper,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: OC.line2, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: OC.line2, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: OC.o500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: OC.bad, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: OC.bad, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: body(13, weight: FontWeight.w700, color: OC.ink2));
  }
}
