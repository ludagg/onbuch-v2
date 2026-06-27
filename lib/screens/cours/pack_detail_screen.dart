import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/cours_packs_service.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/exercise.dart';

/// Détail d'un pack (fiche produit) — données réelles. `subjectId` via la route.
class PackDetailScreen extends StatefulWidget {
  final String? subjectId;
  const PackDetailScreen({super.key, this.subjectId});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  // Pack résolu depuis la base si absent du catalogue de la classe (navigation
  // « par examen »). Null tant qu'il n'est pas chargé / introuvable.
  Pack? _fetched;
  bool _fetching = true;

  // Exercices de la matière (banque admin) — pour le bouton « Voir les exercices ».
  List<ExerciseChapter> _exoChapters = const [];
  String? _examen, _serie;

  @override
  void initState() {
    super.initState();
    _resolve();
    _loadExos();
  }

  Future<void> _resolve() async {
    final p = await CoursPacks.instance.fetchPack(widget.subjectId ?? '');
    if (mounted) setState(() { _fetched = p; _fetching = false; });
  }

  /// Charge la classe de l'élève (examen/série) + la banque d'exercices, pour
  /// proposer un accès direct aux exercices de la matière depuis sa fiche.
  Future<void> _loadExos() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        final prof = await DatabaseService().getUserProfile(user.$id);
        _examen = (prof?['examen'] ?? '').toString();
        _serie = (prof?['serieCode'] ?? '').toString().isNotEmpty
            ? (prof?['serieCode']).toString()
            : (prof?['serie'] ?? '').toString();
      }
      final chapters = await ExerciseService().getChapters();
      if (mounted) setState(() => _exoChapters = chapters);
    } catch (_) {/* hors-ligne / non connecté → pas de bouton exercices */}
  }

  /// Chapitres d'exercices de cette matière, pour la classe de l'élève.
  /// Même appariement (nom exact, insensible à la casse) que l'écran cible.
  List<ExerciseChapter> _exosFor(Pack p) => _exoChapters
      .where((c) =>
          c.subject.trim().toLowerCase() == p.name.trim().toLowerCase() &&
          c.appliesToClass(_examen, _serie))
      .toList();

  Pack? _packOf(CoursPacks store) => store.byId(widget.subjectId ?? '') ?? _fetched;

  @override
  Widget build(BuildContext context) {
    final store = CoursPacks.instance;
    return Scaffold(
      backgroundColor: OC.bg,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final p = _packOf(store);
          if (p == null) {
            return _fetching
                ? const Center(child: CircularProgressIndicator(color: OC.o500))
                : Center(child: Text('Pack introuvable.', style: body(14, color: OC.muted)));
          }
          final owned = store.isOwned(p.id);
          return CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: OC.bg,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: OC.panel,
                  alignment: Alignment.center,
                  child: Text('Couverture du pack', style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _avatar(p.code, 48),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.level.isEmpty ? p.name : '${p.name} · ${p.level}', style: display(19, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Programme MINESEC · ${p.lessons} leçons', style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
                    ])),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: _statBox('${p.lessons}', 'Leçons')),
                    const SizedBox(width: 9),
                    Expanded(child: _statBox('${p.videos}', 'Vidéos')),
                    const SizedBox(width: 9),
                    Expanded(child: _statBox('${p.quizzes}', 'Quiz')),
                    const SizedBox(width: 9),
                    Expanded(child: _statBox('${p.coef}', 'Coef', accent: true)),
                  ]),
                  ..._exercicesAccess(context, p),
                  const SizedBox(height: 20),
                  Text('Au programme', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                  const SizedBox(height: 10),
                  if (p.modules.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
                      child: Text('Le programme de ce pack arrivera bientôt.', style: body(13, color: OC.muted)),
                    )
                  else
                    for (var i = 0; i < p.modules.length; i++) _moduleRow(context, p, i, owned),
                ]),
              ),
            ),
          ]);
        },
      ),
      bottomSheet: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final p = _packOf(store);
          if (p == null) return const SizedBox.shrink();
          return _footer(context, p, store);
        },
      ),
    );
  }

  /// Encart « Voir les exercices » — n'apparaît que si la matière a des
  /// exercices pour la classe de l'élève. Ouvre directement la liste des
  /// chapitres d'exercices de la matière.
  List<Widget> _exercicesAccess(BuildContext context, Pack p) {
    final exos = _exosFor(p);
    if (exos.isEmpty) return const [];
    final n = exos.length;
    return [
      const SizedBox(height: 20),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/exercices/chapitres',
            extra: {'subject': p.name, 'examen': _examen, 'serie': _serie}),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OC.o50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OC.o200, width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.fitness_center_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Voir les exercices', style: body(14, weight: FontWeight.w800, color: OC.ink)),
              const SizedBox(height: 2),
              Text('$n chapitre${n > 1 ? 's' : ''} d\'exercices · énoncés & corrigés',
                  style: body(11.5, color: OC.o700, weight: FontWeight.w600)),
            ])),
            Icon(Icons.chevron_right_rounded, size: 20, color: OC.o600),
          ]),
        ),
      ),
    ];
  }

  Widget _moduleRow(BuildContext context, Pack p, int i, bool owned) {
    final m = p.modules[i];
    final preview = m.free && !owned;
    final locked = !owned && !m.free;
    final open = owned || m.free;
    final leading = preview
        ? Container(width: 30, height: 30, decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center, child: Icon(Icons.check_rounded, size: 17, color: OC.good))
        : Container(width: 30, height: 30, decoration: BoxDecoration(color: locked ? OC.panel : OC.o50, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center, child: Text('${i + 1}', style: body(13, weight: FontWeight.w800, color: locked ? OC.muted : OC.o600)));
    return GestureDetector(
      onTap: open ? () => context.push('/cours/lecon?id=${p.id}&i=$i') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: body(13.5, weight: FontWeight.w700, color: locked ? OC.ink2 : OC.ink)),
            const SizedBox(height: 2),
            Text(preview ? 'Aperçu gratuit' : (locked ? 'Premium' : 'Chapitre'), style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ])),
          if (preview)
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(8)),
                child: Text('APERÇU', style: body(9.5, weight: FontWeight.w800, color: OC.o700).copyWith(letterSpacing: 0.3)))
          else if (locked)
            Icon(Icons.lock_outline_rounded, size: 17, color: OC.muted)
          else
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
        ]),
      ),
    );
  }

  Widget _footer(BuildContext context, Pack p, CoursPacks store) {
    final owned = store.isOwned(p.id);
    final inCart = store.inCart(p.id);
    late String label; late VoidCallback onTap;
    if (owned) {
      label = 'Commencer le pack';
      onTap = () => context.push('/cours/lecon?id=${p.id}');
    } else if (p.premium && inCart) {
      label = 'Voir le panier';
      onTap = () => context.push('/cours/panier');
    } else if (p.premium) {
      label = '+ Ajouter à ma bibliothèque';
      onTap = () => store.add(p);
    } else {
      label = '+ Ajouter (gratuit)';
      onTap = () => store.add(p);
    }
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
      child: Row(children: [
        if (!owned) ...[
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(p.premium ? 'Premium' : 'Gratuit', style: body(11, color: OC.muted, weight: FontWeight.w700)),
            Text(p.premium ? '${p.price}' : 'Gratuit', style: display(20, weight: FontWeight.w700, color: p.premium ? OC.o600 : OC.good)),
            if (p.premium) Text('crédits', style: body(10, color: OC.muted, weight: FontWeight.w600)),
          ]),
          const SizedBox(width: 14),
        ],
        Expanded(child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(label, style: body(14, weight: FontWeight.w700, color: Colors.white)),
          ),
        )),
      ]),
    );
  }

  Widget _avatar(String code, double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(size * 0.28)),
        alignment: Alignment.center,
        child: Text(code, style: display(size * 0.32, weight: FontWeight.w800, color: OC.o600)),
      );

  Widget _statBox(String value, String label, {bool accent = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          Text(value, style: display(18, weight: FontWeight.w700, color: accent ? OC.o600 : OC.ink)),
          const SizedBox(height: 2),
          Text(label, style: body(10, color: OC.muted, weight: FontWeight.w600)),
        ]),
      );
}
