import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/concours.dart';
import '../../data/orientation_guide.dart';
import '../../utils/launch.dart';

/// Fiche concours (section B des wireframes) : bannière, infos clés et onglets
/// Aperçu · Dates · Conditions · Épreuves · Débouchés.
class ConcoursDetailScreen extends StatefulWidget {
  final Concours? concours;
  const ConcoursDetailScreen({super.key, this.concours});

  @override
  State<ConcoursDetailScreen> createState() => _ConcoursDetailScreenState();
}

class _ConcoursDetailScreenState extends State<ConcoursDetailScreen> {
  int _tab = 0;
  static const _tabs = ['Aperçu', 'Dates', 'Débouchés'];

  Concours get c => widget.concours ?? const Concours(id: '-', name: 'Concours', organizer: '');

  @override
  Widget build(BuildContext context) {
    final dl = c.registrationDeadline;
    final days = dl == null ? null : dl.difference(DateTime.now()).inDays;
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: OC.bg,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          expandedHeight: 150,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/concours'),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [OC.darkHero, OC.darkHero2]),
              ),
              child: const Align(
                alignment: Alignment.center,
                child: Icon(Icons.account_balance_rounded, size: 46, color: Colors.white24),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: display(22, weight: FontWeight.w700)),
              if (c.organizer.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(c.organizer, style: body(13, color: OC.ink2, weight: FontWeight.w500)),
              ],
              if (dl != null && days != null && days >= 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
                  child: Text('Clôture ${_fr(dl)} · J-$days',
                      style: body(12, weight: FontWeight.w800, color: OC.o700)),
                ),
              ],
              const SizedBox(height: 16),
              _stats(),
              const SizedBox(height: 18),
              _tabBar(),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: _tabContent(),
          ),
        ),
      ]),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  Widget _stats() {
    final items = [
      ('Inscriptions', c.registrationDeadline == null ? '—' : _frShort(c.registrationDeadline!)),
      ('Épreuves', c.examDate == null ? '—' : _frShort(c.examDate!)),
      ('Résultats', c.resultsDate == null ? '—' : _frShort(c.resultsDate!)),
    ];
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(items[i].$2, style: display(15, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(items[i].$1, style: body(10, color: OC.muted, weight: FontWeight.w600)),
          ]),
        )),
      ],
    ]);
  }

  Widget _tabBar() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == _tab;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? OC.o500 : OC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
              ),
              child: Text(_tabs[i], style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
            ),
          );
        },
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 1:
        return _datesTab();
      case 2:
        return _debouchesTab();
      default:
        return _apercuTab();
    }
  }

  // ── Débouchés : ce que ce concours permet de devenir ──
  Widget _debouchesTab() {
    final admin = (c.debouches ?? '').trim();
    // Lignes saisies par l'admin (séparées par retour à la ligne, « ; » ou « • »).
    final adminItems = admin
        .split(RegExp(r'[\n;•]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final field = matchOrientation(c.name);

    if (adminItems.isEmpty && field == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Les débouchés de ce concours seront bientôt précisés. En attendant, '
          'consulte le guide d\'orientation pour comprendre les grandes filières.',
          style: body(13, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        _guideButton(),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (adminItems.isNotEmpty) ...[
        _h('Métiers & débouchés'),
        const SizedBox(height: 10),
        for (final d in adminItems) _bullet(d, OC.o600),
        const SizedBox(height: 16),
      ],
      if (field != null) ...[
        _h(adminItems.isEmpty ? 'Métiers & débouchés' : 'Filière : ${field.title}'),
        const SizedBox(height: 6),
        Text(field.tagline, style: body(12.5, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.4)),
        const SizedBox(height: 10),
        if (adminItems.isEmpty)
          for (final d in field.debouches) _bullet(d, field.accent),
        if (field.schools.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('ÉCOLES & EXEMPLES',
              style: body(10.5, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 0.06 * 10.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final s in field.schools)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(9)),
                child: Text(s, style: body(11, color: OC.ink2, weight: FontWeight.w600)),
              ),
          ]),
        ],
        const SizedBox(height: 16),
      ],
      _guideButton(),
    ]);
  }

  Widget _bullet(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle_rounded, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text,
              style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45))),
        ]),
      );

  Widget _guideButton() => GestureDetector(
        onTap: () => context.push('/orientation-guide'),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: OC.o50, borderRadius: BorderRadius.circular(13),
            border: Border.all(color: OC.o100, width: 1.5),
          ),
          child: Row(children: [
            Icon(Icons.explore_rounded, size: 18, color: OC.o600),
            const SizedBox(width: 11),
            Expanded(child: Text('Voir le guide d\'orientation complet',
                style: body(13, weight: FontWeight.w700, color: OC.o700))),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: OC.o600),
          ]),
        ),
      );

  // ── Aperçu (données réelles) ──
  Widget _apercuTab() {
    final hasAbout = c.description != null && c.description!.trim().isNotEmpty;
    final links = <Widget>[];
    if ((c.link ?? '').trim().isNotEmpty) {
      links.add(_linkRow(context, Icons.public_rounded, 'Site officiel / infos', c.link!.trim()));
    }
    if (c.resultsAvailable && (c.resultsLink ?? '').trim().isNotEmpty) {
      links.add(_linkRow(context, Icons.workspace_premium_outlined, 'Résultats', c.resultsLink!.trim()));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hasAbout) ...[
        _h('À propos'),
        const SizedBox(height: 8),
        Text(c.description!.trim(), style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5)),
        const SizedBox(height: 16),
      ],
      if (c.audience != null) ...[
        _h('Public visé'),
        const SizedBox(height: 8),
        Text(c.audience!, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        const SizedBox(height: 16),
      ],
      if (links.isNotEmpty) ...[
        _h('Liens officiels'),
        const SizedBox(height: 10),
        for (final w in links) Padding(padding: const EdgeInsets.only(bottom: 9), child: w),
      ],
      if (!hasAbout && c.audience == null && links.isEmpty)
        Text('Consulte les dates clés et le communiqué officiel pour les détails de ce concours.',
            style: body(13, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.5)),
    ]);
  }

  // ── Dates (données réelles) ──
  Widget _datesTab() {
    final steps = <(String, DateTime?)>[
      ('Clôture des inscriptions', c.registrationDeadline),
      ('Épreuves écrites', c.examDate),
      ('Résultats', c.resultsDate),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < steps.length; i++)
        _timelineRow(steps[i].$1, steps[i].$2, i == steps.length - 1,
            isNow: i == 0 && c.registrationDeadline != null),
      const SizedBox(height: 8),
      _note('Dates officielles — vérifie le communiqué pour toute mise à jour.'),
    ]);
  }

  Widget _timelineRow(String title, DateTime? date, bool last, {bool isNow = false}) {
    final color = isNow ? OC.o500 : OC.line2;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 11, height: 11, margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: isNow ? OC.o500 : OC.paper, shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2))),
          if (!last) Expanded(child: Container(width: 2, color: OC.line2, margin: const EdgeInsets.symmetric(vertical: 2))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: body(13, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(date == null ? 'À confirmer' : _fr(date),
                style: body(12, color: isNow ? OC.o600 : OC.muted, weight: FontWeight.w600)),
          ]),
        )),
      ]),
    );
  }

  // ── Bas de page : lien vers le communiqué officiel (affichage seulement —
  // l'app ne gère ni la préparation ni les inscriptions). Masqué sans lien.
  Widget _bottomBar(BuildContext context) {
    final link = (c.communique ?? '').trim();
    if (link.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: BoxDecoration(
          color: OC.paper,
          border: Border(top: BorderSide(color: OC.line, width: 1.5)),
        ),
        child: GestureDetector(
          onTap: () => openUrl(context, link),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('Communiqué officiel', style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──
  Widget _h(String t) => Text(t, style: body(13.5, weight: FontWeight.w800, color: OC.ink));

  Widget _note(String t) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 15, color: OC.o600),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: body(11.5, color: OC.o700, weight: FontWeight.w600).copyWith(height: 1.35))),
        ]),
      );

  Widget _linkRow(BuildContext context, IconData icon, String label, String url) => GestureDetector(
        onTap: () => openUrl(context, url),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: OC.line, width: 1.5)),
          child: Row(children: [
            Icon(icon, size: 18, color: OC.o600),
            const SizedBox(width: 11),
            Expanded(child: Text(label, style: body(13, weight: FontWeight.w700))),
            Icon(Icons.open_in_new_rounded, size: 16, color: OC.muted),
          ]),
        ),
      );
}

String _fr(DateTime d) => DateFormat('d MMMM y', 'fr_FR').format(d);
String _frShort(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);
