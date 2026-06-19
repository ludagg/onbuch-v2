import 'package:flutter/material.dart';

/// Léo, la mascotte OnBuch (petit lion). Affiché **animé** (léger flottement
/// + respiration) pour le rendre vivant, jamais figé. Image transparente
/// réutilisable partout.
class LeoMascot extends StatefulWidget {
  final double size;

  /// Décalage de phase pour désynchroniser plusieurs mascottes à l'écran.
  final double phase;
  const LeoMascot({super.key, this.size = 64, this.phase = 0});

  @override
  State<LeoMascot> createState() => _LeoMascotState();
}

class _LeoMascotState extends State<LeoMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Valeur 0→1→0 douce, décalée par `phase`.
        final raw = (_c.value + widget.phase) % 1.0;
        final t = Curves.easeInOut.transform(raw <= 0.5 ? raw * 2 : (1 - raw) * 2);
        final dy = -widget.size * 0.05 * t; // flottement vertical
        final scale = 1 + 0.03 * t; // respiration
        final tilt = (t - 0.5) * 0.04; // léger balancement
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Image.asset(
        'assets/images/leo.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
