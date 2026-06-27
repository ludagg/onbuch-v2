import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../models/filiere.dart';

/// Fiche détaillée d'une filière : présentation, diplômes & durée, séries du Bac
/// conseillées, établissements où l'étudier, concours/accès, compétences
/// attendues et débouchés (métiers).
class FiliereDetailScreen extends StatelessWidget {
  final Filiere? filiere;
  const FiliereDetailScreen({super.key, this.filiere});

  @override
  Widget build(BuildContext context) {
    final f = filiere;
    if (f == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'Filière'),
        body: const EmptyState(
          icon: Icons.travel_explore_rounded,
          title: 'Filière introuvable',
          message: 'Reviens à la liste des filières et réessaie.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, f.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [f.accent, Color.lerp(f.accent, Colors.black, 0.28)!]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 50, height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(f.icon, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.name, style: display(19, weight: FontWeight.w800, color: Colors.white).copyWith(height: 1.15)),
                  const SizedBox(height: 3),
                  Text(f.domain, style: body(12, color: Colors.white.withValues(alpha: 0.85), weight: FontWeight.w700)),
                ])),
              ]),
              const SizedBox(height: 13),
              Text(f.tagline,
                  style: body(13, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w500).copyWith(height: 1.45)),
            ]),
          ),
          const SizedBox(height: 16),

          // Présentation
          if (f.description.trim().isNotEmpty)
            _Card(
              icon: Icons.info_outline_rounded, accent: f.accent, title: 'Présentation',
              child: Text(f.description,
                  style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5)),
            ),

          // Diplômes · durée · séries du Bac
          _Card(
            icon: Icons.workspace_premium_rounded, accent: f.accent, title: 'Le cursus',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _kv('Diplômes', f.diplomas.join(' · '), f.accent),
              const SizedBox(height: 10),
              _kv('Durée', f.duration, f.accent),
              if (f.bacSeries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('SÉRIES DU BAC CONSEILLÉES',
                    style: body(10, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  for (final s in f.bacSeries)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: f.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(s, style: body(12, color: f.accent, weight: FontWeight.w800)),
                    ),
                ]),
              ],
            ]),
          ),

          // Où l'étudier
          if (f.universities.isNotEmpty)
            _Card(
              icon: Icons.account_balance_rounded, accent: f.accent, title: 'Où l\'étudier',
              trailing: _link(context, 'Universités', () => context.push('/universites')),
              child: Column(children: [
                for (final u in f.universities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.school_rounded, size: 14, color: f.accent),
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(u,
                          style: body(13, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.4))),
                    ]),
                  ),
              ]),
            ),

          // Concours / accès
          _Card(
            icon: Icons.emoji_events_rounded, accent: f.accent, title: 'Concours & accès',
            trailing: _link(context, 'Concours', () => context.push('/concours-all')),
            child: f.concours.isEmpty
                ? Text('Admission généralement sur dossier / inscription en faculté, '
                    'sans concours d\'entrée.',
                    style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45))
                : Column(children: [
                    for (final c in f.concours)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.flag_rounded, size: 14, color: f.accent),
                          ),
                          const SizedBox(width: 9),
                          Expanded(child: Text(c,
                              style: body(13, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.4))),
                        ]),
                      ),
                  ]),
          ),

          // Compétences
          if (f.skills.isNotEmpty)
            _Card(
              icon: Icons.psychology_rounded, accent: f.accent, title: 'Compétences & qualités',
              child: Wrap(spacing: 7, runSpacing: 7, children: [
                for (final s in f.skills)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(10)),
                    child: Text(s, style: body(12, color: OC.ink2, weight: FontWeight.w600)),
                  ),
              ]),
            ),

          // Débouchés
          if (f.debouches.isNotEmpty)
            _Card(
              icon: Icons.work_rounded, accent: f.accent, title: 'Débouchés & métiers',
              child: Column(children: [
                for (final d in f.debouches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle_rounded, size: 14, color: f.accent),
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(d,
                          style: body(13, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.4))),
                    ]),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color accent) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 78, child: Text(k.toUpperCase(),
              style: body(10, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 0.6))),
          const SizedBox(width: 8),
          Expanded(child: Text(v, style: body(13, color: OC.ink, weight: FontWeight.w700).copyWith(height: 1.35))),
        ],
      );

  Widget _link(BuildContext context, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: body(11.5, color: OC.o600, weight: FontWeight.w800)),
          Icon(Icons.chevron_right_rounded, size: 16, color: OC.o600),
        ]),
      );
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.icon, required this.accent, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 9),
          Expanded(child: Text(title, style: body(14, weight: FontWeight.w800))),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
