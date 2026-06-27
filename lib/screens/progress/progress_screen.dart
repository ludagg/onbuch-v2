import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/streak_card.dart';
import '../../services/gamification_service.dart';
import '../../services/exercise_service.dart';
import '../../services/tutor_service.dart';
import '../../models/exercise.dart';

/// « Ma progression » : niveau (XP), série, activité réelle, prochain objectif,
/// badges (avec détail) et paliers de niveaux à venir.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _exosDone = 0;
  int _exosFound = 0;
  int _corrections = 0;

  @override
  void initState() {
    super.initState();
    GamificationService.instance.load();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    try {
      final progress = await ExerciseService().loadProgress();
      final corrections = await TutorService().correctionsCount();
      if (!mounted) return;
      setState(() {
        _exosDone = progress.values.where((s) => s != ExerciseStatus.none).length;
        _exosFound = progress.values.where((s) => s == ExerciseStatus.found).length;
        _corrections = corrections;
      });
    } catch (_) {/* hors-ligne → on garde 0 */}
  }

  // ── Progression d'un badge : (valeur courante, cible) ───────────────────────
  (int, int) _badgeProgress(GameBadge b, GamificationState s) {
    switch (b.id) {
      case 'first_quiz':
        return (s.quizzes, 1);
      case 'quiz_10':
        return (s.quizzes, 10);
      case 'streak_3':
        return (s.bestStreak, 3);
      case 'streak_7':
        return (s.bestStreak, 7);
      case 'streak_30':
        return (s.bestStreak, 30);
      case 'tutor_5':
        return (s.tutorUses, 5);
      case 'xp_500':
        return (s.xp, 500);
      case 'xp_2000':
        return (s.xp, 2000);
      default:
        return (b.earned(s) ? 1 : 0, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Ma progression'),
      body: ValueListenableBuilder<GamificationState>(
        valueListenable: GamificationService.instance.state,
        builder: (context, s, _) {
          // Prochain objectif : badge non obtenu le plus proche d'être débloqué.
          GameBadge? next;
          double nextRatio = -1;
          for (final b in kBadges) {
            if (s.badges.contains(b.id) || b.earned(s)) continue;
            final (cur, tgt) = _badgeProgress(b, s);
            final r = tgt == 0 ? 0.0 : (cur / tgt).clamp(0.0, 1.0);
            if (r > nextRatio) {
              nextRatio = r;
              next = b;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              _levelCard(s),
              const SizedBox(height: 14),
              const StreakCard(),
              const SizedBox(height: 22),

              Text('Mon activité', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              _activityGrid(s),
              const SizedBox(height: 22),

              if (next != null) ...[
                Text('Prochain objectif', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 12),
                _nextObjective(next, s),
                const SizedBox(height: 22),
              ],

              Row(children: [
                Text('Badges', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
                const Spacer(),
                Text('${s.badges.length}/${kBadges.length}',
                    style: body(12.5, weight: FontWeight.w700, color: OC.muted)),
              ]),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: kBadges
                    .map((b) => _badgeTile(b, s.badges.contains(b.id) || b.earned(s), s))
                    .toList(),
              ),
              const SizedBox(height: 22),

              Text('Prochains niveaux', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              _levelsRoadmap(s),
            ],
          );
        },
      ),
    );
  }

  // ── Héros niveau ────────────────────────────────────────────────────────────
  Widget _levelCard(GamificationState s) {
    final toNext = (s.xpForLevel - s.xpInLevel).clamp(0, s.xpForLevel);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: OC.gradSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          OBRing(
            pct: s.levelProgress,
            size: 88,
            color: OC.o500,
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Niv.', style: body(10, weight: FontWeight.w700, color: OC.muted)),
              Text('${s.level}', style: display(26, weight: FontWeight.w800, color: OC.o700)),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.xp} XP', style: display(24, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Encore $toNext XP pour le niveau ${s.level + 1}',
                style: body(12.5, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.3)),
          ])),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: s.levelProgress,
            minHeight: 9,
            backgroundColor: OC.o100,
            valueColor: const AlwaysStoppedAnimation(OC.o500),
          ),
        ),
      ]),
    );
  }

  // ── Grille d'activité (6 tuiles, données réelles) ───────────────────────────
  Widget _activityGrid(GamificationState s) {
    final tiles = [
      _Stat(Icons.local_fire_department_rounded, const Color(0xFFF4711E), '${s.streak} j', 'Série'),
      _Stat(Icons.military_tech_rounded, const Color(0xFFC9821C), '${s.bestStreak} j', 'Record'),
      _Stat(Icons.psychology_rounded, const Color(0xFF7A5AE0), '${s.quizzes}', 'Quiz'),
      _Stat(Icons.forum_rounded, OC.o600, '${s.tutorUses}', 'Léo'),
      _Stat(Icons.edit_note_rounded, OC.blue, '$_exosDone', 'Exercices'),
      _Stat(Icons.fact_check_rounded, OC.good, '$_corrections', 'Corrections'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: tiles.map(_statCard).toList(),
    );
  }

  Widget _statCard(_Stat t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 34, height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(t.icon, size: 19, color: t.color),
        ),
        const SizedBox(height: 8),
        Text(t.value, style: display(18, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: body(11, color: OC.muted, weight: FontWeight.w600)),
      ]),
    );
  }

  // ── Prochain objectif (badge le plus proche) ────────────────────────────────
  Widget _nextObjective(GameBadge b, GamificationState s) {
    final (cur, tgt) = _badgeProgress(b, s);
    final pct = tgt == 0 ? 0.0 : (cur / tgt).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5)),
      child: Row(children: [
        OBRing(
          pct: pct, size: 56, color: OC.o500,
          center: Icon(b.icon, size: 24, color: OC.o600),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.label, style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(b.desc, style: body(11.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.3)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct, minHeight: 7,
                backgroundColor: OC.o100, valueColor: const AlwaysStoppedAnimation(OC.o500),
              ),
            )),
            const SizedBox(width: 8),
            Text('$cur/$tgt', style: mono(11.5, weight: FontWeight.w800, color: OC.o700)),
          ]),
        ])),
      ]),
    );
  }

  // ── Badges (tap → détail) ───────────────────────────────────────────────────
  Widget _badgeTile(GameBadge b, bool earned, GamificationState s) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showBadge(b, earned, s),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: earned ? OC.o50 : OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? OC.o100 : OC.line, width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(b.icon, size: 30, color: earned ? OC.o600 : OC.faint),
          const SizedBox(height: 6),
          Text(b.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: body(10.5, weight: FontWeight.w700, color: earned ? OC.ink : OC.muted)),
          const SizedBox(height: 2),
          Text(earned ? 'Obtenu ✓' : _badgeShort(b, s), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: body(9, color: earned ? OC.o600 : OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  String _badgeShort(GameBadge b, GamificationState s) {
    final (cur, tgt) = _badgeProgress(b, s);
    return '$cur/$tgt';
  }

  void _showBadge(GameBadge b, bool earned, GamificationState s) {
    final (cur, tgt) = _badgeProgress(b, s);
    final pct = tgt == 0 ? 0.0 : (cur / tgt).clamp(0.0, 1.0);
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 20),
          Container(
            width: 84, height: 84, alignment: Alignment.center,
            decoration: BoxDecoration(color: earned ? OC.o50 : OC.panel, shape: BoxShape.circle),
            child: Icon(b.icon, size: 42, color: earned ? OC.o600 : OC.faint),
          ),
          const SizedBox(height: 14),
          Text(b.label, style: display(19, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(b.desc, textAlign: TextAlign.center,
              style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 18),
          if (earned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, size: 17, color: OC.good),
                const SizedBox(width: 7),
                Text('Badge obtenu', style: body(13, weight: FontWeight.w800, color: OC.good)),
              ]),
            )
          else ...[
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 9, backgroundColor: OC.o100, valueColor: const AlwaysStoppedAnimation(OC.o500)),
              )),
              const SizedBox(width: 10),
              Text('$cur/$tgt', style: mono(13, weight: FontWeight.w800, color: OC.o700)),
            ]),
          ],
        ]),
      ),
    );
  }

  // ── Paliers de niveaux à venir ──────────────────────────────────────────────
  Widget _levelsRoadmap(GamificationState s) {
    // XP cumulé pour atteindre le niveau L : 50·(L-1)·L.
    int floorXp(int level) => 50 * (level - 1) * level;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final lvl = s.level + i;
          final current = i == 0;
          final reached = floorXp(lvl);
          final remaining = (reached - s.xp).clamp(0, 1 << 30);
          return Container(
            width: 92,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: current ? OC.o50 : OC.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: current ? OC.o500 : OC.line, width: current ? 2 : 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: current ? OC.o500 : OC.panel, borderRadius: BorderRadius.circular(8)),
                child: Text('Niv. $lvl', style: body(11, weight: FontWeight.w800, color: current ? Colors.white : OC.ink2)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(current ? 'Actuel' : '$remaining XP', style: display(14, weight: FontWeight.w800, color: current ? OC.o700 : OC.ink)),
                const SizedBox(height: 1),
                Text(current ? 'en cours' : 'à atteindre', style: body(9.5, color: OC.muted, weight: FontWeight.w600)),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

class _Stat {
  final IconData icon;
  final Color color;
  final String value, label;
  const _Stat(this.icon, this.color, this.value, this.label);
}
