import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/calendar_event.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

/// Liste complète des évènements du calendrier scolaire (agenda), groupés par
/// mois, avec filtre par type. Complète la vue calendrier du Campus.
class SchoolEventsScreen extends StatefulWidget {
  const SchoolEventsScreen({super.key});

  @override
  State<SchoolEventsScreen> createState() => _SchoolEventsScreenState();
}

class _SchoolEventsScreenState extends State<SchoolEventsScreen> {
  final _db = DatabaseService();
  List<CalendarEvent> _events = [];
  bool _loading = true;
  CalendarEventType? _filter; // null = tous

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await _db.getCalendarEvents();
      e.sort((a, b) => a.start.compareTo(b.start));
      if (mounted) setState(() { _events = e; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CalendarEventType> get _typesPresent {
    final seen = <CalendarEventType>[];
    for (final e in _events) {
      if (!seen.contains(e.type)) seen.add(e.type);
    }
    return seen;
  }

  List<CalendarEvent> get _filtered =>
      _filter == null ? _events : _events.where((e) => e.type == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Agenda'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : RefreshIndicator(
              color: OC.o500,
              onRefresh: () async {
                DatabaseService.clearCache();
                await _load();
              },
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _filters()),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.event_busy_rounded, size: 42, color: OC.muted),
                          const SizedBox(height: 12),
                          Text('Aucun évènement', style: display(18, weight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Reviens bientôt : l\'agenda se remplit au fil de l\'année.',
                              textAlign: TextAlign.center, style: body(13.5, color: OC.muted).copyWith(height: 1.4)),
                        ]),
                      ),
                    ),
                  )
                else
                  SliverList.list(children: _buildGrouped(list)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ]),
            ),
    );
  }

  Widget _filters() {
    final types = _typesPresent;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _chip('Tous', _filter == null, () => setState(() => _filter = null), OC.ink),
          for (final t in types) ...[
            const SizedBox(width: 8),
            _chip(t.label, _filter == t, () => setState(() => _filter = t), t.color),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap, Color accent) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: on ? accent.withValues(alpha: 0.12) : OC.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? accent : OC.line2, width: 1.5),
          ),
          child: Text(label, style: body(12.5, weight: FontWeight.w700, color: on ? accent : OC.ink2)),
        ),
      );

  List<Widget> _buildGrouped(List<CalendarEvent> list) {
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final out = <Widget>[];
    String? currentMonth;
    for (final e in list) {
      final monthKey = DateFormat('MMMM y', 'fr_FR').format(e.start);
      if (monthKey != currentMonth) {
        currentMonth = monthKey;
        out.add(Padding(
          padding: EdgeInsets.fromLTRB(20, out.isEmpty ? 6 : 18, 20, 8),
          child: Text(_cap(monthKey), style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        ));
      }
      final past = e.end.isBefore(t0);
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
        child: _eventTile(e, past),
      ));
    }
    return out;
  }

  Widget _eventTile(CalendarEvent e, bool past) {
    final tile = Opacity(
      opacity: past ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          // Pastille date
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(color: e.type.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text(DateFormat('d', 'fr_FR').format(e.start),
                  style: display(18, weight: FontWeight.w800, color: e.type.color)),
              Text(DateFormat('MMM', 'fr_FR').format(e.start).toUpperCase(),
                  style: body(9, weight: FontWeight.w800, color: e.type.color)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(e.type.icon, size: 13, color: e.type.color),
              const SizedBox(width: 5),
              Flexible(child: Text('${e.type.label} · ${_range(e)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(11.5, color: OC.muted, weight: FontWeight.w600))),
            ]),
            if (e.description != null) ...[
              const SizedBox(height: 5),
              Text(e.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(12, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.3)),
            ],
          ])),
          if (e.link != null) const Icon(Icons.open_in_new_rounded, size: 16, color: OC.muted),
        ]),
      ),
    );
    if (e.link == null) return tile;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openUrl(context, e.link),
      child: tile,
    );
  }

  String _range(CalendarEvent e) {
    if (!e.isRange) return DateFormat('EEE d MMM', 'fr_FR').format(e.start);
    return '${DateFormat('d', 'fr_FR').format(e.start)} – ${DateFormat('d MMM', 'fr_FR').format(e.end)}';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
