import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/skeletons.dart';
import '../../models/metier.dart';
import '../../services/database_service.dart';

/// « Découvre ton futur métier » : annuaire des fiches métiers (orientation),
/// recherche + filtre par secteur. Tap → fiche complète.
class MetiersScreen extends StatefulWidget {
  const MetiersScreen({super.key});

  @override
  State<MetiersScreen> createState() => _MetiersScreenState();
}

class _MetiersScreenState extends State<MetiersScreen> {
  final _searchCtrl = TextEditingController();
  late final Future<List<Metier>> _future = DatabaseService().getMetiers();
  String _query = '';
  String _sector = 'Tous';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Métiers'),
      body: FutureBuilder<List<Metier>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 28), children: const [SkeletonList(count: 6)]);
          }
          final all = snap.data ?? const <Metier>[];
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.work_rounded,
              title: 'Bientôt disponible',
              message: 'Les fiches métiers arrivent très vite pour t\'aider à choisir ta voie.',
            );
          }
          final sectors = <String>[];
          for (final m in all) {
            if (m.sector.isNotEmpty && !sectors.contains(m.sector)) sectors.add(m.sector);
          }
          sectors.sort();
          final list = all.where((m) {
            if (_sector != 'Tous' && m.sector != _sector) return false;
            if (_query.isEmpty) return true;
            return m.searchBlob.contains(_query);
          }).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.work_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text('Découvre ton futur métier', style: display(16, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                  const SizedBox(height: 8),
                  Text('Salaire, compétences, études, débouchés : tout pour choisir ton métier en connaissance de cause.',
                      style: body(12.5, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w500).copyWith(height: 1.5)),
                ]),
              ),
              const SizedBox(height: 14),
              _searchField(),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final s in ['Tous', ...sectors])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(onTap: () => setState(() => _sector = s), child: OBChip(s, active: _sector == s)),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              Text('${list.length} métier${list.length > 1 ? 's' : ''}', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(icon: Icons.work_rounded, title: 'Aucun métier', message: 'Essaie un autre mot-clé ou secteur.')
              else
                for (var i = 0; i < list.length; i++)
                  Appear(index: i, child: Padding(padding: const EdgeInsets.only(bottom: 11), child: _MetierCard(list[i]))),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.line2, width: 1.5)),
      child: Row(children: [
        Icon(Icons.search_rounded, size: 19, color: OC.muted),
        const SizedBox(width: 11),
        Expanded(child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          style: body(14, color: OC.ink),
          decoration: InputDecoration(
            isDense: true, border: InputBorder.none,
            hintText: 'Métier, secteur, compétence…',
            hintStyle: body(14, color: OC.muted, weight: FontWeight.w500),
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        )),
        if (_query.isNotEmpty)
          GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18))),
      ]),
    );
  }
}

class _MetierCard extends StatelessWidget {
  final Metier m;
  const _MetierCard(this.m);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/metier', extra: m),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          Container(
            width: 46, height: 46, alignment: Alignment.center,
            decoration: BoxDecoration(color: m.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(m.iconData, size: 22, color: m.accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w800)),
            if (m.sector.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.sector, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11, color: m.accent, weight: FontWeight.w700)),
            ],
            if (m.educationLevel.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(m.educationLevel, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11, color: OC.muted, weight: FontWeight.w500)),
            ],
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
        ]),
      ),
    );
  }
}

/// Fiche complète d'un métier.
class MetierDetailScreen extends StatelessWidget {
  final Metier? metier;
  const MetierDetailScreen({super.key, this.metier});

  @override
  Widget build(BuildContext context) {
    final m = metier;
    if (m == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'Métier'),
        body: const EmptyState(icon: Icons.work_rounded, title: 'Métier introuvable', message: 'Reviens à la liste et réessaie.'),
      );
    }
    final c = m.accent;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, m.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c, Color.lerp(c, Colors.black, 0.28)!]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(15)),
                child: Icon(m.iconData, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, style: display(19, weight: FontWeight.w800, color: Colors.white).copyWith(height: 1.15)),
                if (m.sector.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(m.sector, style: body(12, color: Colors.white.withValues(alpha: 0.85), weight: FontWeight.w700)),
                ],
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          if (m.description.isNotEmpty) ...[
            Text(m.description, style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5)),
            const SizedBox(height: 18),
          ],

          // Salaire (admin)
          if (m.salary.isNotEmpty)
            _card(Icons.payments_rounded, c, 'Salaire moyen au Cameroun', child: Text(m.salary, style: display(18, weight: FontWeight.w800, color: OC.o700)))
          else
            _card(Icons.payments_rounded, c, 'Salaire moyen au Cameroun', child: Text('Bientôt renseigné.', style: body(12.5, color: OC.muted, weight: FontWeight.w500))),

          if (m.educationLevel.isNotEmpty)
            _card(Icons.school_rounded, c, 'Niveau d\'études nécessaire', child: Text(m.educationLevel, style: body(13, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.4))),

          if (m.skills.isNotEmpty)
            _card(Icons.psychology_rounded, c, 'Compétences requises', child: _chips(m.skills)),

          if (m.prospects.isNotEmpty)
            _card(Icons.trending_up_rounded, c, 'Perspectives d\'emploi', child: Text(m.prospects, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45))),

          if (m.careerPath.isNotEmpty)
            _card(Icons.timeline_rounded, c, 'Évolution de carrière', child: Text(m.careerPath, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45))),

          if (m.relatedFilieres.isNotEmpty)
            _card(Icons.alt_route_rounded, c, 'Filières liées', child: _chips(m.relatedFilieres)),

          if (m.testimonials.isNotEmpty)
            _card(Icons.format_quote_rounded, c, 'Témoignages de professionnels',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final t in m.testimonials)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(12)),
                        child: Text('« $t »', style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45, fontStyle: FontStyle.italic)),
                      ),
                    ),
                ])),
        ],
      ),
    );
  }

  Widget _card(IconData ic, Color c, String title, {required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ic, size: 18, color: c),
            const SizedBox(width: 9),
            Expanded(child: Text(title, style: body(14, weight: FontWeight.w800))),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _chips(List<String> items) => Wrap(spacing: 7, runSpacing: 7, children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(10)),
            child: Text(it, style: body(12, color: OC.ink2, weight: FontWeight.w600)),
          ),
      ]);
}
