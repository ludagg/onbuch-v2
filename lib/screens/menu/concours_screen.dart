import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/calendar_event.dart';
import '../../services/database_service.dart';

class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  late final Future<List<CalendarEvent>> _future = DatabaseService().getCalendarEvents();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Concours'),
      body: FutureBuilder<List<CalendarEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: OC.o500));
          }
          final now = DateTime.now();
          final t0 = DateTime(now.year, now.month, now.day);
          final list = (snap.data ?? [])
              .where((e) => e.type == CalendarEventType.concours && !e.end.isBefore(t0))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('Les concours à venir', style: display(20, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Dates limites et épreuves, mises à jour par OnBuch.',
                  style: body(13, color: OC.ink2, weight: FontWeight.w500)),
              const SizedBox(height: 18),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                  child: Row(children: [
                    const Icon(Icons.event_busy_rounded, size: 18, color: OC.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Aucun concours annoncé pour le moment.', style: body(13, color: OC.muted, weight: FontWeight.w500))),
                  ]),
                )
              else
                ...list.map(_card),
            ],
          );
        },
      ),
    );
  }

  Widget _card(CalendarEvent e) {
    final days = e.start.difference(DateTime.now()).inDays;
    final c = CalendarEventType.concours.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.track_changes_rounded, size: 22, color: c)),
          const SizedBox(width: 12),
          Expanded(child: Text(e.title, style: body(15, weight: FontWeight.w700).copyWith(height: 1.2))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.event_rounded, size: 15, color: OC.muted),
          const SizedBox(width: 6),
          Text(DateFormat('d MMMM y', 'fr_FR').format(e.start), style: body(12.5, weight: FontWeight.w600, color: OC.ink2)),
          const Spacer(),
          if (days >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(days == 0 ? "Aujourd'hui" : 'J-$days', style: body(11.5, weight: FontWeight.w800, color: c)),
            ),
        ]),
        if (e.description != null) ...[
          const SizedBox(height: 10),
          Text(e.description!, style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
        ],
      ]),
    );
  }
}
