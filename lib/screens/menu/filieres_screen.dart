import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../models/filiere.dart';
import '../../data/filieres.dart';

/// Page **Filières** (Orientation) : annuaire des filières de formation du
/// supérieur camerounais. L'élève cherche une filière, vérifie qu'elle existe,
/// la filtre par domaine, et ouvre sa fiche (où la faire, concours, débouchés…).
class FilieresScreen extends StatefulWidget {
  const FilieresScreen({super.key});

  @override
  State<FilieresScreen> createState() => _FilieresScreenState();
}

class _FilieresScreenState extends State<FilieresScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _domain = 'Tous';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Ordre d'affichage des domaines (filtres) — déduits de la base, ordre stable.
  List<String> get _domains {
    final seen = <String>[];
    for (final f in kFilieres) {
      if (!seen.contains(f.domain)) seen.add(f.domain);
    }
    return seen;
  }

  bool _matches(Filiere f) {
    if (_domain != 'Tous' && f.domain != _domain) return false;
    if (_query.isEmpty) return true;
    return f.searchBlob.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final list = kFilieres.where(_matches).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Filières'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
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
                const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text('Quelle filière pour toi ?', style: display(17, weight: FontWeight.w700, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Cherche une filière, vois où l\'étudier au Cameroun, les concours à '
                'passer, les compétences attendues et les métiers auxquels elle mène.',
                style: body(12.5, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w500)
                    .copyWith(height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _searchField(),
          const SizedBox(height: 12),
          // Filtres par domaine (défilants)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final d in ['Tous', ..._domains])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _domain = d),
                      child: OBChip(d, active: _domain == d),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('${list.length} filière${list.length > 1 ? 's' : ''}',
              style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.travel_explore_rounded,
              title: 'Aucune filière',
              message: 'Aucune filière ne correspond à ta recherche. Essaie un autre '
                  'mot-clé (ex. « génie », « santé », « droit »).',
            )
          else
            for (var i = 0; i < list.length; i++)
              Appear(index: i, child: Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _FiliereCard(list[i]),
              )),
        ],
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
              hintText: 'Filière, métier, domaine…',
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

class _FiliereCard extends StatelessWidget {
  final Filiere f;
  const _FiliereCard(this.f);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/filiere', extra: f),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: f.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(f.icon, size: 22, color: f.accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(14, weight: FontWeight.w800).copyWith(height: 1.15)),
              const SizedBox(height: 3),
              Text(f.domain, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11, color: f.accent, weight: FontWeight.w700)),
            ])),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
          ]),
          const SizedBox(height: 10),
          Text(f.tagline, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: body(12, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _pill(Icons.workspace_premium_rounded, f.diplomas.isNotEmpty ? f.diplomas.first : 'Diplôme'),
            _pill(Icons.schedule_rounded, f.duration),
            if (f.universities.isNotEmpty)
              _pill(Icons.account_balance_rounded,
                  '${f.universities.length} établissement${f.universities.length > 1 ? 's' : ''}'),
          ]),
        ]),
      ),
    );
  }

  Widget _pill(IconData ic, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 12, color: OC.muted),
          const SizedBox(width: 5),
          Text(t, style: body(10.5, color: OC.ink2, weight: FontWeight.w600)),
        ]),
      );
}
