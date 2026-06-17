import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/concours.dart';
import '../../models/prep_center.dart';
import '../../models/concours_resource.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

const _teal = Color(0xFF0E9AA0);
const _tealBg = Color(0xFFE2F3F3);

/// Hub Concours : sessions en cours, centres de préparation et ressources.
class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  final _db = DatabaseService();
  late final Future<void> _future = _load();

  List<Concours> _concours = const [];
  List<PrepCenter> _centers = const [];
  List<ConcoursResource> _resources = const [];

  Future<void> _load() async {
    final res = await Future.wait([
      _db.getConcours(),
      _db.getPrepCenters(),
      _db.getConcoursResources(),
    ]);
    _concours = res[0] as List<Concours>;
    _centers = res[1] as List<PrepCenter>;
    _resources = res[2] as List<ConcoursResource>;
    if (_concours.isEmpty) _concours = _sampleConcours();
    if (_centers.isEmpty) _centers = _sampleCenters();
    if (_resources.isEmpty) _resources = _sampleResources();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Concours'),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _teal));
          }
          final open = _concours.where((c) {
            final n = c.nextDate;
            return n == null || !n.isBefore(DateTime.now());
          }).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 36),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _Hero(open: open, centers: _centers.length, resources: _resources.length),
              ),
              const SizedBox(height: 26),

              // ── Concours ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SecHead(eyebrow: 'Sessions en cours', title: 'Concours ouverts', action: null),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: _concours.map((c) => _ConcoursCard(c)).toList()),
              ),
              const SizedBox(height: 12),

              // ── Centres de préparation ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SecHead(eyebrow: 'Se préparer', title: 'Centres de préparation', action: null),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _centers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 13),
                  itemBuilder: (_, i) => _CenterCard(_centers[i]),
                ),
              ),
              const SizedBox(height: 26),

              // ── Ressources ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SecHead(eyebrow: 'Réviser malin', title: 'Ressources de prépa', action: null),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: _resources.map((r) => _ResourceRow(r)).toList()),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int open, centers, resources;
  const _Hero({required this.open, required this.centers, required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF11857F), Color(0xFF0A565A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(children: [
        Positioned(
          top: -70, right: -50,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0)]),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.military_tech_rounded, color: Color(0xFFBDEDEA), size: 17),
            const SizedBox(width: 7),
            Text('OBJECTIF CONCOURS',
                style: body(10.5, weight: FontWeight.w800, color: const Color(0xFFBDEDEA)).copyWith(letterSpacing: 0.1 * 10.5)),
          ]),
          const SizedBox(height: 10),
          Text('Tout pour réussir\ntes concours',
              style: display(23, weight: FontWeight.w700, color: Colors.white).copyWith(height: 1.12)),
          const SizedBox(height: 8),
          Text('Sessions ouvertes, centres de prépa et ressources — au même endroit.',
              style: body(12.5, color: Colors.white.withValues(alpha: 0.82), weight: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 16),
          Row(children: [
            _stat('$open', 'ouverts'),
            _sep(),
            _stat('$centers', 'centres'),
            _sep(),
            _stat('$resources', 'ressources'),
          ]),
        ]),
      ]),
    );
  }

  Widget _stat(String v, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: display(22, weight: FontWeight.w700, color: Colors.white)),
        Text(l, style: body(11, color: Colors.white.withValues(alpha: 0.75), weight: FontWeight.w600)),
      ]);

  Widget _sep() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.18),
      margin: const EdgeInsets.symmetric(horizontal: 18));
}

// ─── Carte concours ───────────────────────────────────────────────────────────
class _ConcoursCard extends StatelessWidget {
  final Concours c;
  const _ConcoursCard(this.c);

  @override
  Widget build(BuildContext context) {
    final next = c.nextDate;
    final days = next == null ? null : next.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line, width: 1.5),
        boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: _tealBg, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.track_changes_rounded, size: 23, color: _teal),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: body(15, weight: FontWeight.w700).copyWith(height: 1.2)),
            if (c.organizer.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(c.organizer, style: body(12, color: OC.muted, weight: FontWeight.w600)),
            ],
          ])),
          if (days != null && days >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _tealBg, borderRadius: BorderRadius.circular(999)),
              child: Text(days == 0 ? 'Auj.' : 'J-$days', style: body(11.5, weight: FontWeight.w800, color: _teal)),
            ),
        ]),
        if (c.description != null) ...[
          const SizedBox(height: 12),
          Text(c.description!, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        ],
        const SizedBox(height: 12),
        if (c.registrationDeadline != null)
          _dateRow(Icons.how_to_reg_rounded, 'Inscriptions jusqu\'au ${_fr(c.registrationDeadline!)}'),
        if (c.examDate != null) _dateRow(Icons.event_rounded, 'Épreuves : ${_fr(c.examDate!)}'),
        if (c.resultsAvailable) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(13)),
            child: Row(children: [
              const Icon(Icons.emoji_events_rounded, size: 20, color: OC.good),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Résultats disponibles', style: body(13, weight: FontWeight.w800, color: OC.waInk)),
                if (c.resultsDate != null)
                  Text('Publiés le ${_fr(c.resultsDate!)}', style: body(11.5, color: OC.waInk, weight: FontWeight.w500)),
              ])),
              if (c.resultsLink != null)
                GestureDetector(
                  onTap: () => openUrl(context, c.resultsLink),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: OC.good, borderRadius: BorderRadius.circular(10)),
                    child: Text('Voir', style: body(12.5, weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
            ]),
          ),
        ],
        if (c.communique != null || c.link != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            if (c.communique != null)
              Expanded(child: _btn(context, 'Communiqué', Icons.description_outlined, c.communique!, filled: false)),
            if (c.communique != null && c.link != null) const SizedBox(width: 10),
            if (c.link != null)
              Expanded(child: _btn(context, 'S\'inscrire', Icons.how_to_reg_rounded, c.link!, filled: true)),
          ]),
        ],
      ]),
    );
  }

  Widget _dateRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 15, color: OC.muted),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: body(12.5, weight: FontWeight.w600, color: OC.ink2))),
        ]),
      );

  Widget _btn(BuildContext context, String label, IconData icon, String url, {required bool filled}) {
    return GestureDetector(
      onTap: () => openUrl(context, url),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? _teal : OC.paper,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: OC.line2, width: 1.5),
          boxShadow: filled ? [BoxShadow(color: _teal.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 5))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: filled ? Colors.white : OC.ink2),
          const SizedBox(width: 7),
          Text(label, style: body(13, weight: FontWeight.w700, color: filled ? Colors.white : OC.ink2)),
        ]),
      ),
    );
  }
}

// ─── Carte centre de préparation ──────────────────────────────────────────────
class _CenterCard extends StatelessWidget {
  final PrepCenter c;
  const _CenterCard(this.c);

  @override
  Widget build(BuildContext context) {
    final specs = c.specialtyList.take(2).toList();
    return Container(
      width: 256,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Bandeau image / dégradé
        Stack(children: [
          SizedBox(
            height: 84, width: double.infinity,
            child: (c.imageUrl != null)
                ? Image.network(c.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _banner(), loadingBuilder: (_, ch, p) => p == null ? ch : _banner())
                : _banner(),
          ),
          if (c.eventDate != null)
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.event_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(_fr(c.eventDate!), style: body(10, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14.5, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 13, color: _teal),
              const SizedBox(width: 3),
              Expanded(child: Text(c.city, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.muted, weight: FontWeight.w600))),
            ]),
            if (c.eventTitle != null) ...[
              const SizedBox(height: 7),
              Text(c.eventTitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
            ],
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(spacing: 6, runSpacing: 6, children: specs.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _tealBg, borderRadius: BorderRadius.circular(7)),
                child: Text(s, style: body(10, weight: FontWeight.w700, color: _teal)),
              )).toList()),
            ],
            const SizedBox(height: 11),
            GestureDetector(
              onTap: () {
                if (c.phone != null) {
                  openUrl(context, 'https://wa.me/${c.phone!.replaceAll(RegExp(r'[^0-9]'), '')}');
                } else if (c.link != null) {
                  openUrl(context, c.link);
                }
              },
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: c.phone != null ? OC.wa : _teal,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(c.phone != null ? Icons.chat_rounded : Icons.open_in_new_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 7),
                  Text(c.phone != null ? 'Contacter' : 'En savoir plus',
                      style: body(12.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _banner() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF13908A), Color(0xFF0C6065)]),
        ),
        child: const Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 30)),
      );
}

// ─── Ligne ressource ──────────────────────────────────────────────────────────
class _ResourceRow extends StatelessWidget {
  final ConcoursResource r;
  const _ResourceRow(this.r);

  ({IconData icon, Color color, Color bg, String label}) get _style {
    switch (r.type) {
      case 'annales':
        return (icon: Icons.menu_book_rounded, color: _teal, bg: _tealBg, label: 'Annales');
      case 'video':
        return (icon: Icons.play_circle_fill_rounded, color: const Color(0xFFC0392B), bg: const Color(0xFFFAE7E4), label: 'Vidéo');
      case 'fiche':
        return (icon: Icons.sticky_note_2_rounded, color: OC.warn, bg: OC.warnBg, label: 'Fiche');
      case 'site':
        return (icon: Icons.public_rounded, color: OC.blue, bg: OC.blueBg, label: 'Site');
      default:
        return (icon: Icons.description_rounded, color: OC.blue, bg: OC.blueBg, label: 'Guide');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => r.url != null ? openUrl(context, r.url) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(s.icon, size: 22, color: s.color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(6)),
                child: Text(s.label.toUpperCase(), style: body(8.5, weight: FontWeight.w800, color: s.color)),
              ),
              if (r.concours != null) ...[
                const SizedBox(width: 6),
                Flexible(child: Text(r.concours!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(10.5, color: OC.muted, weight: FontWeight.w600))),
              ],
            ]),
            const SizedBox(height: 5),
            Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.25)),
            if (r.description != null) ...[
              const SizedBox(height: 2),
              Text(r.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
            ],
          ])),
          const SizedBox(width: 8),
          Icon(r.url != null ? Icons.chevron_right_rounded : Icons.lock_outline_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}

String _fr(DateTime d) => DateFormat('d MMM y', 'fr_FR').format(d);

// ─── Contenus d'exemple (tant que l'admin n'a rien publié) ───────────────────
List<Concours> _sampleConcours() {
  final now = DateTime.now();
  return [
    Concours(
      id: 's1', name: 'Concours ENS Yaoundé', organizer: 'MINESUP · École Normale Supérieure',
      description: 'Entrée en 1re année (cycles DIPES I & II), toutes filières.',
      registrationDeadline: now.add(const Duration(days: 21)),
      examDate: now.add(const Duration(days: 60)),
    ),
    Concours(
      id: 's2', name: 'Concours ENAM', organizer: 'École Nationale d\'Administration et de Magistrature',
      description: 'Cycle A & B — administration générale, douanes, magistrature.',
      registrationDeadline: now.add(const Duration(days: 9)),
      examDate: now.add(const Duration(days: 45)),
    ),
    Concours(
      id: 's3', name: 'Concours Police nationale', organizer: 'DGSN',
      description: 'Recrutement d\'élèves gardiens de la paix et inspecteurs.',
      examDate: now.subtract(const Duration(days: 15)),
      resultsAvailable: true, resultsDate: now.subtract(const Duration(days: 2)),
    ),
  ];
}

List<PrepCenter> _sampleCenters() {
  final now = DateTime.now();
  return [
    PrepCenter(
      id: 'c1', name: 'Prépa Excellence', city: 'Yaoundé',
      specialties: 'ENS, ENSP, Polytechnique',
      eventTitle: 'Concours blanc ENS', eventDate: now.add(const Duration(days: 12)),
    ),
    PrepCenter(
      id: 'c2', name: 'Institut Réussite', city: 'Douala',
      specialties: 'ENAM, IRIC, Douanes',
      eventTitle: 'Portes ouvertes', eventDate: now.add(const Duration(days: 5)),
    ),
    PrepCenter(
      id: 'c3', name: 'Centre Avenir', city: 'Bafoussam',
      specialties: 'Médecine, FASA',
    ),
  ];
}

List<ConcoursResource> _sampleResources() => const [
      ConcoursResource(id: 'r1', title: 'Annales ENS 2018–2024 (corrigées)', type: 'annales', concours: 'ENS', description: 'Épreuves des 6 dernières sessions'),
      ConcoursResource(id: 'r2', title: 'Guide complet : réussir l\'ENAM', type: 'guide', concours: 'ENAM', description: 'Méthodo, programme, conseils'),
      ConcoursResource(id: 'r3', title: 'Culture générale — l\'essentiel en vidéo', type: 'video', description: 'Playlist de révision express'),
      ConcoursResource(id: 'r4', title: 'Fiches de maths pour Polytechnique', type: 'fiche', concours: 'ENSP', description: 'Formules & théorèmes clés'),
    ];
