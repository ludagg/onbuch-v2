import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/annales_filter.dart';
import '../../models/facets.dart';
import '../../services/annales_service.dart';

/// Palette cyclique pour colorer les dossiers.
const _palette = [
  (Color(0xFFDB4F12), Color(0xFFFDEBE2)),
  (Color(0xFF2D6CDF), Color(0xFFE7EEFB)),
  (Color(0xFF1E9E63), Color(0xFFE5F3EB)),
  (Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
  (Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
  (Color(0xFFA6651E), Color(0xFFF6ECDC)),
];

class AnnalesLibraryScreen extends StatefulWidget {
  const AnnalesLibraryScreen({super.key});

  @override
  State<AnnalesLibraryScreen> createState() => _AnnalesLibraryScreenState();
}

class _AnnalesLibraryScreenState extends State<AnnalesLibraryScreen> {
  final _service = AnnalesService();
  final _searchCtrl = TextEditingController();
  late Future<FacetSet> _facets;

  @override
  void initState() {
    super.initState();
    _facets = _service.fetchFacets();
  }

  @override
  void dispose() {
    _service.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _submitSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    context.push('/annales/list',
        extra: AnnalesFilter(label: 'Recherche · "$query"', search: query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Bibliothèque', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: OC.o600,
        onRefresh: () async => setState(() => _facets = _service.fetchFacets()),
        child: FutureBuilder<FacetSet>(
          future: _facets,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: OC.o600));
            }
            final f = snap.data ?? FacetSet.empty;
            final unreachable = f.total == 0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
              children: [
                // Recherche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.05), blurRadius: 5)],
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, size: 20, color: OC.muted),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _submitSearch,
                          style: body(14.5, weight: FontWeight.w500),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Matière, examen, année…',
                            hintStyle: body(14.5, color: OC.muted, weight: FontWeight.w500),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _submitSearch(_searchCtrl.text),
                        child: const Icon(Icons.tune_rounded, size: 19, color: OC.o500),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),

                if (unreachable)
                  _Unreachable(onRetry: () => setState(() => _facets = _service.fetchFacets()))
                else ...[
                  // Total
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('${_fmt(f.total)} épreuves disponibles',
                        style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
                  ),
                  const SizedBox(height: 14),

                  // Parcourir par classe
                  if (f.schoolLevels.isNotEmpty) ...[
                    const _SectionTitle('Parcourir par classe'),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          for (var i = 0; i < f.schoolLevels.length; i++)
                            _FolderCard(
                              name: f.schoolLevels[i].value,
                              count: f.schoolLevels[i].count,
                              c: _palette[i % _palette.length].$1,
                              bg: _palette[i % _palette.length].$2,
                              onTap: () => context.push('/annales/browse',
                                  extra: AnnalesFilter(
                                    label: f.schoolLevels[i].value,
                                    schoolLevel: f.schoolLevels[i].value,
                                  )),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Examens officiels (sous-ensemble Bac/Probatoire/BEPC/GCE…)
                  if (f.examTypes.isNotEmpty) ...[
                    const _SectionTitle('Examens officiels'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: f.examTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 11),
                        itemBuilder: (_, i) => _ExamChip(
                          name: f.examTypes[i].value,
                          count: f.examTypes[i].count,
                          c: _palette[i % _palette.length].$1,
                          bg: _palette[i % _palette.length].$2,
                          onTap: () => context.push('/annales/browse',
                              extra: AnnalesFilter(
                                label: f.examTypes[i].value,
                                examType: f.examTypes[i].value,
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Matières (toutes classes confondues)
                  if (f.subjects.isNotEmpty) ...[
                    const _SectionTitle('Par matière'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          for (final s in f.subjects.take(12))
                            GestureDetector(
                              onTap: () => context.push('/annales/list',
                                  extra: AnnalesFilter(label: s.value, subject: s.value)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                                decoration: BoxDecoration(
                                  color: OC.paper,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: OC.line2, width: 1.5),
                                ),
                                child: Text('${s.value} · ${s.count}',
                                    style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(title, style: body(13, weight: FontWeight.w800, color: OC.ink2)),
      );
}

class _Unreachable extends StatelessWidget {
  final VoidCallback onRetry;
  const _Unreachable({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, size: 46, color: OC.faint),
        const SizedBox(height: 14),
        Text('Bibliothèque indisponible', style: display(16, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Impossible de joindre la bibliothèque pour le moment. Vérifiez votre connexion.',
            textAlign: TextAlign.center, style: body(13, color: OC.muted, weight: FontWeight.w500)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12), border: Border.all(color: OC.o100, width: 1.5)),
            child: Text('Réessayer', style: body(13.5, weight: FontWeight.w700, color: OC.o700)),
          ),
        ),
      ]),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final int count;
  final Color c, bg;
  final VoidCallback onTap;
  const _FolderCard({required this.name, required this.count, required this.c, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
          boxShadow: [
            BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 2),
            BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(children: [
          Positioned(
            top: -28,
            right: -22,
            child: Container(width: 70, height: 70, decoration: BoxDecoration(color: bg.withValues(alpha: 0.55), shape: BoxShape.circle)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 46,
              height: 40,
              child: Stack(children: [
                Positioned(
                  top: 0,
                  left: 2,
                  child: Container(
                    width: 22,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 0,
                  child: Container(
                    width: 46,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.27), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 19),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text(name, style: display(15, weight: FontWeight.w600).copyWith(height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${_fmt(count)} épreuves', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
          const Positioned(right: 0, top: 0, child: Icon(Icons.chevron_right_rounded, color: OC.faint, size: 18)),
        ]),
      ),
    );
  }
}

class _ExamChip extends StatelessWidget {
  final String name;
  final int count;
  final Color c, bg;
  final VoidCallback onTap;
  const _ExamChip({required this.name, required this.count, required this.c, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.workspace_premium_rounded, size: 18, color: c),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${_fmt(count)} épreuves', style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}
