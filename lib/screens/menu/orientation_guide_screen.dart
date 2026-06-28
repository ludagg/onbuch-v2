import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/leo_mascot.dart';
import '../../data/orientation_guide.dart';

/// Guide d'orientation : présente chaque grande filière post-bac camerounaise
/// et ses débouchés concrets, pour aider le bachelier à choisir sa voie.
class OrientationGuideScreen extends StatelessWidget {
  const OrientationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Guide d\'orientation'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // En-tête pédagogique
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [OC.darkHero, OC.darkHero2]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.explore_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text('Trouve ta voie', style: display(18, weight: FontWeight.w700, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Après le Bac, chaque concours ouvre des portes différentes. '
                'Découvre les grandes filières du Cameroun et les métiers auxquels '
                'elles mènent — pour choisir en connaissance de cause.',
                style: body(12.5, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w500)
                    .copyWith(height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Assistant d'orientation dédié (séparé du tuteur).
          GestureDetector(
            onTap: () => context.push('/orientation-chat'),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              decoration: BoxDecoration(
                color: OC.o50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OC.o200, width: 1.5),
              ),
              child: Row(children: [
                const LeoMascot(size: 44, mood: LeoMood.wave),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Demander à Léo', style: body(14.5, weight: FontWeight.w800, color: OC.o700)),
                  const SizedBox(height: 2),
                  Text('Ton conseiller d\'orientation : filière, école, métier, concours.',
                      style: body(11.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.3)),
                ])),
                Icon(Icons.chevron_right_rounded, size: 20, color: OC.o600),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < kOrientationGuide.length; i++)
            Appear(index: i, child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FieldCard(kOrientationGuide[i]),
            )),
        ],
      ),
    );
  }
}

class _FieldCard extends StatefulWidget {
  final OrientationField field;
  const _FieldCard(this.field);

  @override
  State<_FieldCard> createState() => _FieldCardState();
}

class _FieldCardState extends State<_FieldCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    return Container(
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // En-tête cliquable
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(f.icon, size: 22, color: f.accent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.title, style: body(14, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(f.tagline, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: body(11.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.3)),
              ])),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: OC.muted),
              ),
            ]),
          ),
        ),
        // Contenu déroulant
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              _section('Débouchés', f.accent),
              const SizedBox(height: 8),
              for (final d in f.debouches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(Icons.check_circle_rounded, size: 14, color: f.accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d,
                        style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4))),
                  ]),
                ),
              if (f.schools.isNotEmpty) ...[
                const SizedBox(height: 10),
                _section('Écoles & exemples', OC.muted),
                const SizedBox(height: 8),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  for (final s in f.schools)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: OC.panel, borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(s, style: body(11, color: OC.ink2, weight: FontWeight.w600)),
                    ),
                ]),
              ],
            ]),
          ),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ]),
    );
  }

  Widget _section(String t, Color c) => Text(t.toUpperCase(),
      style: body(10.5, weight: FontWeight.w800, color: c).copyWith(letterSpacing: 0.06 * 10.5));
}
