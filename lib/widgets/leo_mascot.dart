import 'package:flutter/material.dart';

/// Humeurs disponibles de Léo (chaque humeur = un asset transparent).
///
/// Les 4 dernières (`sleepy/sad/fire/alarm`) servent aux rappels de série
/// (notifications) : Léo qui dort, Léo triste (sablier), Léo qui brandit une
/// flamme, Léo à l'heure de réviser (réveil).
enum LeoMood { idle, thinking, celebrate, encourage, wave, lab, sleepy, sad, fire, alarm }

const Map<LeoMood, String> _leoAssets = {
  LeoMood.idle: 'assets/images/leo.png',
  LeoMood.thinking: 'assets/images/leo_thinking.png',
  LeoMood.celebrate: 'assets/images/leo_celebrate.png',
  LeoMood.encourage: 'assets/images/leo_encourage.png',
  LeoMood.wave: 'assets/images/leo_wave.png',
  LeoMood.lab: 'assets/images/leo_lab.png',
  // Rappels / série.
  LeoMood.sleepy: 'assets/images/leo_sleepy.png',
  LeoMood.sad: 'assets/images/leo_sad.png',
  LeoMood.fire: 'assets/images/leo_fire.png',
  LeoMood.alarm: 'assets/images/leo_alarm.png',
};

/// Léo, la mascotte OnBuch (petit lion). Affiché **animé** (léger flottement
/// + respiration) pour le rendre vivant, jamais figé. [mood] choisit l'humeur.
class LeoMascot extends StatefulWidget {
  final double size;
  final LeoMood mood;

  /// Décalage de phase pour désynchroniser plusieurs mascottes à l'écran.
  final double phase;
  const LeoMascot({super.key, this.size = 64, this.mood = LeoMood.idle, this.phase = 0});

  @override
  State<LeoMascot> createState() => _LeoMascotState();
}

class _LeoMascotState extends State<LeoMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // Léo « réfléchit » bouge un peu plus vite (effet vivant pendant l'attente).
    duration: Duration(milliseconds: widget.mood == LeoMood.thinking ? 1700 : 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _leoAssets[widget.mood] ?? _leoAssets[LeoMood.idle]!;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
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
        asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
