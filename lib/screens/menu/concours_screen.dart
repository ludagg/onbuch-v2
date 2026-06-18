import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/concours.dart';
import '../../services/database_service.dart';

/// Catalogue Concours (section A des wireframes) : recherche, raccourcis prépa,
/// emplacements partenaires, concours dont la clôture approche, et liste.
class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  final _db = DatabaseService();
  late final Future<List<Concours>> _future = _load();
  int _cat = 0;

  Future<List<Concours>> _load() async {
    final list = await _db.getConcours();
    return list.isEmpty ? _sample() : list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Concours', style: display(17, weight: FontWeight.w700)),
          Text('Grandes écoles & admissions', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            color: OC.ink,
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<List<Concours>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: OC.o500));
          }
          final all = snap.data ?? const <Concours>[];
          // Clôture la plus proche → carte vedette.
          final upcoming = all.where((c) => c.registrationDeadline != null &&
              c.registrationDeadline!.isAfter(DateTime.now())).toList()
            ..sort((a, b) => a.registrationDeadline!.compareTo(b.registrationDeadline!));
          final featured = upcoming.isNotEmpty ? upcoming.first : (all.isNotEmpty ? all.first : null);
          final rest = all.where((c) => c.id != featured?.id).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              _searchBar(),
              const SizedBox(height: 22),

              // Raccourcis prépa
              _label('Préparer mon concours'),
              const SizedBox(height: 10),
              Row(children: [
                _shortcut(Icons.bolt_rounded, 'Préparation', () => context.go('/cours')),
                const SizedBox(width: 9),
                _shortcut(Icons.description_outlined, 'Anciens sujets', () => context.go('/annales')),
                const SizedBox(width: 9),
                _shortcut(Icons.edit_note_rounded, 'Concours blanc', () => _soon(context)),
              ]),
              const SizedBox(height: 18),

              // Emplacement partenaire (sponsorisé)
              _sponsoredBanner(context),
              const SizedBox(height: 16),

              // Vedette — clôture proche
              if (featured != null) ...[
                _FeaturedCard(featured),
                const SizedBox(height: 18),
              ],

              // Filtres rapides
              _categoryChips(),
              const SizedBox(height: 16),

              _label('Concours ouverts · ${all.length}'),
              const SizedBox(height: 12),
              ...rest.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ConcoursRow(c),
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

  Widget _searchBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _soon(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: OC.line2, width: 1.5),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, size: 19, color: OC.muted),
          const SizedBox(width: 11),
          Text('École, filière, ville…', style: body(14, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ),
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

  Widget _sponsoredBanner(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OC.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(children: [
        Container(
          height: 78,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF2A1E12), Color(0xFF7A4A1E)]),
          ),
          child: Center(child: Text('Prépa ENS · Stages intensifs',
              style: display(15, weight: FontWeight.w700, color: Colors.white))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          child: Row(children: [
            _pill('Sponsorisé', OC.o50, OC.o700),
            const SizedBox(width: 8),
            Expanded(child: Text('Réussis ton concours avec un accompagnement dédié.',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11, color: OC.ink2, weight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
          ]),
        ),
      ]),
    );
  }

  Widget _categoryChips() {
    const cats = ['Tous', 'Sciences', 'Santé', 'Éducation', 'Éco/Gestion'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == _cat;
          return GestureDetector(
            onTap: () => setState(() => _cat = i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? OC.ink : OC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? OC.ink : OC.line2, width: 1.5),
              ),
              child: Text(cats[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
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
          child: const Icon(Icons.account_balance_rounded, size: 20, color: OC.muted),
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

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bientôt disponible', style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  static List<Concours> _sample() {
    final now = DateTime.now();
    return [
      Concours(id: 's1', name: 'Concours ENS Yaoundé', organizer: 'MINESUP · École Normale Supérieure',
          description: 'Cycle 1 · 1 200 places', registrationDeadline: now.add(const Duration(days: 14)),
          examDate: now.add(const Duration(days: 48))),
      Concours(id: 's2', name: 'Polytechnique (ENSP)', organizer: 'Génie · Yaoundé',
          description: '850 places', registrationDeadline: now.add(const Duration(days: 30))),
      Concours(id: 's3', name: 'FMSB — Médecine', organizer: 'Médecine · Yaoundé I',
          description: 'Faculté de Médecine', registrationDeadline: now.add(const Duration(days: 5))),
      Concours(id: 's4', name: 'ENAM', organizer: 'Administration & Magistrature',
          description: 'Cycle A & B', examDate: now.add(const Duration(days: 70))),
    ];
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

  @override
  Widget build(BuildContext context) {
    final dl = c.registrationDeadline;
    final days = dl == null ? null : dl.difference(DateTime.now()).inDays;
    final open = days == null || days >= 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/concours-detail', extra: c),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.account_balance_outlined, size: 21, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(c.organizer.isNotEmpty ? c.organizer : (c.description ?? ''),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          const SizedBox(width: 8),
          _pill(
            days != null && days >= 0 && days <= 9 ? 'J-$days' : (open ? 'Ouvert' : 'Clos'),
            open ? OC.o50 : OC.panel,
            open ? OC.o700 : OC.muted,
          ),
        ]),
      ),
    );
  }
}
