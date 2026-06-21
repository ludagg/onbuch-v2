import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/concours.dart';
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
  static const _tabs = ['Aperçu', 'Dates', 'Conditions', 'Épreuves', 'Débouchés'];

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
        return _conditionsTab();
      case 3:
        return _epreuvesTab();
      case 4:
        return _deboucheTab();
      default:
        return _apercuTab();
    }
  }

  // ── Aperçu ──
  Widget _apercuTab() {
    final about = (c.description != null && c.description!.trim().isNotEmpty)
        ? c.description!.trim()
        : 'Ce concours ouvre l\'accès à une formation sélective. Consulte les onglets Dates, Conditions et Épreuves pour préparer ta candidature.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h('À propos'),
      const SizedBox(height: 8),
      Text(about, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5)),
      if (c.audience != null) ...[
        const SizedBox(height: 16),
        _h('Public visé'),
        const SizedBox(height: 8),
        Text(c.audience!, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
      ],
      const SizedBox(height: 18),
      if (c.communique != null)
        _linkRow(context, Icons.description_outlined, 'Communiqué officiel', c.communique!),
    ]);
  }

  // ── Dates ──
  Widget _datesTab() {
    final steps = <(String, DateTime?, bool)>[
      ('Ouverture des inscriptions', null, true),
      ('Clôture des dossiers', c.registrationDeadline, false),
      ('Épreuves écrites', c.examDate, false),
      ('Résultats', c.resultsDate, false),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < steps.length; i++)
        _timelineRow(steps[i].$1, steps[i].$2, i == steps.length - 1, isNow: steps[i].$1.startsWith('Clôture')),
      const SizedBox(height: 8),
      _note('Calendrier indicatif — les dates officielles font foi.'),
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

  // ── Conditions ──
  Widget _conditionsTab() {
    const criteria = [
      'Être titulaire du diplôme requis (ou en cours)',
      'Respecter la limite d\'âge fixée par le règlement',
      'Série / filière compatible avec le concours',
      'Dossier complet déposé avant la clôture',
    ];
    const docs = ['Acte de naissance', 'Relevé de notes', 'Photos d\'identité', 'Reçu de paiement'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h('Critères d\'éligibilité'),
      const SizedBox(height: 10),
      ...criteria.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_rounded, size: 17, color: OC.o500),
              const SizedBox(width: 9),
              Expanded(child: Text(t, style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.35))),
            ]),
          )),
      const SizedBox(height: 12),
      _h('Pièces à fournir'),
      const SizedBox(height: 10),
      ...docs.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.insert_drive_file_outlined, size: 15, color: OC.muted),
              const SizedBox(width: 9),
              Text(t, style: body(12.5, color: OC.ink2, weight: FontWeight.w500)),
            ]),
          )),
      const SizedBox(height: 6),
      _note('Indicatif — vérifie le communiqué officiel du concours.'),
    ]);
  }

  // ── Épreuves ──
  Widget _epreuvesTab() {
    const epreuves = [
      ('Culture générale', 'coef 2'),
      ('Épreuve de spécialité', 'coef 4'),
      ('Logique / raisonnement', 'coef 2'),
      ('Entretien / oral', 'coef 1'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h('Épreuves'),
      const SizedBox(height: 10),
      ...epreuves.map((ep) => Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13),
                border: Border.all(color: OC.line, width: 1.5)),
            child: Row(children: [
              Expanded(child: Text(ep.$1, style: body(13, weight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(7)),
                child: Text(ep.$2, style: body(10.5, weight: FontWeight.w700, color: OC.ink2)),
              ),
            ]),
          )),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: const Text('Préparer ces épreuves', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () => context.push('/concours-prep', extra: c),
        ),
      ),
      const SizedBox(height: 8),
      _note('Format indicatif — adapte selon le concours visé.'),
    ]);
  }

  // ── Débouchés ──
  Widget _deboucheTab() {
    const bars = [40, 55, 35, 60, 48, 70];
    const filieres = ['Filières d\'excellence', 'Emplois qualifiés', 'Poursuite d\'études', 'Réseau d\'alumni'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h('Tendance des admissions'),
      const SizedBox(height: 12),
      Container(
        height: 96,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < bars.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: Container(
              height: bars[i].toDouble(),
              decoration: BoxDecoration(
                color: i == bars.length - 1 ? OC.o500 : OC.line2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            )),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      _h('Débouchés'),
      const SizedBox(height: 10),
      ...filieres.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.school_outlined, size: 15, color: OC.o600),
              const SizedBox(width: 9),
              Text(t, style: body(12.5, color: OC.ink2, weight: FontWeight.w500)),
            ]),
          )),
      const SizedBox(height: 6),
      _note('Données illustratives — à compléter par concours.'),
    ]);
  }

  // ── Bottom CTA ──
  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: BoxDecoration(
          color: OC.paper,
          border: Border(top: BorderSide(color: OC.line, width: 1.5)),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13),
                border: Border.all(color: OC.line2, width: 1.5)),
            child: Icon(Icons.bookmark_border_rounded, size: 22, color: OC.ink2),
          ),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => context.push('/concours-inscription', extra: c),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: OC.grad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text('Vérifier mon éligibilité',
                    style: body(14, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          )),
        ]),
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
