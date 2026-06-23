import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import 'cours_models.dart';
import 'cours_ui.dart';

/// Liste complète des packs, filtrable (série · niveau · matière).
class AllPacksScreen extends StatefulWidget {
  const AllPacksScreen({super.key});
  @override
  State<AllPacksScreen> createState() => _AllPacksScreenState();
}

class _AllPacksScreenState extends State<AllPacksScreen> {
  String serie = 'Bac C';
  String niveau = 'Tous niveaux';
  String matiere = 'Toutes matières';

  static const _series = ['Bac C'];
  static const _niveaux = ['Tous niveaux', 'Terminale', 'Première'];
  static const _matieres = ['Toutes matières', 'Maths', 'Physique', 'Chimie'];

  List<Pack> get _filtered => kPacks.where((p) {
        if (niveau != 'Tous niveaux' && p.niveau != niveau) return false;
        if (matiere != 'Toutes matières' && p.matiere != matiere) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: Text('Tous les packs', style: display(17, weight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          CoursSearchBar(placeholder: 'Rechercher un pack...', onFilter: () {}),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _drop(serie, _series, (v) => setState(() => serie = v))),
            const SizedBox(width: 8),
            Expanded(child: _drop(niveau, _niveaux, (v) => setState(() => niveau = v))),
            const SizedBox(width: 8),
            Expanded(child: _drop(matiere, _matieres, (v) => setState(() => matiere = v))),
          ]),
          const SizedBox(height: 18),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(child: Text('Aucun pack pour ces filtres.', style: body(13, color: OC.muted))),
            )
          else
            for (final p in list) PackListCard(p),
        ],
      ),
    );
  }

  Widget _drop(String value, List<String> options, ValueChanged<String> onSelect) {
    return GestureDetector(
      onTap: () => _pick(value, options, onSelect),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: OC.line2, width: 1.5)),
        child: Row(children: [
          Expanded(child: Text(_shortLabel(value), style: body(12, weight: FontWeight.w700, color: OC.ink), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Icon(Icons.expand_more_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  String _shortLabel(String v) => v.replaceAll('Tous niveaux', 'Niveau').replaceAll('Toutes matières', 'Matière');

  void _pick(String current, List<String> options, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          for (final o in options)
            ListTile(
              title: Text(o, style: body(14, weight: FontWeight.w600, color: o == current ? OC.o700 : OC.ink)),
              trailing: o == current ? Icon(Icons.check_rounded, color: OC.o600, size: 20) : null,
              onTap: () { onSelect(o); Navigator.pop(ctx); },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
