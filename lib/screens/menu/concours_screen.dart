import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/states.dart';
import '../../models/concours.dart';
import '../../services/database_service.dart';

/// Catalogue Concours (section A des wireframes) : recherche, raccourcis prépa,
/// emplacements partenaires, concours dont la clôture approche, et liste.
class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

enum _CFilter { tous, ouverts, cloture, resultats }

extension _CFilterX on _CFilter {
  String get label => switch (this) {
        _CFilter.tous => 'Tous',
        _CFilter.ouverts => 'Ouverts',
        _CFilter.cloture => 'Clôture proche',
        _CFilter.resultats => 'Résultats',
      };
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  final _db = DatabaseService();
  late final Future<List<Concours>> _future = _db.getConcours();
  final _searchCtrl = TextEditingController();
  String _query = '';
  _CFilter _filter = _CFilter.tous;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesQuery(Concours c) {
    if (_query.isEmpty) return true;
    bool has(String? s) => s != null && s.toLowerCase().contains(_query);
    return has(c.name) || has(c.organizer) || has(c.description) || has(c.audience);
  }

  bool _matchesFilter(Concours c) {
    final now = DateTime.now();
    switch (_filter) {
      case _CFilter.tous:
        return true;
      case _CFilter.ouverts:
        return c.registrationDeadline == null || c.registrationDeadline!.isAfter(now);
      case _CFilter.cloture:
        final dl = c.registrationDeadline;
        if (dl == null) return false;
        final d = dl.difference(now).inDays;
        return d >= 0 && d <= 14;
      case _CFilter.resultats:
        return c.resultsAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Concours', style: display(17, weight: FontWeight.w700)),
          Text('Grandes écoles & admissions', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes_rounded, size: 21),
            color: OC.ink,
            tooltip: 'Mes candidatures',
            onPressed: () => context.push('/mes-candidatures'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, size: 21),
            color: OC.ink,
            tooltip: 'Alertes & échéances',
            onPressed: () => context.push('/concours-alertes'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<Concours>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: const [
                Skeleton(width: double.infinity, height: 150, radius: 24),
                SizedBox(height: 22),
                SkeletonList(count: 4),
              ],
            );
          }
          final all = snap.data ?? const <Concours>[];

          // Aucune donnée réelle → vrai état vide (plus de faux concours).
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.track_changes_rounded,
              title: 'Aucun concours pour le moment',
              message: 'Les concours et admissions apparaîtront ici dès leur ouverture. Reviens bientôt !',
            );
          }

          final searching = _query.isNotEmpty || _filter != _CFilter.tous;

          // Clôture la plus proche → carte vedette (hors recherche/filtre).
          final upcoming = all.where((c) => c.registrationDeadline != null &&
              c.registrationDeadline!.isAfter(DateTime.now())).toList()
            ..sort((a, b) => a.registrationDeadline!.compareTo(b.registrationDeadline!));
          final featured = upcoming.isNotEmpty ? upcoming.first : all.first;

          final list = searching
              ? all.where((c) => _matchesQuery(c) && _matchesFilter(c)).toList()
              : all.where((c) => c.id != featured.id).toList();

          final headerLabel = searching
              ? '${list.length} résultat${list.length > 1 ? 's' : ''}'
              : 'Tous les concours · ${all.length}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              _searchField(),
              const SizedBox(height: 22),

              // Raccourcis prépa
              _label('Préparer mon concours'),
              const SizedBox(height: 10),
              Row(children: [
                _shortcut(Icons.bolt_rounded, 'Préparation', () => context.push('/concours-prep')),
                const SizedBox(width: 9),
                _shortcut(Icons.description_outlined, 'Anciens sujets', () => context.go('/annales')),
                const SizedBox(width: 9),
                _shortcut(Icons.edit_note_rounded, 'Concours blanc', () => context.push('/concours-blanc')),
              ]),
              const SizedBox(height: 18),

              // Vedette — clôture proche (seul bloc « héros », masqué en recherche)
              if (!searching) ...[
                _FeaturedCard(featured),
                const SizedBox(height: 18),
              ],

              // Filtres de statut (réels)
              _statusChips(),
              const SizedBox(height: 16),

              _label(headerLabel),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OC.paper, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OC.line, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(Icons.search_off_rounded, size: 18, color: OC.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Aucun concours pour cette recherche.',
                        style: body(13, color: OC.muted, weight: FontWeight.w500))),
                  ]),
                )
              else
                for (var i = 0; i < list.length; i++)
                  Appear(index: i, child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ConcoursRow(list[i]),
                  )),

              const SizedBox(height: 8),
              _nativeAd(context),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String t) => Text(t, style: body(13, weight: FontWeight.w800, color: OC.ink2));

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OC.line2, width: 1.5),
        boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(Icons.search_rounded, size: 19, color: OC.muted),
        const SizedBox(width: 11),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            textInputAction: TextInputAction.search,
            style: body(14, color: OC.ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'École, filière, ville…',
              hintStyle: body(14, color: OC.muted, weight: FontWeight.w500),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        if (_query.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: OC.muted),
            ),
          ),
      ]),
    );
  }

  Widget _shortcut(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: OC.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OC.line, width: 1.5),
          ),
          child: Column(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 21, color: OC.o600),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11, weight: FontWeight.w700, color: OC.ink2)),
          ]),
        ),
      ),
    );
  }

  Widget _statusChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _CFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _CFilter.values[i];
          final on = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? OC.ink : OC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? OC.ink : OC.line2, width: 1.5),
              ),
              child: Text(f.label, style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
            ),
          );
        },
      ),
    );
  }

  Widget _nativeAd(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line2, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.account_balance_rounded, size: 20, color: OC.muted),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Institut Saint-Jean — Prépa', style: body(12, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Inscriptions ouvertes', style: body(10.5, color: OC.muted, weight: FontWeight.w500)),
        ])),
        _pill('Pub', OC.panel, OC.muted),
      ]),
    );
  }

}

Widget _pill(String t, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(t.toUpperCase(), style: body(8.5, weight: FontWeight.w800, color: fg).copyWith(letterSpacing: 0.04 * 8.5)),
    );

String _frShort(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);

// ─── Carte vedette (clôture proche) ──────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Concours c;
  const _FeaturedCard(this.c);

  @override
  Widget build(BuildContext context) {
    final dl = c.registrationDeadline;
    final days = dl == null ? null : dl.difference(DateTime.now()).inDays;
    final meta = [
      if (c.description != null && c.description!.isNotEmpty) c.description!,
      if (dl != null) 'clôture ${_frShort(dl)}',
    ].join(' · ');

    return GestureDetector(
      onTap: () => context.push('/concours-detail', extra: c),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [OC.darkHero, OC.darkHero2]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(7)),
              child: Text('CLÔTURE PROCHE', style: body(9, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.06 * 9)),
            ),
            const Spacer(),
            if (days != null && days >= 0)
              Text(days == 0 ? "Aujourd'hui" : 'J-$days', style: mono(13, weight: FontWeight.w700, color: const Color(0xFFFFB489))),
          ]),
          const SizedBox(height: 12),
          Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: display(19, weight: FontWeight.w700, color: Colors.white)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(12.5, color: Colors.white.withValues(alpha: 0.78), weight: FontWeight.w500)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Container(
              height: 42,
              decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Voir le concours', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              ]),
            )),
            const SizedBox(width: 10),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active_outlined, size: 18, color: Colors.white),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Ligne concours ──────────────────────────────────────────────────────────
class _ConcoursRow extends StatelessWidget {
  final Concours c;
  const _ConcoursRow(this.c);

  static final _avatarColors = [
    OC.o600, OC.blue, OC.good, Color(0xFF7A5AE0), Color(0xFF0E9AA0), Color(0xFFD2462E),
  ];
  Color get _accent => _avatarColors[c.name.hashCode.abs() % _avatarColors.length];

  /// Sigle de l'école si présent dans le nom (ENS, ENSP, FMSB, ENAM…), sinon
  /// les 2 premières lettres.
  String get _badge {
    final caps = RegExp(r'\b[A-Z]{2,6}\b').allMatches(c.name).map((m) => m.group(0)!).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (caps.isNotEmpty) return caps.first;
    final w = c.name.trim();
    return w.isEmpty ? 'C' : w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dl = c.registrationDeadline;
    final days = dl == null ? null : dl.difference(DateTime.now()).inDays;
    final open = days == null || days >= 0;
    final urgent = days != null && days >= 0 && days <= 7;
    final accent = _accent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/concours-detail', extra: c),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          // Avatar sigle coloré (identité de l'école)
          Container(
            width: 46, height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Text(_badge, style: display(_badge.length >= 4 ? 12 : 15, weight: FontWeight.w800, color: accent)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(c.organizer.isNotEmpty ? c.organizer : (c.description ?? ''),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
            if (dl != null) ...[
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.event_outlined, size: 12.5, color: urgent ? OC.bad : OC.muted),
                const SizedBox(width: 4),
                Text('Clôture ${_frShort(dl)}',
                    style: body(11, weight: FontWeight.w700, color: urgent ? OC.bad : OC.ink2)),
              ]),
            ],
          ])),
          const SizedBox(width: 8),
          // Statut / compte à rebours
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: !open ? OC.panel : (urgent ? OC.bad.withValues(alpha: 0.12) : OC.o50),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              days != null && days >= 0 ? (days == 0 ? "Auj." : 'J-$days') : (open ? 'Ouvert' : 'Clos'),
              style: mono(11.5, weight: FontWeight.w800, color: !open ? OC.muted : (urgent ? OC.bad : OC.o700)),
            ),
          ),
        ]),
      ),
    );
  }
}
