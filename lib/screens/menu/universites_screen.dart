import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/cached_image.dart';
import '../../models/university.dart';
import '../../services/database_service.dart';

/// Annuaire des universités camerounaises (page Orientation) : classement
/// indicatif, recherche, filtres par type (publique/privée) et par ville.
class UniversitesScreen extends StatefulWidget {
  const UniversitesScreen({super.key});

  @override
  State<UniversitesScreen> createState() => _UniversitesScreenState();
}

class _UniversitesScreenState extends State<UniversitesScreen> {
  final _searchCtrl = TextEditingController();
  late final Future<List<University>> _future = DatabaseService().getUniversities();
  String _query = '';
  String _type = 'Toutes'; // Toutes | Publiques | Privées
  String _city = 'Toutes'; // Toutes | <ville>

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(University u) {
    if (_type == 'Publiques' && !u.isPublic) return false;
    if (_type == 'Privées' && u.isPublic) return false;
    if (_city != 'Toutes' && u.city != _city) return false;
    if (_query.isEmpty) return true;
    bool has(String s) => s.toLowerCase().contains(_query);
    return has(u.name) || has(u.acronym) || has(u.city) || u.fields.any(has);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Universités'),
      body: FutureBuilder<List<University>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: const [SkeletonList(count: 6)],
            );
          }
          final all = [...(snap.data ?? const <University>[])]
            ..sort((a, b) {
              int r(University u) => u.rank > 0 ? u.rank : 9999;
              final byRank = r(a).compareTo(r(b));
              return byRank != 0 ? byRank : a.order.compareTo(b.order);
            });
          final cities = (all.map((u) => u.city).toSet().toList()..sort());
          final list = all.where(_matches).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              _searchField(),
              const SizedBox(height: 12),
              // Filtre type
              Row(children: [
                for (final t in const ['Toutes', 'Publiques', 'Privées'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: OBChip(t, active: _type == t),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              // Filtre ville (défilant)
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in ['Toutes', ...cities])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _city = c),
                          child: OBChip(c, active: _city == c),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('${list.length} université${list.length > 1 ? 's' : ''}',
                  style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.school_rounded,
                  title: 'Aucune université',
                  message: 'Aucune université ne correspond à ta recherche ou à tes filtres.',
                )
              else
                for (var i = 0; i < list.length; i++)
                  Appear(index: i, child: Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _UniversityCard(list[i]),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OC.line2, width: 1.5),
      ),
      child: Row(children: [
        Icon(Icons.search_rounded, size: 19, color: OC.muted),
        const SizedBox(width: 11),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            style: body(14, color: OC.ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Nom, sigle, ville, filière…',
              hintStyle: body(14, color: OC.muted, weight: FontWeight.w500),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        if (_query.isNotEmpty)
          GestureDetector(
            onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18)),
          ),
      ]),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  final University u;
  const _UniversityCard(this.u);

  @override
  Widget build(BuildContext context) {
    final accent = u.accent;
    final meta = [u.city, u.type, if (u.founded > 0) 'depuis ${u.founded}']
        .where((e) => e.trim().isNotEmpty)
        .join(' · ');
    return GestureDetector(
      onTap: () => context.push('/universite', extra: u),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Logo si disponible, sinon pastille au sigle
            if (u.hasLogo)
              Container(
                width: 50, height: 50,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CachedImage(u.logoUrl, fit: BoxFit.contain, gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Center(child: Text(u.acronym.isEmpty ? '?' : u.acronym,
                          style: display(u.acronym.length >= 4 ? 11 : 14, weight: FontWeight.w800, color: accent)))),
                ),
              )
            else
              Container(
                width: 50, height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Text(u.acronym.isEmpty ? '?' : u.acronym,
                    style: display(u.acronym.length >= 4 ? 12 : 15, weight: FontWeight.w800, color: accent)),
              ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (u.rank > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(6)),
                    child: Text('#${u.rank}', style: mono(11, weight: FontWeight.w800, color: OC.o700)),
                  ),
                  const SizedBox(width: 7),
                ],
                Expanded(child: Text(u.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: body(13.5, weight: FontWeight.w800).copyWith(height: 1.15))),
              ]),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
              ],
            ])),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
          ]),
          if (u.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(u.description, style: body(12, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
          ],
          if (u.fields.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final f in u.fields)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(8)),
                  child: Text(f, style: body(10.5, color: OC.ink2, weight: FontWeight.w600)),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}
