import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/leo_mascot.dart';
import '../../services/cours_packs_service.dart';
import '../../services/database_service.dart';
import '../../models/fascicule.dart';

/// Accueil du module Cours — calque de la page Annales : recherche, accès
/// rapides (Mes cours · Panier · Catalogue), grille « Parcourir par examen »
/// (limitée à BEPC · Bac ESG · Probatoire ESG) puis une zone « Tous les cours »
/// qui liste directement les packs de ces examens, triés.
class CoursLibraryHomeScreen extends StatefulWidget {
  const CoursLibraryHomeScreen({super.key});

  @override
  State<CoursLibraryHomeScreen> createState() => _CoursLibraryHomeScreenState();
}

class _CoursLibraryHomeScreenState extends State<CoursLibraryHomeScreen> {
  final _packs = CoursPacks.instance;

  // Fascicules (livres OnBuch) pour la vitrine « Nos fascicules ».
  List<Fascicule> _fascicules = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _packs.load();
    final fasc = await DatabaseService().getFascicules();
    if (mounted) setState(() { _fascicules = fasc; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const OBWordmark(size: 23),
        actions: obTopActions(context),
      ),
      body: RefreshIndicator(
        color: OC.o500,
        onRefresh: () => _load(),
        child: ListenableBuilder(
          listenable: _packs,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
            children: [
              // En-tête : Léo (à gauche) + accroche sur la même ligne.
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 20, 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const LeoMascot(size: 56, mood: LeoMood.wave),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text("Qu'est-ce qu'on révise aujourd'hui ?",
                        style: display(19, weight: FontWeight.w800).copyWith(height: 1.12)),
                  ),
                ]),
              ),

              // Recherche → recherche transverse Cours
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.push('/cours-search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.05), blurRadius: 5)],
                    ),
                    child: Row(children: [
                      Icon(Icons.search_rounded, size: 20, color: OC.muted),
                      const SizedBox(width: 11),
                      Expanded(child: Text('Matière, pack, leçon…', style: body(14.5, color: OC.muted, weight: FontWeight.w500))),
                      const Icon(Icons.tune_rounded, size: 19, color: OC.o500),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Mes matières : les matières de la classe de l'élève ─────────
              _mySubjectsSection(context),
              const SizedBox(height: 18),

              // ── Vitrine éditoriale « Nos fascicules » (couvertures en éventail) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FasciculesShowcase(_fascicules),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la liste des matières à afficher : **exactement** les matières de
  /// la série de l'élève (issues d'`exam_series`, comme les Annales/Ressources),
  /// chacune rattachée à son pack de cours si la base en propose un (sinon
  /// « Bientôt »). On n'ajoute **pas** les autres packs de l'examen : « Mes
  /// matières » colle à la structure de la série — pour faire apparaître une
  /// matière de cours, l'admin l'ajoute à la série (« Séries / filières »), ce
  /// qui la fait apparaître ici ET dans les Ressources, de façon cohérente.
  List<_MatiereEntry> _matiereEntries() {
    final catalogue = _packs.catalogue;
    final names = _packs.classSubjects;
    String norm(String s) => s.trim().toLowerCase();
    final used = <String>{};
    Pack? match(String name) {
      final n = norm(name);
      for (final p in catalogue) {
        if (!used.contains(p.id) && norm(p.name) == n) return p;
      }
      for (final p in catalogue) {
        if (used.contains(p.id)) continue;
        final pn = norm(p.name);
        if (pn.contains(n) || n.contains(pn)) return p;
      }
      return null;
    }

    final out = <_MatiereEntry>[];
    for (final name in names) {
      final p = match(name);
      if (p != null) used.add(p.id);
      out.add(_MatiereEntry(name, p));
    }
    return out;
  }

  /// Section « Mes matières » : affiche **toutes** les matières de la classe de
  /// l'élève (liste complète issue de la taxonomie, comme la page Annales), avec
  /// les icônes de matière. Note sur la classe choisie + accès pour la modifier
  /// dans le profil. Si aucune classe n'est définie, invite à la choisir.
  Widget _mySubjectsSection(BuildContext context) {
    final cls = _packs.classLabel;
    final hasClass = _packs.examLabel.trim().isNotEmpty || _packs.serieLabel.trim().isNotEmpty;
    final entries = hasClass ? _matiereEntries() : const <_MatiereEntry>[];

    // Retour du profil : forcer la relecture (la classe a pu changer) pour
    // refiltrer les matières, puis recharger le reste de la page.
    Future<void> editClass() async {
      await context.push('/edit-profile');
      await _packs.refresh();
      if (mounted) _load();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // En-tête : titre + compteur + accès « Ma classe / Choisir ».
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Text('Mes matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          if (_loaded && hasClass && entries.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text('${entries.length}', style: body(12, weight: FontWeight.w700, color: OC.muted)),
          ],
          const Spacer(),
          GestureDetector(
            onTap: editClass,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.tune_rounded, size: 14, color: OC.o600),
              const SizedBox(width: 4),
              Text(hasClass ? 'Ma classe' : 'Choisir', style: body(12, weight: FontWeight.w700, color: OC.o600)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      // Note : d'après la classe choisie, modifiable dans le profil.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          hasClass
              ? 'D\'après ta classe${cls.isEmpty ? '' : ' · $cls'}. Modifie-la dans ton profil si besoin.'
              : 'Choisis ta classe dans ton profil pour voir directement tes matières ici.',
          style: body(11.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.3),
        ),
      ),
      const SizedBox(height: 13),
      // Corps : grille des matières, état vide, ou invitation à choisir la classe.
      if (!_loaded)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: List.generate(3, (_) => const SkeletonRow())),
        )
      else if (!hasClass)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: editClass,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OC.o50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OC.o100, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.school_rounded, size: 21, color: OC.o600),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Choisis ta classe', style: body(13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Examen + série → on affiche tes matières directement.',
                      style: body(11, color: OC.muted, weight: FontWeight.w500)),
                ])),
                Icon(Icons.chevron_right_rounded, size: 18, color: OC.o600),
              ]),
            ),
          ),
        )
      else if (entries.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Text('Aucune matière disponible pour ta classe pour le moment.',
              style: body(12.5, color: OC.muted, weight: FontWeight.w500)),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              for (final e in entries)
                _SubjectTile(
                  name: e.name,
                  pack: e.pack,
                  onTap: () async {
                    if (e.pack != null) {
                      await context.push('/cours/pack?id=${e.pack!.id}');
                      if (mounted) _load();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Cours bientôt disponible pour ${e.name}.'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                ),
            ],
          ),
        ),
    ]);
  }
}

/// Une matière de la classe : son nom (taxonomie) + son pack si la base en
/// propose un (sinon `null` → « Bientôt »).
class _MatiereEntry {
  final String name;
  final Pack? pack;
  const _MatiereEntry(this.name, this.pack);
}

/// Tuile d'une matière de l'élève (grille « Mes matières »). Icône de matière
/// (`SubjLogo`, même rendu que la page Annales) + nom + statut. Ouvre le pack
/// s'il existe, sinon signale qu'il arrive bientôt.
class _SubjectTile extends StatelessWidget {
  final String name;
  final Pack? pack;
  final VoidCallback onTap;
  const _SubjectTile({required this.name, required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pack;
    final label = p == null
        ? 'Bientôt'
        : (p.lessons > 0 ? '${p.lessons} leçon${p.lessons > 1 ? 's' : ''}' : 'Disponible');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          SubjLogo(name, size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Row(children: [
                if (p?.premium == true) ...[
                  const Icon(Icons.lock_outline_rounded, size: 11, color: Color(0xFFA6701A)),
                  const SizedBox(width: 3),
                ],
                Flexible(child: Text(label, style: body(10.5, color: OC.muted, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Vitrine éditoriale « Nos fascicules » : 3 couvertures en éventail (héro sombre).
/// 100 % Dart (Transform + Image.network) → patchable Shorebird, aucun plugin natif.
/// Repli sur une bannière simple si aucune couverture n'est disponible (hors-ligne).
class _FasciculesShowcase extends StatelessWidget {
  const _FasciculesShowcase(this.fascicules);
  final List<Fascicule> fascicules;

  @override
  Widget build(BuildContext context) {
    final covers = [for (final f in fascicules) if (f.hasCover) f.coverUrl];
    return GestureDetector(
      onTap: () => context.push('/fascicules'),
      child: covers.isEmpty ? _plain() : _hero(covers.take(3).toList()),
    );
  }

  // Une couverture de livre (image réseau, tolérante hors-ligne).
  Widget _cover(String url, {double w = 80}) => Container(
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: AspectRatio(
            aspectRatio: 595 / 841,
            child: CachedImage(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Container(color: OC.o600),
              loadingBuilder: (_, child, p) => p == null ? child : Container(color: const Color(0xFF2A211B)),
            ),
          ),
        ),
      );

  // L'éventail : couverture centrale droite, deux latérales inclinées derrière.
  Widget _fan(List<String> covers) {
    Widget at(int i, {required double angle, required Offset shift, double scale = 1}) {
      if (i >= covers.length) return const SizedBox.shrink();
      return Transform.translate(
        offset: shift,
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: _cover(covers[i])),
        ),
      );
    }
    return SizedBox(
      width: 148, height: 122,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        at(1, angle: -0.22, shift: const Offset(-31, 7), scale: 0.82),
        at(2, angle: 0.22, shift: const Offset(31, 7), scale: 0.82),
        at(0, angle: -0.045, shift: const Offset(0, -6)),
      ]),
    );
  }

  Widget _hero(List<String> covers) => Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(0.7, -1.0), radius: 1.4,
            colors: [Color(0xFF3A2E25), Color(0xFF1C1714)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 7))],
        ),
        child: Row(children: [
          _fan(covers),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NOS FASCICULES',
                  style: body(9.5, weight: FontWeight.w800, color: OC.o500).copyWith(letterSpacing: 0.13 * 9.5)),
              const SizedBox(height: 4),
              Text('La bibliothèque OnBuch',
                  style: display(18, weight: FontWeight.w800).copyWith(color: Colors.white, height: 1.05)),
              const SizedBox(height: 5),
              Text('Les bouquins complets — cours + exercices corrigés.',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(11.5, weight: FontWeight.w500).copyWith(color: const Color(0xFFD8CEC4), height: 1.3)),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.fromLTRB(13, 8, 11, 8),
                decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ouvrir', style: body(12.5, weight: FontWeight.w700).copyWith(color: Colors.white)),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ]),
              ),
            ]),
          ),
        ]),
      );

  // Repli (aucune couverture chargée) : bannière sombre simple, comme avant.
  Widget _plain() => Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.ink, OC.ink2],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nos fascicules', style: display(17, weight: FontWeight.w800).copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text('Les bouquins complets OnBuch — cours + exercices corrigés',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: body(11.5, weight: FontWeight.w500).copyWith(color: Colors.white70, height: 1.25)),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ]),
      );
}
