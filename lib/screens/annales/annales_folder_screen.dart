import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/annale.dart';
import '../../models/annales_filter.dart';
import '../../models/facets.dart';
import '../../services/annales_service.dart';
import '../../widgets/subject_avatar.dart';

/// Écran de parcours d'un sous-ensemble d'annales (une classe, un examen…).
/// Affiche les matières disponibles, des filtres série/année dynamiques, et
/// quelques épreuves récentes. Drill-down vers la liste filtrée.
class AnnalesBrowseScreen extends StatefulWidget {
  final AnnalesFilter filter;
  const AnnalesBrowseScreen({super.key, required this.filter});

  @override
  State<AnnalesBrowseScreen> createState() => _AnnalesBrowseScreenState();
}

class _AnnalesBrowseScreenState extends State<AnnalesBrowseScreen> {
  final _service = AnnalesService();
  late AnnalesFilter _filter;
  late Future<FacetSet> _facets;
  late Future<AnnalePage> _recent;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _reload();
  }

  void _reload() {
    _facets = _service.fetchFacets(_filter);
    _recent = _service.fetchDocuments(_filter, limit: 8);
  }

  void _toggleSeries(String s) {
    setState(() {
      _filter = _filter.series == s ? _filter.copyWith(clearSeries: true) : _filter.copyWith(series: s);
      _reload();
    });
  }

  void _toggleYear(int y) {
    setState(() {
      _filter = _filter.year == y ? _filter.copyWith(clearYear: true) : _filter.copyWith(year: y);
      _reload();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text(_filter.label, style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<FacetSet>(
        future: _facets,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: OC.o600));
          }
          final f = snap.data ?? FacetSet.empty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text('${f.total} épreuves', style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
              const SizedBox(height: 12),

              // Filtres série
              if (f.series.isNotEmpty) ...[
                _chipsRow([
                  for (final s in f.series)
                    _FilterChip('Série ${s.value}', active: _filter.series == s.value, onTap: () => _toggleSeries(s.value)),
                ]),
                const SizedBox(height: 9),
              ],
              // Filtres année
              if (f.years.isNotEmpty) ...[
                _chipsRow([
                  for (final y in f.years.take(8))
                    _FilterChip('${y.value}', active: _filter.year?.toString() == y.value, onTap: () => _toggleYear(int.tryParse(y.value) ?? 0)),
                ]),
                const SizedBox(height: 18),
              ],

              // Dossiers matières
              if (f.subjects.isNotEmpty) ...[
                Text('Matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 11),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    for (final s in f.subjects)
                      GestureDetector(
                        onTap: () => context.push('/annales/list',
                            extra: _filter.copyWith(label: s.value, subject: s.value)),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
                          decoration: BoxDecoration(
                            color: OC.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: OC.line, width: 1.5),
                          ),
                          child: Row(children: [
                            SubjectAvatar(s.value, size: 36),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(s.value, style: body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${s.count} épreuves', style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Épreuves récentes
              Row(children: [
                Text('Récemment ajoutées', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/annales/list', extra: _filter),
                  child: Text('Tout voir', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
                ),
              ]),
              const SizedBox(height: 11),
              FutureBuilder<AnnalePage>(
                future: _recent,
                builder: (context, rs) {
                  if (rs.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: OC.o600)),
                    );
                  }
                  final items = rs.data?.items ?? const [];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Aucune épreuve pour cette sélection.',
                          style: body(13, color: OC.muted, weight: FontWeight.w500)),
                    );
                  }
                  return Column(children: [for (final a in items) AnnaleRow(a)]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chipsRow(List<Widget> chips) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: 9), chips[i]],
        ]),
      );
}

/// Carte-ligne d'une épreuve, réutilisée par le parcours et la liste.
class AnnaleRow extends StatelessWidget {
  final Annale a;
  const AnnaleRow(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/annales/detail', extra: a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          SubjectAvatar(a.subject, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.heading, style: body(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(a.contextLine.isEmpty ? a.docTypeLabel : a.contextLine,
                  style: body(11, color: OC.muted, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          _DocTypePill(a.docTypeLabel),
        ]),
      ),
    );
  }
}

class _DocTypePill extends StatelessWidget {
  final String type;
  const _DocTypePill(this.type);
  @override
  Widget build(BuildContext context) {
    final (Color c, Color bg) = switch (type) {
      'Corrigé' => (const Color(0xFF1E9E63), const Color(0xFFE5F3EB)),
      'Fascicule' => (const Color(0xFF7A5AE0), const Color(0xFFEEE9FA)),
      'Épreuve zéro' => (const Color(0xFFA6701A), const Color(0xFFFBF0DD)),
      'Cours' => (const Color(0xFF2D6CDF), const Color(0xFFE7EEFB)),
      'Exercices' => (const Color(0xFF0E9AA0), const Color(0xFFE1F2F2)),
      _ => (const Color(0xFFC0392B), const Color(0xFFFAE7E4)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(type, style: body(10, weight: FontWeight.w800, color: c)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(this.label, {required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? OC.o50 : OC.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? OC.o500 : OC.line2, width: 1.5),
        ),
        child: Text(label, style: body(13, weight: FontWeight.w700, color: active ? OC.o700 : OC.ink2)),
      ),
    );
  }
}
