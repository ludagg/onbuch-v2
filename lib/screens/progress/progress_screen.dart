import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/gamification_service.dart';

/// « Ma progression » : niveau (XP), streak, stats et badges.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Ma progression'),
      body: ValueListenableBuilder<GamificationState>(
        valueListenable: GamificationService.instance.state,
        builder: (context, s, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              _levelCard(s),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _statCard('🔥', '${s.streak} j', 'Série en cours')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('🏅', '${s.bestStreak} j', 'Record')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCard('🧠', '${s.quizzes}', 'Quiz terminés')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('🦁', '${s.tutorUses}', 'Questions à Léo')),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Text('Badges', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
                const Spacer(),
                Text('${s.badges.length}/${kBadges.length}', style: body(12.5, weight: FontWeight.w700, color: OC.muted)),
              ]),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
                children: kBadges.map((b) => _badgeTile(b, s.badges.contains(b.id))).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _levelCard(GamificationState s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: OC.gradSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Row(children: [
        OBRing(
          pct: s.levelProgress,
          size: 86,
          color: OC.o500,
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Niv.', style: body(10, weight: FontWeight.w700, color: OC.muted)),
            Text('${s.level}', style: display(26, weight: FontWeight.w800, color: OC.o700)),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s.xp} XP', style: display(22, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Encore ${s.xpForLevel - s.xpInLevel} XP pour le niveau ${s.level + 1}',
              style: body(12.5, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.3)),
        ])),
      ]),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(value, style: display(19, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(label, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
      ]),
    );
  }

  Widget _badgeTile(GameBadge b, bool earned) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: earned ? OC.o50 : OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: earned ? OC.o100 : OC.line, width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Opacity(
          opacity: earned ? 1 : 0.32,
          child: Text(b.emoji, style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 7),
        Text(b.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: body(11, weight: FontWeight.w700, color: earned ? OC.ink : OC.muted)),
        const SizedBox(height: 2),
        Text(earned ? 'Obtenu' : b.desc, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: body(9.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.2)),
      ]),
    );
  }
}
