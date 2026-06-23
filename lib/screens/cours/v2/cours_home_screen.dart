import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import 'cours_models.dart';
import 'cours_ui.dart';

/// Écran principal de la section Cours (Packs → Détail → Chapitre).
class CoursHomeScreen extends StatefulWidget {
  const CoursHomeScreen({super.key});
  @override
  State<CoursHomeScreen> createState() => _CoursHomeScreenState();
}

class _CoursHomeScreenState extends State<CoursHomeScreen> {
  final Set<String> _cats = {};

  IconData _catIcon(String c) {
    switch (c) {
      case 'Bac C': return Icons.workspace_premium_rounded;
      case 'Première': return Icons.looks_one_rounded;
      case 'Terminale': return Icons.looks_two_rounded;
      case 'Maths': return Icons.calculate_rounded;
      case 'Physique': return Icons.science_rounded;
      case 'Chimie': return Icons.biotech_rounded;
      default: return Icons.label_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final featured = kPacks.firstWhere((p) => p.populaire, orElse: () => kPacks.first);
    final others = [packById('phys_tc'), packById('chimie_p')].whereType<Pack>().toList();
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Text('Cours', style: display(22, weight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: OC.ink),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text('Trouve le pack qu\'il te faut et progresse à ton rythme.',
              style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 16),
          CoursSearchBar(placeholder: 'Rechercher un cours, un chapitre...', onFilter: () => context.push('/cours/tous-les-packs')),
          const SizedBox(height: 22),

          // Catégories
          SectionHeader('Catégories', onSeeAll: () => context.push('/cours/tous-les-packs')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [for (final c in kCategories) _catChip(c)],
          ),
          const SizedBox(height: 24),

          // Packs populaires
          SectionHeader('Packs populaires', onSeeAll: () => context.push('/cours/tous-les-packs')),
          const SizedBox(height: 12),
          _featuredCard(context, featured),
          const SizedBox(height: 24),

          // Tous les packs
          SectionHeader('Tous les packs', onSeeAll: () => context.push('/cours/tous-les-packs')),
          const SizedBox(height: 12),
          for (final p in others) PackListCard(p),
        ],
      ),
    );
  }

  Widget _catChip(String c) {
    final on = _cats.contains(c);
    return GestureDetector(
      onTap: () => setState(() => on ? _cats.remove(c) : _cats.add(c)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: on ? OC.o50 : OC.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_catIcon(c), size: 15, color: on ? OC.o600 : OC.muted),
          const SizedBox(width: 6),
          Text(c, style: body(12.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
        ]),
      ),
    );
  }

  Widget _featuredCard(BuildContext context, Pack p) {
    final tint = matiereTint(p.matiere);
    return GestureDetector(
      onTap: () => context.push('/cours/detail/${p.id}'),
      child: Container(
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: OC.line, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Bandeau couverture
          Container(
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [tint.withValues(alpha: 0.16), OC.paper]),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (p.populaire)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('POPULAIRE', style: body(9, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.4)),
                  ]),
                ),
              const Spacer(),
              MatiereThumb(p.matiere, size: 48),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.titre, style: display(18, weight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(p.meta, style: body(12, color: OC.muted, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: p.progressionPct, minHeight: 7, backgroundColor: OC.line, valueColor: const AlwaysStoppedAnimation(OC.o500)),
                )),
                const SizedBox(width: 10),
                Text('${(p.progressionPct * 100).round()}%', style: body(12.5, weight: FontWeight.w800, color: OC.o700)),
              ]),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push('/cours/detail/${p.id}'),
                child: Container(
                  height: 46, width: double.infinity,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text('Continuer', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
