import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/cours_packs_service.dart';

const _kFilters = ['Tous', 'Gratuits', 'Premium', 'Populaires'];

/// Catalogue de cours — écran principal du module Cours. Données réelles :
/// packs (matières) filtrés par la classe de l'élève (examen + série), comme
/// les annales. Achat des premium en crédits OnBuch.
class CoursCatalogueScreen extends StatefulWidget {
  const CoursCatalogueScreen({super.key});

  @override
  State<CoursCatalogueScreen> createState() => _CoursCatalogueScreenState();
}

class _CoursCatalogueScreenState extends State<CoursCatalogueScreen> {
  final _packs = CoursPacks.instance;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _packs.load();
  }

  List<Pack> get _visible {
    final all = _packs.catalogue;
    switch (_filter) {
      case 1: return all.where((p) => !p.premium).toList();
      case 2: return all.where((p) => p.premium).toList();
      case 3: return all.reversed.toList(); // démo « populaires »
      default: return all;
    }
  }

  bool get _showComplete => (_filter == 0 || _filter == 2) && _packs.premiumAvailable.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: ListenableBuilder(
          listenable: _packs,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Catalogue de cours', style: display(18, weight: FontWeight.w700)),
            Text(_packs.classLabel.isEmpty ? 'Programme' : _packs.classLabel, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
        actions: [
          IconButton(icon: Icon(Icons.auto_stories_rounded, color: OC.ink), onPressed: () => context.push('/cours/bibliotheque')),
          IconButton(icon: Icon(Icons.search_rounded, color: OC.ink), onPressed: () {/* TODO nav */}),
          IconButton(icon: Icon(Icons.tune_rounded, color: OC.ink), onPressed: () {/* TODO nav */}),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: _packs,
        builder: (context, _) {
          final visible = _visible;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
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
              if (_packs.loading && _packs.catalogue.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: OC.o500)))
              else if (_packs.catalogue.isEmpty)
                _empty()
              else ...[
                if (_showComplete) ...[
                  _completePackCard(context),
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
                  children: [for (final p in visible) _packCard(context, p)],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _completePackCard(BuildContext context) {
    final premium = _packs.premiumAvailable;
    final lessons = premium.fold(0, (s, p) => s + p.lessons);
    final subtotal = premium.fold(0, (s, p) => s + p.price);
    final price = premium.length >= 2 ? (subtotal * 0.7).round() : subtotal;
    final allInCart = premium.isNotEmpty && premium.every((p) => _packs.inCart(p.id));
    return GestureDetector(
      onTap: allInCart ? () => context.push('/cours/panier') : () => _packs.addAllToCart(premium),
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
              child: Text('PACK COMPLET', style: body(9.5, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.4)),
            ),
            const Spacer(),
            Icon(Icons.workspace_premium_rounded, color: OC.o500, size: 22),
          ]),
          const SizedBox(height: 12),
          Text('Toutes les matières premium', style: display(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${premium.length} matières · $lessons leçons · bundle -30 %', style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            Text('$price crédits', style: display(20, weight: FontWeight.w700, color: OC.o600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: allInCart ? null : OC.grad,
                color: allInCart ? OC.goodBg : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(allInCart ? 'Au panier ✓' : '+ Tout ajouter',
                  style: body(13, weight: FontWeight.w700, color: allInCart ? OC.waInk : Colors.white)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _packCard(BuildContext context, Pack p) {
    final owned = _packs.isOwned(p.id);
    final inCart = _packs.inCart(p.id);
    final sub = [p.lessons > 0 ? '${p.lessons} leçons' : null, p.level.isEmpty ? null : p.level].whereType<String>().join(' · ');
    return GestureDetector(
      onTap: () => context.push('/cours/pack?id=${p.id}'),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(p.code),
            const Spacer(),
            _tierTag(p.premium),
          ]),
          const SizedBox(height: 12),
          Text(p.name, style: body(14, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(sub.isEmpty ? 'Pack de cours' : sub, style: body(11, color: OC.muted, weight: FontWeight.w600)),
          const Spacer(),
          _actionButton(p, owned, inCart),
        ]),
      ),
    );
  }

  Widget _actionButton(Pack p, bool owned, bool inCart) {
    if (owned) return _btn('✓ Ajouté', OC.goodBg, OC.waInk, null);
    if (p.premium && inCart) return _btn('Au panier ✓', OC.o50, OC.o700, null);
    return _btn('+ Ajouter', null, Colors.white, () => _packs.add(p), gradient: true);
  }

  Widget _btn(String label, Color? bg, Color fg, VoidCallback? onTap, {bool gradient = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, height: 38,
          decoration: BoxDecoration(gradient: gradient ? OC.grad : null, color: gradient ? null : bg, borderRadius: BorderRadius.circular(11)),
          alignment: Alignment.center,
          child: Text(label, style: body(12.5, weight: FontWeight.w700, color: fg)),
        ),
      );

  Widget _avatar(String code) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(code, style: display(13, weight: FontWeight.w800, color: OC.o600)),
      );

  Widget _tierTag(bool premium) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: premium ? const Color(0xFFFBF0DD) : OC.goodBg, borderRadius: BorderRadius.circular(7)),
        child: Text(premium ? 'PREMIUM' : 'GRATUIT',
            style: body(9.5, weight: FontWeight.w800, color: premium ? const Color(0xFFA6701A) : OC.waInk).copyWith(letterSpacing: 0.3)),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(children: [
          Icon(Icons.menu_book_rounded, size: 46, color: OC.faint),
          const SizedBox(height: 12),
          Text('Catalogue bientôt disponible', style: display(17, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Les packs de cours de ta classe apparaîtront ici.', textAlign: TextAlign.center, style: body(13, color: OC.muted)),
        ]),
      );
}
