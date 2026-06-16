import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ));
    _loadName();
  }

  Future<void> _loadName() async {
    final user = await AuthService().getCurrentUser();
    final name = user?.name.trim() ?? '';
    if (name.isEmpty) return;
    final first = DatabaseService.splitFullName(name)['firstName'] as String?;
    if (mounted && first != null && first.isNotEmpty) setState(() => _firstName = first);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.o500,
      body: SizedBox.expand(
        child: Container(
        decoration: const BoxDecoration(gradient: OC.grad),
        child: Stack(fit: StackFit.expand, children: [
          Positioned(top: -80, left: -70, child: _blob(260, Colors.white.withValues(alpha:0.10))),
          SafeArea(
            child: Column(children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.16),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 70, height: 70,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 40, color: OC.o500),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Text(_firstName != null ? 'Tout est prêt,\n$_firstName !' : 'Tout est prêt !',
                  style: display(28, weight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'On surveille déjà la publication du Bac 2026. Tu seras la première prévenue.',
                  textAlign: TextAlign.center,
                  style: body(15, color: Colors.white.withValues(alpha:0.9)).copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('🔔 Alerte Bac active', style: body(12, weight: FontWeight.w700, color: Colors.white)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.12), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Voir mes résultats', style: body(14, weight: FontWeight.w700, color: OC.o600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: OC.o600, size: 17),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
        ),
      ),
    );
  }

  Widget _blob(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
