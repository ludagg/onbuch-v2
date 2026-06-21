import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/concours.dart';
import '../../services/database_service.dart';

/// Alertes & échéances concours (section F · écran 23). L'utilisateur active un
/// rappel par concours ; l'état est conservé localement.
class ConcoursAlertesScreen extends StatefulWidget {
  const ConcoursAlertesScreen({super.key});

  @override
  State<ConcoursAlertesScreen> createState() => _ConcoursAlertesScreenState();
}

class _ConcoursAlertesScreenState extends State<ConcoursAlertesScreen> {
  static const _prefsKey = 'ob_concours_alerts';
  List<Concours>? _items;
  Set<String> _on = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DatabaseService().getConcours();
    final now = DateTime.now();
    final upcoming = list.where((c) =>
        (c.registrationDeadline != null && c.registrationDeadline!.isAfter(now)) ||
        (c.examDate != null && c.examDate!.isAfter(now))).toList()
      ..sort((a, b) => (a.nextDate ?? now).compareTo(b.nextDate ?? now));
    Set<String> on = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      on = (prefs.getStringList(_prefsKey) ?? const []).toSet();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _items = upcoming;
      _on = on;
    });
  }

  Future<void> _toggle(String id, bool v) async {
    setState(() {
      if (v) {
        _on.add(id);
      } else {
        _on.remove(id);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _on.toList());
    } catch (_) {}
  }

  String _deadlineLabel(Concours c) {
    final now = DateTime.now();
    if (c.registrationDeadline != null && c.registrationDeadline!.isAfter(now)) {
      final d = c.registrationDeadline!.difference(now).inDays;
      return 'Clôture ${d <= 0 ? "aujourd'hui" : "dans $d j"} · ${DateFormat('d MMM', 'fr_FR').format(c.registrationDeadline!)}';
    }
    if (c.examDate != null && c.examDate!.isAfter(now)) {
      return 'Épreuves le ${DateFormat('d MMM y', 'fr_FR').format(c.examDate!)}';
    }
    return 'Échéance à venir';
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Alertes & échéances'),
      body: items == null
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(14)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.notifications_active_outlined, size: 18, color: OC.o600),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'Active un rappel pour ne rater aucune ouverture ni clôture de concours.',
                      style: body(12.5, color: OC.o700, weight: FontWeight.w600).copyWith(height: 1.4),
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(child: Text('Aucune échéance à venir', style: body(14, color: OC.muted, weight: FontWeight.w600))),
                  )
                else
                  ...items.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 11),
                        padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
                        decoration: BoxDecoration(
                          color: OC.paper,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: OC.line, width: 1.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
                            child: Icon(Icons.notifications_outlined, size: 19, color: OC.o600),
                          ),
                          const SizedBox(width: 11),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(_deadlineLabel(c), style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
                          ])),
                          Switch(
                            value: _on.contains(c.id),
                            activeColor: Colors.white,
                            activeTrackColor: OC.o500,
                            onChanged: (v) => _toggle(c.id, v),
                          ),
                        ]),
                      )),
              ],
            ),
    );
  }
}
