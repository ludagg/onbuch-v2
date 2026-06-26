import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/skeletons.dart';
import '../../models/bourse.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

/// Page « Bourses » (Orientation) : liste des bourses d'études, recherche et
/// filtre Cameroun / Étranger. Données admin avec repli sur une liste curée.
class BoursesScreen extends StatefulWidget {
  const BoursesScreen({super.key});

  @override
  State<BoursesScreen> createState() => _BoursesScreenState();
}

class _BoursesScreenState extends State<BoursesScreen> {
  final _searchCtrl = TextEditingController();
  late final Future<List<Bourse>> _future = DatabaseService().getBourses();
  String _query = '';
  String _scope = 'Toutes'; // Toutes | Cameroun | Étranger

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(Bourse b) {
    if (_scope == 'Cameroun' && !b.isLocal) return false;
    if (_scope == 'Étranger' && b.isLocal) return false;
    if (_query.isEmpty) return true;
    bool has(String s) => s.toLowerCase().contains(_query);
    return has(b.title) || has(b.provider) || has(b.destination) || has(b.level) || b.tags.any(has);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Bourses'),
      body: FutureBuilder<List<Bourse>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: const [SkeletonList(count: 5)],
            );
          }
          final all = [...(snap.data ?? const <Bourse>[])]..sort((a, b) => a.order.compareTo(b.order));
          final list = all.where(_matches).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              _searchField(),
              const SizedBox(height: 12),
              Row(children: [
                for (final s in const ['Toutes', 'Cameroun', 'Étranger'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _scope = s),
                      child: OBChip(s, active: _scope == s),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              // Avertissement (dates indicatives)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: OC.warnBg, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: OC.warn),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Dates et conditions indicatives — vérifie toujours sur le lien officiel.',
                      style: body(11, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.3))),
                ]),
              ),
              const SizedBox(height: 14),
              Text('${list.length} bourse${list.length > 1 ? 's' : ''}',
                  style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.school_rounded,
                  title: 'Aucune bourse',
                  message: 'Aucune bourse ne correspond à ta recherche ou à ton filtre.',
                )
              else
                for (var i = 0; i < list.length; i++)
                  Appear(index: i, child: Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _BourseCard(list[i]),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OC.line2, width: 1.5),
      ),
      child: Row(children: [
        Icon(Icons.search_rounded, size: 19, color: OC.muted),
        const SizedBox(width: 11),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            style: body(14, color: OC.ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Bourse, pays, organisme…',
              hintStyle: body(14, color: OC.muted, weight: FontWeight.w500),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        if (_query.isNotEmpty)
          GestureDetector(
            onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18)),
          ),
      ]),
    );
  }
}

class _BourseCard extends StatelessWidget {
  final Bourse b;
  const _BourseCard(this.b);

  @override
  Widget build(BuildContext context) {
    final accent = b.isLocal ? OC.good : OC.blue;
    return GestureDetector(
      onTap: b.link.isEmpty ? null : () => openUrl(context, b.link),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(b.isLocal ? Icons.flag_rounded : Icons.public_rounded, size: 22, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(13.5, weight: FontWeight.w800).copyWith(height: 1.15)),
              if (b.provider.isNotEmpty || b.destination.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text([b.provider, b.destination].where((e) => e.trim().isNotEmpty).join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
              ],
            ])),
            if (b.link.isNotEmpty) ...[
              const SizedBox(width: 6),
              Icon(Icons.open_in_new_rounded, size: 16, color: OC.faint),
            ],
          ]),
          if (b.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(b.description, style: body(12, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
          ],
          const SizedBox(height: 11),
          // Méta : niveau, prise en charge, échéance
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (b.level.isNotEmpty) _metaRow(Icons.school_outlined, b.level),
            if (b.coverage.isNotEmpty) ...[
              const SizedBox(height: 5),
              _metaRow(Icons.savings_outlined, b.coverage),
            ],
            if (b.deadline.isNotEmpty) ...[
              const SizedBox(height: 5),
              _metaRow(Icons.event_outlined, 'Échéance : ${b.deadline}'),
            ],
          ]),
          if (b.tags.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final t in b.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(8)),
                  child: Text(t, style: body(10.5, color: OC.ink2, weight: FontWeight.w600)),
                ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 14, color: OC.muted)),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: body(12, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.3))),
      ]);
}
