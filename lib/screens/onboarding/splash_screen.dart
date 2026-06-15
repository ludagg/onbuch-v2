import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/onboarding/1');
    });
  }

  @override
  void dispose() {
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
            // texture blobs
            Positioned(top: -90, right: -80,
              child: _blob(280, Colors.white.withValues(alpha:0.10))),
            Positioned(bottom: 40, left: -70,
              child: _blob(200, Colors.white.withValues(alpha:0.08))),
            // content
            SafeArea(
              child: Column(children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scale,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 110,
                    height: 110,
                  ),
                ),
                const SizedBox(height: 22),
                OBWordmark(size: 38, light: true),
                const SizedBox(height: 12),
                Text(
                  'Tes résultats. Ton tuteur. Ta réussite\n— dans une seule app.',
                  textAlign: TextAlign.center,
                  style: body(14.5, color: Colors.white.withValues(alpha:0.88)),
                ),
                const Spacer(),
                Column(children: [
                  SizedBox(
                    width: 26, height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.6,
                      backgroundColor: Colors.white.withValues(alpha:0.28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('LuvviX · Douala', style: body(12, weight: FontWeight.w600, color: Colors.white.withValues(alpha:0.75))),
                  const SizedBox(height: 40),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
