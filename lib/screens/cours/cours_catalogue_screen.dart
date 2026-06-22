import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOCK (collé en haut, valeurs/libellés/états EXACTS du wireframe — écran 3).
// Aucune API, aucun fetch.
// ─────────────────────────────────────────────────────────────────────────────
const _kFilters = ['Tous', 'Gratuits', 'Premium', 'Populaires'];

const _kCompletePack = (
  tag: 'PACK COMPLET',
  title: 'Tout le programme Bac D',
  meta: '7 matières · 240 leçons · annales',
  price: '2 500 F',
);

// tier : 'GRATUIT' | 'PREMIUM' ; added : état initial du bouton.
const _kPacks = <({String code, String name, String lessons, String tier, bool added})>[
  (code: 'Ma', name: 'Maths · Tle D', lessons: '38 leçons', tier: 'GRATUIT', added: true),
  (code: 'PC', name: 'Physique-Chimie', lessons: '32 leçons', tier: 'PREMIUM', added: false),
  (code: 'SV', name: 'SVT · Tle D', lessons: '28 leçons', tier: 'PREMIUM', added: false),
  (code: 'Ph', name: 'Philosophie', lessons: '20 leçons', tier: 'GRATUIT', added: false),
];

/// Catalogue de cours — écran principal du module Cours (vision Nomad).
/// Pack complet en avant + packs par matière (gratuits / premium), filtrables.
class CoursCatalogueScreen extends StatefulWidget {
  const CoursCatalogueScreen({super.key});

  @override
  State<CoursCatalogueScreen> createState() => _CoursCatalogueScreenState();
}

class _CoursCatalogueScreenState extends State<CoursCatalogueScreen> {
  int _filter = 0; // index de filtre actif (état visuel local)
  bool _completeAdded = false;
  late final List<bool> _added = _kPacks.map((p) => p.added).toList(); // états locaux

  // Indices des packs visibles selon le filtre actif.
  List<int> get _visible {
    final all = List.generate(_kPacks.length, (i) => i);
    switch (_filter) {
      case 1: // Gratuits
        return all.where((i) => _kPacks[i].tier == 'GRATUIT').toList();
      case 2: // Premium
        return all.where((i) => _kPacks[i].tier == 'PREMIUM').toList();
      case 3: // Populaires
        // TODO: critère « Populaires » non défini par le wireframe (tri ? sous-ensemble ?).
        return all;
      default: // Tous
        return all;
    }
  }

  bool get _showComplete => _filter == 0 || _filter == 2; // Tous / Premium

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Catalogue de cours', style: display(18, weight: FontWeight.w700)),
          Text('Bac · Série D', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(icon: Icon(Icons.search_rounded, color: OC.ink), onPressed: () {/* TODO nav */}),
          IconButton(icon: Icon(Icons.tune_rounded, color: OC.ink), onPressed: () {/* TODO nav */}),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Filtres
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: OBChip(_kFilters[i], active: _filter == i),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_showComplete) ...[
            _completePackCard(),
            const SizedBox(height: 20),
            Text('Packs par matière', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 11),
          ],

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 0.82,
            children: [for (final i in visible) _packCard(i)],
          ),
        ],
      ),
    );
  }

  // ── Pack complet (carte pleine largeur) ─────────────────────────────────────
  Widget _completePackCard() {
    return GestureDetector(
      onTap: () {/* TODO nav */},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [OC.o50, OC.paper], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OC.o100, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(8)),
              child: Text(_kCompletePack.tag, style: body(9.5, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.4)),
            ),
            const Spacer(),
            Icon(Icons.workspace_premium_rounded, color: OC.o500, size: 22),
          ]),
          const SizedBox(height: 12),
          Text(_kCompletePack.title, style: display(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_kCompletePack.meta, style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            Text(_kCompletePack.price, style: display(22, weight: FontWeight.w700, color: OC.o600)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _completeAdded = !_completeAdded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _completeAdded ? null : OC.grad,
                  color: _completeAdded ? OC.goodBg : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_completeAdded ? '✓ Ajouté' : '+ Ajouter',
                    style: body(13, weight: FontWeight.w700, color: _completeAdded ? OC.waInk : Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Carte de pack matière ───────────────────────────────────────────────────
  Widget _packCard(int i) {
    final p = _kPacks[i];
    final added = _added[i];
    return GestureDetector(
      onTap: () {/* TODO nav */},
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(p.code),
            const Spacer(),
            _tierTag(p.tier),
          ]),
          const SizedBox(height: 12),
          Text(p.name, style: body(14, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(p.lessons, style: body(11, color: OC.muted, weight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _added[i] = !_added[i]),
            child: Container(
              width: double.infinity, height: 38,
              decoration: BoxDecoration(
                gradient: added ? null : OC.grad,
                color: added ? OC.goodBg : null,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(added ? '✓ Ajouté' : '+ Ajouter',
                  style: body(12.5, weight: FontWeight.w700, color: added ? OC.waInk : Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _avatar(String code) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(code, style: display(13, weight: FontWeight.w800, color: OC.o600)),
      );

  Widget _tierTag(String tier) {
    final premium = tier == 'PREMIUM';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: premium ? const Color(0xFFFBF0DD) : OC.goodBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(tier,
          style: body(9.5, weight: FontWeight.w800, color: premium ? const Color(0xFFA6701A) : OC.waInk).copyWith(letterSpacing: 0.3)),
    );
  }
}
