import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// État vide réutilisable (icône en pastille + titre + sous-titre + CTA option).
/// Uniformise les écrans sans données.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(32, 60, 32, 40),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(color: OC.o50, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: OC.o500),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: display(18, weight: FontWeight.w700)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center,
                style: body(13.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.45)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onAction,
              child: Container(
                height: 46, padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(actionLabel!, style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// État d'erreur réutilisable, avec bouton « Réessayer ».
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final EdgeInsets padding;
  const ErrorState({
    super.key,
    this.message = 'Une erreur est survenue.',
    this.onRetry,
    this.padding = const EdgeInsets.fromLTRB(32, 50, 32, 40),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: OC.badBg, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, size: 32, color: OC.bad),
          ),
          const SizedBox(height: 14),
          Text('Oups', style: display(18, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center,
              style: body(13.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.45)),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                height: 46, padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Réessayer', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Apparition douce (fondu + léger glissement) au montage, avec délai indexé
/// pour un effet « cascade » sur les listes. Joué une seule fois.
class Appear extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double offsetY;
  const Appear({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 340),
    this.offsetY = 14,
  });

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index.clamp(0, 12)) * 55);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, widget.offsetY * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}
