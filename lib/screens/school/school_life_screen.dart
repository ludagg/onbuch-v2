import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/calendar_event.dart';
import '../../services/database_service.dart';

/// Onglet « Campus » — la vie scolaire organisée autour de la timeline de
/// l'année : progression de l'année + calendrier (grille mensuelle) agrégeant
/// les repères officiels, examens et concours.
class SchoolLifeScreen extends StatefulWidget {
  const SchoolLifeScreen({super.key});

  @override
  State<SchoolLifeScreen> createState() => _SchoolLifeScreenState();
}

class _SchoolLifeScreenState extends State<SchoolLifeScreen> {
  final _db = DatabaseService();
  List<CalendarEvent> _events = [];
  bool _loading = true;

  late DateTime _focused;
  DateTime? _selected;
  late final DateTime _yearStart;
  late final DateTime _yearEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focused = now;
    _selected = DateTime(now.year, now.month, now.day);
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    _yearStart = DateTime(startYear, 9, 1);
    _yearEnd = DateTime(startYear + 1, 7, 31);
    _load();
  }

  Future<void> _load() async {
    final e = await _db.getCalendarEvents();
    if (mounted) setState(() { _events = e; _loading = false; });
  }

  List<CalendarEvent> _eventsForDay(DateTime day) =>
      _events.where((e) => e.coversDay(day)).toList();

  List<CalendarEvent> get _upcoming {
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final list = _events.where((e) => !e.end.isBefore(t0)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return list.take(5).toList();
  }

  double get _yearProgress {
    final total = _yearEnd.difference(_yearStart).inMinutes;
    final done = DateTime.now().difference(_yearStart).inMinutes;
    return total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  }

  String get _periodLabel {
    final now = DateTime.now();
    if (now.isBefore(_yearStart)) return 'Avant la rentrée';
    if (now.isAfter(_yearEnd)) return 'Grandes vacances';
    final p = _yearProgress;
    if (p < 1 / 3) return '1er trimestre';
    if (p < 2 / 3) return '2e trimestre';
    return '3e trimestre';
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focused.isBefore(_yearStart)
        ? _yearStart
        : (_focused.isAfter(_yearEnd) ? _yearEnd : _focused);
    final dayEvents = _selected == null ? <CalendarEvent>[] : _eventsForDay(_selected!);

    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: OC.bg,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 18,
            title: const OBWordmark(size: 23),
            actions: obTopActions(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ta vie scolaire', style: display(24, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Suis l\'avancement de ton année et les dates clés.',
                    style: body(13.5, color: OC.ink2).copyWith(height: 1.4)),
                const SizedBox(height: 18),

                _yearProgressCard(),
                const SizedBox(height: 16),

                _calendarCard(focused),
                const SizedBox(height: 16),

                // Jour sélectionné
                Text(_selected != null ? _frDate(_selected!, full: true) : 'Aujourd\'hui',
                    style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 8),
                if (dayEvents.isEmpty)
                  _hintBox('Aucun événement ce jour.')
                else
                  ...dayEvents.map((e) => _eventTile(e)),
                const SizedBox(height: 18),

                // À venir
                Row(children: [
                  Text('À venir', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/agenda'),
                    child: Row(children: [
                      Text('Voir tout', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
                      Icon(Icons.chevron_right_rounded, size: 18, color: OC.o600),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                if (_loading)
                  _hintBox('Chargement du calendrier…')
                else if (_upcoming.isEmpty)
                  _hintBox('Rien à l\'horizon pour le moment.')
                else
                  ..._upcoming.map((e) => _eventTile(e, showDate: true)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progression de l'année ─────────────────────────────────────────────────
  Widget _yearProgressCard() {
    final pct = (_yearProgress * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [OC.darkHero, OC.darkHero2],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('ANNÉE SCOLAIRE ${_yearStart.year}-${_yearEnd.year}',
              style: body(10.5, weight: FontWeight.w800, color: const Color(0xFFFFB489)).copyWith(letterSpacing: 0.1 * 10.5)),
          const Spacer(),
          Text('$pct%', style: mono(14, weight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        Text(_periodLabel, style: display(20, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _yearProgress, minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            valueColor: const AlwaysStoppedAnimation(OC.o500),
          ),
        ),
        const SizedBox(height: 9),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final s in ['Rentrée', 'T1', 'T2', 'T3', 'Examens', 'Résultats'])
            Text(s, style: body(9.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.55))),
        ]),
      ]),
    );
  }

  // ── Calendrier (grille mensuelle) ──────────────────────────────────────────
  Widget _calendarCard(DateTime focused) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(children: [
        TableCalendar<CalendarEvent>(
          locale: 'fr_FR',
          firstDay: _yearStart,
          lastDay: _yearEnd,
          focusedDay: focused,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.horizontalSwipe,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (d) => _selected != null && isSameDay(_selected, d),
          eventLoader: _eventsForDay,
          onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
          onPageChanged: (foc) => _focused = foc,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: display(15, weight: FontWeight.w700),
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: OC.ink2),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: OC.ink2),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: body(11, weight: FontWeight.w700, color: OC.muted),
            weekendStyle: body(11, weight: FontWeight.w700, color: OC.muted),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: body(13, color: OC.ink),
            weekendTextStyle: body(13, color: OC.ink2),
            todayDecoration: BoxDecoration(color: OC.o100, shape: BoxShape.circle),
            todayTextStyle: body(13, weight: FontWeight.w700, color: OC.o700),
            selectedDecoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle),
            selectedTextStyle: body(13, weight: FontWeight.w700, color: Colors.white),
          ),
          calendarBuilders: CalendarBuilders<CalendarEvent>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              final types = <CalendarEventType>[];
              for (final e in events) {
                if (!types.contains(e.type)) types.add(e.type);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final t in types.take(3))
                    Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 0.6),
                      decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                    ),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _legend(),
      ]),
    );
  }

  Widget _legend() {
    const types = [
      CalendarEventType.composition, CalendarEventType.examen,
      CalendarEventType.conge, CalendarEventType.concours, CalendarEventType.resultats,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: Wrap(spacing: 12, runSpacing: 6, children: [
        for (final t in types)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(t.label, style: body(10.5, weight: FontWeight.w600, color: OC.muted)),
          ]),
      ]),
    );
  }

  // ── Tuiles & helpers ───────────────────────────────────────────────────────
  Widget _eventTile(CalendarEvent e, {bool showDate = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: e.type.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(e.type.icon, size: 20, color: e.type.color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(showDate ? '${e.type.label} · ${_frRange(e)}' : e.type.label,
              style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _hintBox(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Icon(Icons.event_available_rounded, size: 18, color: OC.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: body(13, color: OC.muted, weight: FontWeight.w500))),
        ]),
      );

  String _frDate(DateTime d, {bool full = false}) =>
      DateFormat(full ? 'EEEE d MMMM' : 'd MMM', 'fr_FR').format(d);

  String _frRange(CalendarEvent e) {
    if (!e.isRange) return _frDate(e.start);
    return '${DateFormat('d', 'fr_FR').format(e.start)} – ${_frDate(e.end)}';
  }
}
