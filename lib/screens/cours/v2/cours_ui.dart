import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import 'cours_models.dart';

IconData matiereIcon(String matiere) {
  final m = matiere.toLowerCase();
  if (m.contains('phys')) return Icons.science_rounded;
  if (m.contains('chim')) return Icons.biotech_rounded;
  return Icons.calculate_rounded;
}

/// Vignette d'un pack (carré teinté à l'icône matière).
class MatiereThumb extends StatelessWidget {
  final String matiere;
  final double size;
  const MatiereThumb(this.matiere, {super.key, this.size = 52});
  @override
  Widget build(BuildContext context) {
    final c = matiereTint(matiere);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size * 0.26)),
      alignment: Alignment.center,
      child: Icon(matiereIcon(matiere), color: c, size: size * 0.46),
    );
  }
}

/// Carte-liste d'un pack (vignette + titre + 2 lignes méta + chevron).
class PackListCard extends StatelessWidget {
  final Pack pack;
  const PackListCard(this.pack, {super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/cours/detail/${pack.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          MatiereThumb(pack.matiere, size: 54),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(pack.titre, style: body(14.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (pack.premium) ...[const SizedBox(width: 6), const _PremiumDot()],
            ]),
            const SizedBox(height: 4),
            Text(pack.meta, style: body(11.5, color: OC.muted, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.star_rounded, size: 13, color: OC.o500),
              const SizedBox(width: 3),
              Text('${pack.note} · ${pack.dureeHeures}h de contenu', style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
            ]),
          ])),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 20, color: OC.faint),
        ]),
      ),
    );
  }
}

class _PremiumDot extends StatelessWidget {
  const _PremiumDot();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFFBF0DD), borderRadius: BorderRadius.circular(6)),
        child: Text('PREMIUM', style: body(8.5, weight: FontWeight.w800, color: const Color(0xFFA6701A)).copyWith(letterSpacing: 0.3)),
      );
}

/// Carte « formule » rendue en LaTeX (centrée).
class FormulaCard extends StatelessWidget {
  final String latex;
  const FormulaCard(this.latex, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
      alignment: Alignment.center,
      child: Math.tex(
        latex,
        textStyle: TextStyle(fontSize: 18, color: OC.ink),
        mathStyle: MathStyle.display,
        onErrorFallback: (_) => Text(latex, style: mono(14, color: OC.ink)),
      ),
    );
  }
}

/// Rendu LaTeX inline (énoncés d'exercices), avec repli texte.
class InlineMath extends StatelessWidget {
  final String latex;
  final double size;
  const InlineMath(this.latex, {super.key, this.size = 15});
  @override
  Widget build(BuildContext context) {
    return Math.tex(
      latex,
      textStyle: TextStyle(fontSize: size, color: OC.ink),
      onErrorFallback: (_) => Text(latex, style: mono(size - 1, color: OC.ink)),
    );
  }
}

/// Barre de recherche + bouton filtre (réutilisée Home / AllPacks).
class CoursSearchBar extends StatelessWidget {
  final String placeholder;
  final VoidCallback? onFilter;
  const CoursSearchBar({super.key, required this.placeholder, this.onFilter});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line2, width: 1.5)),
        child: Row(children: [
          Icon(Icons.search_rounded, size: 18, color: OC.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(placeholder, style: body(13, color: OC.muted, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      )),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: onFilter,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line2, width: 1.5)),
          child: Icon(Icons.tune_rounded, size: 19, color: OC.ink),
        ),
      ),
    ]);
  }
}

/// Petit en-tête de section avec lien « Voir tout ».
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader(this.title, {super.key, this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: display(16, weight: FontWeight.w700)),
      if (onSeeAll != null)
        GestureDetector(onTap: onSeeAll, child: Text('Voir tout', style: body(12.5, weight: FontWeight.w700, color: OC.o600))),
    ]);
  }
}
