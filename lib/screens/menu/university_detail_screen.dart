import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/cached_image.dart';
import '../../models/university.dart';
import '../../utils/launch.dart';

/// Fiche détaillée d'une université : logo, identité (ville/région/type), grandes
/// écoles & facultés, cursus/filières offerts, domaines, et lien officiel.
class UniversityDetailScreen extends StatelessWidget {
  final University? university;
  const UniversityDetailScreen({super.key, this.university});

  @override
  Widget build(BuildContext context) {
    final u = university;
    if (u == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'Université'),
        body: Center(child: Text('Université introuvable.', style: body(14, color: OC.muted))),
      );
    }
    final accent = u.accent;
    final metaLine = [u.city, u.region, u.type, if (u.founded > 0) 'depuis ${u.founded}']
        .where((e) => e.trim().isNotEmpty)
        .join(' · ');

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, u.acronym.isEmpty ? 'Université' : u.acronym),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── En-tête : logo + nom + classement ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OC.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OC.line, width: 1.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _UniversityLogo(u, size: 64),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (u.rank > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(7)),
                    child: Text('Classée #${u.rank}', style: mono(11, weight: FontWeight.w800, color: OC.o700)),
                  ),
                if (u.rank > 0) const SizedBox(height: 7),
                Text(u.name, style: display(18, weight: FontWeight.w800).copyWith(height: 1.15)),
                if (metaLine.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(metaLine, style: body(12, color: OC.muted, weight: FontWeight.w600)),
                ],
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          if (u.description.isNotEmpty) ...[
            Text(u.description, style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5)),
            const SizedBox(height: 18),
          ],

          // ── Fiche pratique (frais, admission, places…) ──
          ..._practical(u, accent),

          // ── Domaines ──
          if (u.fields.isNotEmpty) ...[
            _sectionTitle('Domaines'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in u.fields)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(f, style: body(11.5, color: accent, weight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 18),
          ],

          // ── Grandes écoles & facultés ──
          if (u.schools.isNotEmpty) ...[
            _sectionTitle('Grandes écoles & facultés'),
            const SizedBox(height: 10),
            for (final s in u.schools)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.account_balance_rounded, size: 17, color: OC.o600),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(s, style: body(13, weight: FontWeight.w600, color: OC.ink)),
                  )),
                ]),
              ),
            const SizedBox(height: 9),
          ],

          // ── Cursus / filières ──
          if (u.programs.isNotEmpty) ...[
            _sectionTitle('Cursus & filières'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in u.programs)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: OC.panel,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school_rounded, size: 13, color: OC.muted),
                    const SizedBox(width: 6),
                    Text(p, style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
                  ]),
                ),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Lien officiel ──
          if (u.website.isNotEmpty)
            GestureDetector(
              onTap: () => openUrl(context, u.website),
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.language_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Site officiel', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: body(13, weight: FontWeight.w800, color: OC.ink2));

  // ── Fiche pratique de l'école (chaque bloc ne s'affiche que si renseigné) ──
  List<Widget> _practical(University u, Color accent) {
    if (!u.hasDetails) return const [];
    final stats = <Widget>[
      if (u.tuition.isNotEmpty) _statTile(Icons.payments_rounded, u.tuition, 'Frais de scolarité', accent),
      if (u.places.isNotEmpty) _statTile(Icons.event_seat_rounded, u.places, 'Places', accent),
      if (u.successRate.isNotEmpty) _statTile(Icons.trending_up_rounded, u.successRate, 'Taux de réussite', accent),
    ];
    return [
      _sectionTitle('Infos pratiques'),
      const SizedBox(height: 10),
      if (stats.isNotEmpty) ...[
        Wrap(spacing: 10, runSpacing: 10, children: stats),
        const SizedBox(height: 12),
      ],
      if (u.admission.isNotEmpty) _kvCard(Icons.checklist_rounded, 'Conditions d\'admission', u.admission, accent),
      if (u.registrationDates.isNotEmpty) _kvCard(Icons.event_rounded, 'Dates des inscriptions', u.registrationDates, accent),
      if (u.documents.isNotEmpty) _chipsCard(Icons.description_rounded, 'Pièces à fournir', u.documents, accent),
      if (u.accreditation.isNotEmpty) _kvCard(Icons.verified_rounded, 'Accréditation', u.accreditation, accent),
      if (u.campuses.isNotEmpty) _chipsCard(Icons.location_city_rounded, 'Campus disponibles', u.campuses, accent),
      if (u.residences.isNotEmpty) _kvCard(Icons.bed_rounded, 'Résidences universitaires', u.residences, accent),
      const SizedBox(height: 10),
    ];
  }

  Widget _statTile(IconData ic, String value, String label, Color accent) => Container(
        width: 104,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ic, size: 18, color: accent),
          const SizedBox(height: 8),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13, weight: FontWeight.w800).copyWith(height: 1.15)),
          const SizedBox(height: 2),
          Text(label, style: body(10, color: OC.muted, weight: FontWeight.w600)),
        ]),
      );

  Widget _kvCard(IconData ic, String title, String value, Color accent) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ic, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(title, style: body(12.5, weight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        ]),
      );

  Widget _chipsCard(IconData ic, String title, List<String> items, Color accent) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ic, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(title, style: body(12.5, weight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final it in items)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(9)),
                child: Text(it, style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
              ),
          ]),
        ]),
      );
}

/// Logo de l'université : image réseau si disponible, sinon pastille au sigle.
class _UniversityLogo extends StatelessWidget {
  final University u;
  final double size;
  const _UniversityLogo(this.u, {this.size = 56});

  @override
  Widget build(BuildContext context) {
    final accent = u.accent;
    final fallback = Container(
      width: size, height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Text(u.acronym.isEmpty ? '?' : u.acronym,
          style: display(u.acronym.length >= 4 ? 13 : 17, weight: FontWeight.w800, color: accent)),
    );
    if (!u.hasLogo) return fallback;
    return Container(
      width: size, height: size,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: CachedImage(
          u.logoUrl,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Center(child: Text(u.acronym.isEmpty ? '?' : u.acronym,
              style: display(u.acronym.length >= 4 ? 12 : 15, weight: FontWeight.w800, color: accent))),
        ),
      ),
    );
  }
}
