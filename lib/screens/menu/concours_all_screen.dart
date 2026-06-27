import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/skeletons.dart';
import '../../models/concours.dart';
import '../../services/database_service.dart';
import '../../data/orientation_guide.dart';

// ── Catégorisation : domaine (déduit du nom) + ville (déduite du texte) ───────
// Aucune saisie admin requise : on s'appuie sur la base « orientation » déjà
// utilisée pour rattacher un concours à une filière, et sur une liste de villes.
const _kCities = [
  'Yaoundé', 'Douala', 'Dschang', 'Buéa', 'Bamenda', 'Ngaoundéré', 'Maroua',
  'Garoua', 'Bertoua', 'Ebolowa', 'Bafoussam', 'Kumba', 'Foumban',
  'Nkongsamba', 'Bandjoun', 'Soa', 'Mbalmayo', 'Limbé', 'Kribi', 'Edéa', 'Sangmélima',
];

String _fold(String s) {
  const map = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'û': 'u', 'ù': 'u', 'ü': 'u', 'ç': 'c',
  };
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(map[ch] ?? ch);
  }
  return b.toString();
}

OrientationField? _concoursField(Concours c) =>
    matchOrientation('${c.name} ${c.organizer} ${c.audience ?? ''}');

String _concoursDomain(Concours c) => _concoursField(c)?.title ?? 'Autres';

String? _concoursCity(Concours c) {
  final hay = _fold('${c.name} ${c.organizer} ${c.description ?? ''} ${c.audience ?? ''}');
  for (final city in _kCities) {
    if (hay.contains(_fold(city))) return city;
  }
  return null;
}

/// Page dédiée à la **liste complète des concours** (ouverts et clôturés),
/// avec recherche et filtres : statut, domaine et ville. Distincte de l'onglet
/// Concours qui ne met en avant que les concours ouverts.
class ConcoursAllScreen extends StatefulWidget {
  const ConcoursAllScreen({super.key});

  @override
  State<ConcoursAllScreen> createState() => _ConcoursAllScreenState();
}

class _ConcoursAllScreenState extends State<ConcoursAllScreen> {
  final _searchCtrl = TextEditingController();
  late final Future<List<Concours>> _future = DatabaseService().getConcours();
  String _query = '';
  String _status = 'Tous'; // Tous | Ouverts | Clôturés
  String _domain = 'Tous'; // Tous | <domaine>
  String _city = 'Tous'; // Tous | <ville>

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isOpen(Concours c) =>
      c.registrationDeadline == null || c.registrationDeadline!.isAfter(DateTime.now());

  bool _matches(Concours c) {
    if (_status == 'Ouverts' && !_isOpen(c)) return false;
    if (_status == 'Clôturés' && _isOpen(c)) return false;
    if (_domain != 'Tous' && _concoursDomain(c) != _domain) return false;
    if (_city != 'Tous' && _concoursCity(c) != _city) return false;
    if (_query.isEmpty) return true;
    bool has(String? s) => s != null && s.toLowerCase().contains(_query);
    return has(c.name) || has(c.organizer) || has(c.description) || has(c.audience);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Tous les concours'),
      body: FutureBuilder<List<Concours>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: const [SkeletonList(count: 6)],
            );
          }
          final all = [...(snap.data ?? const <Concours>[])]
            ..sort((a, b) {
              // Ouverts d'abord (clôture la plus proche), clôturés ensuite.
              final oa = _isOpen(a), ob = _isOpen(b);
              if (oa != ob) return oa ? -1 : 1;
              final da = a.registrationDeadline, db = b.registrationDeadline;
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
          final list = all.where(_matches).toList();

          // Domaines & villes présents dans les données (« Autres » en dernier).
          final domains = (all.map(_concoursDomain).toSet().toList()
            ..sort((a, b) {
              if (a == 'Autres') return 1;
              if (b == 'Autres') return -1;
              return a.compareTo(b);
            }));
          final cities = (all.map(_concoursCity).whereType<String>().toSet().toList()..sort());

          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.track_changes_rounded,
              title: 'Aucun concours',
              message: 'Les concours apparaîtront ici dès qu\'ils seront publiés.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              _searchField(),
              const SizedBox(height: 12),
              Row(children: [
                for (final s in const ['Tous', 'Ouverts', 'Clôturés'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: OBChip(s, active: _status == s),
                    ),
                  ),
              ]),
              // Filtre par domaine (défilant)
              if (domains.length > 1) ...[
                const SizedBox(height: 10),
                _chipRow(
                  ['Tous', ...domains],
                  _domain,
                  (v) => setState(() => _domain = v),
                  icon: Icons.category_rounded,
                ),
              ],
              // Filtre par ville (défilant)
              if (cities.isNotEmpty) ...[
                const SizedBox(height: 10),
                _chipRow(
                  ['Tous', ...cities],
                  _city,
                  (v) => setState(() => _city = v),
                  icon: Icons.location_on_rounded,
                ),
              ],
              const SizedBox(height: 14),
              Text('${list.length} concours', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OC.paper, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OC.line, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(Icons.search_off_rounded, size: 18, color: OC.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Aucun concours pour ce filtre.',
                        style: body(13, color: OC.muted, weight: FontWeight.w500))),
                  ]),
                )
              else
                for (var i = 0; i < list.length; i++)
                  Appear(index: i, child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ConcoursRow(list[i]),
                  )),
            ],
          );
        },
      ),
    );
  }

  /// Rangée de filtres défilante (chips), précédée d'une icône repère.
  Widget _chipRow(List<String> options, String active, ValueChanged<String> onPick, {required IconData icon}) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 30, height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(999)),
              child: Icon(icon, size: 16, color: OC.muted),
            ),
          ),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onPick(o),
                child: OBChip(o, active: active == o),
              ),
            ),
        ],
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
              hintText: 'École, filière, organisateur…',
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

String _frShort(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);

class _ConcoursRow extends StatelessWidget {
  final Concours c;
  const _ConcoursRow(this.c);

  static final _avatarColors = [
    OC.o600, OC.blue, OC.good, const Color(0xFF7A5AE0), const Color(0xFF0E9AA0), const Color(0xFFD2462E),
  ];
  Color get _accent => _avatarColors[c.name.hashCode.abs() % _avatarColors.length];

  OrientationField? get _field => _concoursField(c);
  String? get _city => _concoursCity(c);

  String get _badge {
    final caps = RegExp(r'\b[A-Z]{2,6}\b').allMatches(c.name).map((m) => m.group(0)!).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (caps.isNotEmpty) return caps.first;
    final w = c.name.trim();
    return w.isEmpty ? 'C' : w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dl = c.registrationDeadline;
    final days = dl == null ? null : dl.difference(DateTime.now()).inDays;
    final open = days == null || days >= 0;
    final urgent = days != null && days >= 0 && days <= 7;
    final accent = _accent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/concours-detail', extra: c),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Text(_badge, style: display(_badge.length >= 4 ? 12 : 15, weight: FontWeight.w800, color: accent)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(c.organizer.isNotEmpty ? c.organizer : (c.description ?? ''),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
            if (_field != null || _city != null) ...[
              const SizedBox(height: 5),
              Row(children: [
                if (_field != null) ...[
                  Icon(_field!.icon, size: 12, color: _field!.accent),
                  const SizedBox(width: 4),
                  Flexible(child: Text(_field!.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: body(10.5, color: _field!.accent, weight: FontWeight.w700))),
                ],
                if (_field != null && _city != null) const SizedBox(width: 8),
                if (_city != null) ...[
                  Icon(Icons.location_on_rounded, size: 12, color: OC.muted),
                  const SizedBox(width: 3),
                  Text(_city!, style: body(10.5, color: OC.ink2, weight: FontWeight.w600)),
                ],
              ]),
            ],
            if (dl != null) ...[
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.event_outlined, size: 12.5, color: urgent ? OC.bad : OC.muted),
                const SizedBox(width: 4),
                Text('Clôture ${_frShort(dl)}',
                    style: body(11, weight: FontWeight.w700, color: urgent ? OC.bad : OC.ink2)),
              ]),
            ],
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: !open ? OC.panel : (urgent ? OC.bad.withValues(alpha: 0.12) : OC.o50),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              days != null && days >= 0 ? (days == 0 ? 'Auj.' : 'J-$days') : (open ? 'Ouvert' : 'Clos'),
              style: mono(11.5, weight: FontWeight.w800, color: !open ? OC.muted : (urgent ? OC.bad : OC.o700)),
            ),
          ),
        ]),
      ),
    );
  }
}
