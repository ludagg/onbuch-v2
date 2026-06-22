import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bloc « squelette » animé (pulsation douce) pour les états de chargement.
/// Léger : un seul [AnimationController] par bloc, pas de shader coûteux —
/// adapté aux téléphones bas de gamme.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsets margin;
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.margin = EdgeInsets.zero,
  });

  /// Cercle (avatar, anneau…).
  const Skeleton.circle({super.key, double size = 44, this.margin = EdgeInsets.zero})
      : width = size,
        height = size,
        radius = size;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final color = Color.lerp(OC.panel, OC.line, t)!;
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(widget.radius)),
        );
      },
    );
  }
}

/// Carte squelette générique (avatar + 2 lignes), pour les listes.
class SkeletonRow extends StatelessWidget {
  final double height;
  const SkeletonRow({super.key, this.height = 66});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Row(children: [
        const Skeleton.circle(size: 42),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Skeleton(width: 160, height: 13),
          SizedBox(height: 8),
          Skeleton(width: 100, height: 11),
        ])),
      ]),
    );
  }
}

/// Plusieurs [SkeletonRow] empilées.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) =>
      Column(children: List.generate(count, (_) => const SkeletonRow()));
}

/// Ligne squelette avec vignette à gauche (actualités, annales…).
class SkeletonMediaRow extends StatelessWidget {
  final double height;
  const SkeletonMediaRow({super.key, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Skeleton(width: 96, height: height, radius: 0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: const [
              Skeleton(width: 64, height: 14, radius: 7),
              SizedBox(height: 9),
              Skeleton(width: double.infinity, height: 12),
              SizedBox(height: 7),
              Skeleton(width: 150, height: 10),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Carte squelette « média » : visuel en haut + deux lignes (affiche, héros…).
class SkeletonCard extends StatelessWidget {
  final double imageHeight;
  const SkeletonCard({super.key, this.imageHeight = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Skeleton(width: double.infinity, height: imageHeight, radius: 0),
        Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Skeleton(width: 90, height: 14, radius: 7),
            SizedBox(height: 9),
            Skeleton(width: double.infinity, height: 13),
            SizedBox(height: 8),
            Skeleton(width: 160, height: 11),
          ]),
        ),
      ]),
    );
  }
}
