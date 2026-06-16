import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/concours.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  late final Future<List<Concours>> _future = DatabaseService().getConcours();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Concours'),
      body: FutureBuilder<List<Concours>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: OC.o500));
          }
          final all = snap.data ?? const <Concours>[];
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.track_changes_rounded, size: 46, color: OC.faint),
                  const SizedBox(height: 12),
                  Text('Aucun concours pour le moment', style: display(18, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Les concours annoncés par OnBuch apparaîtront ici.',
                      textAlign: TextAlign.center, style: body(13.5, color: OC.muted).copyWith(height: 1.4)),
                ]),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Text('Concours & grandes écoles', style: display(20, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Dates, communiqués et résultats, mis à jour par OnBuch.',
                  style: body(13, color: OC.ink2, weight: FontWeight.w500)),
              const SizedBox(height: 18),
              ...all.map((c) => _ConcoursCard(c)),
            ],
          );
        },
      ),
    );
  }
}

class _ConcoursCard extends StatelessWidget {
  final Concours c;
  const _ConcoursCard(this.c);

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0E9AA0);
    final next = c.nextDate;
    final days = next == null ? null : next.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.track_changes_rounded, size: 23, color: accent),
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
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(days == 0 ? "Auj." : 'J-$days', style: body(11.5, weight: FontWeight.w800, color: accent)),
            ),
        ]),

        if (c.description != null) ...[
          const SizedBox(height: 12),
          Text(c.description!, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        ],

        const SizedBox(height: 12),
        if (c.registrationDeadline != null)
          _dateRow(Icons.how_to_reg_rounded, 'Inscriptions jusqu\'au ${_fr(c.registrationDeadline!)}'),
        if (c.examDate != null)
          _dateRow(Icons.event_rounded, 'Épreuves : ${_fr(c.examDate!)}'),

        // Résultats
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

        // Actions
        if (c.communique != null || c.link != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            if (c.communique != null)
              Expanded(child: _btn(context, 'Communiqué', Icons.description_outlined, c.communique!, filled: false)),
            if (c.communique != null && c.link != null) const SizedBox(width: 10),
            if (c.link != null)
              Expanded(child: _btn(context, 'S\'inscrire', Icons.open_in_new_rounded, c.link!, filled: true)),
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
          gradient: filled ? OC.grad : null,
          color: filled ? null : OC.paper,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: OC.line2, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: filled ? Colors.white : OC.ink2),
          const SizedBox(width: 7),
          Text(label, style: body(13, weight: FontWeight.w700, color: filled ? Colors.white : OC.ink2)),
        ]),
      ),
    );
  }

  String _fr(DateTime d) => DateFormat('d MMMM y', 'fr_FR').format(d);
}
