import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/gamification_service.dart';

/// Carte « série » (streak) : nombre de jours d'affilée où l'élève a ouvert
/// l'app + bande des 7 derniers jours (jours actifs en flamme).
///
/// Source : [GamificationService] (déjà alimenté par `recordActivity()` à
/// l'ouverture). Les jours actifs sont reconstruits depuis `lastActive` et la
/// longueur de la série (pas d'historique jour-par-jour stocké).
class StreakCard extends StatefulWidget {
  /// Variante resserrée (ex. en-tête du menu latéral).
  final bool compact;
  const StreakCard({super.key, this.compact = false});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  static const _flame = Color(0xFFF4711E);
  static const _flame2 = Color(0xFFE23B2E);

  @override
  void initState() {
    super.initState();
    // Idempotent : garantit des données même si on arrive ici sans passer par
    // l'accueil (deep-link profil, etc.).
    GamificationService.instance.load();
  }

  DateTime? _parse(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  bool _activeOn(DateTime day, GamificationState s) {
    final last = _parse(s.lastActive);
    if (last == null || s.streak <= 0) return false;
    final start = last.subtract(Duration(days: s.streak - 1));
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(last);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GamificationState>(
      valueListenable: GamificationService.instance.state,
      builder: (context, s, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
        final streak = s.streak;
        final pad = widget.compact ? 14.0 : 16.0;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_flame, _flame2],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: widget.compact ? 30 : 34),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text('$streak', style: display(widget.compact ? 24 : 28, weight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(width: 6),
                  Text(streak <= 1 ? 'jour' : 'jours',
                      style: body(13, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
                ]),
                Text(
                  streak <= 0
                      ? 'Ouvre l\'app chaque jour'
                      : 'Série en cours · record ${s.bestStreak}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ])),
            ]),
            SizedBox(height: widget.compact ? 12 : 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final d in days) _dayDot(d, today, _activeOn(d, s))],
            ),
          ]),
        );
      },
    );
  }

  Widget _dayDot(DateTime day, DateTime today, bool active) {
    const labels = 'LMMJVSD';
    final letter = labels[day.weekday - 1];
    final isToday = day == today;
    final size = widget.compact ? 26.0 : 30.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: active
            ? Icon(Icons.local_fire_department_rounded, size: size * 0.58, color: _flame)
            : Text(letter, style: body(12, weight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.85))),
      ),
      const SizedBox(height: 4),
      Text(letter, style: body(9.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.75))),
    ]);
  }
}
