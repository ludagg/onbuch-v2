// Shared UI primitives for OnBuch V2
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Wordmark ─────────────────────────────────────────────────────────────────
class OBWordmark extends StatelessWidget {
  final double size;
  final bool light;
  const OBWordmark({super.key, this.size = 22, this.light = false});

  @override
  Widget build(BuildContext context) {
    final base = light ? Colors.white : OC.ink;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'On',
            style: display(size, weight: FontWeight.w800, color: base),
          ),
          TextSpan(
            text: 'Buch',
            style: display(size, weight: FontWeight.w800, color: light ? Colors.white : OC.o500),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient text helper ─────────────────────────────────────────────────────
class GradText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (b) => OC.grad.createShader(b),
        child: Text(text, style: style),
      );
}

// ─── Primary button ───────────────────────────────────────────────────────────
class OBButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final OBButtonKind kind;
  final IconData? icon;
  final bool expand;
  const OBButton(
    this.label, {
    super.key,
    this.onTap,
    this.kind = OBButtonKind.primary,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = kind == OBButtonKind.primary;
    final isWa = kind == OBButtonKind.wa;
    final isOutline = kind == OBButtonKind.outline;

    Color fg;
    BoxDecoration? dec;

    if (isPrimary) {
      fg = Colors.white;
      dec = BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFB347), OC.o500, OC.o600]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
      );
    } else if (isWa) {
      fg = Colors.white;
      dec = BoxDecoration(
        color: OC.wa,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: OC.wa.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
      );
    } else if (isOutline) {
      fg = OC.ink;
      dec = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line2, width: 1.5),
      );
    } else {
      fg = OC.o700;
      dec = BoxDecoration(
        color: OC.o50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.o100, width: 1.5),
      );
    }

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
        Text(label, style: body(14, weight: FontWeight.w700, color: fg)),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: dec,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    );
  }
}

enum OBButtonKind { primary, outline, wa, soft }

// ─── Chip ─────────────────────────────────────────────────────────────────────
class OBChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  const OBChip(this.label, {super.key, this.active = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: active ? OC.o50 : OC.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? OC.o500 : OC.line2, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: active ? OC.o600 : OC.ink2), const SizedBox(width: 5)],
          Text(label, style: body(13, weight: FontWeight.w700, color: active ? OC.o700 : OC.ink2)),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class SecHead extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? action;
  const SecHead({super.key, required this.title, this.eyebrow, this.action = 'Voir tout'});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!.toUpperCase(),
                  style: body(10.5, weight: FontWeight.w800, color: OC.o600)
                      .copyWith(letterSpacing: 0.12 * 10.5),
                ),
              if (eyebrow != null) const SizedBox(height: 5),
              Text(title, style: display(18, weight: FontWeight.w700)),
            ],
          ),
        ),
        if (action != null)
          Row(children: [
            Text(action!, style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
            const Icon(Icons.chevron_right, size: 15, color: OC.ink2),
          ]),
      ],
    );
  }
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────
class OBCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const OBCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OC.line, width: 1.5),
        boxShadow: [
          BoxShadow(color: OC.ink.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(color: OC.ink.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

// ─── Input field ──────────────────────────────────────────────────────────────
class OBField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final IconData? icon;
  final Widget? trailing;
  final bool focused;
  const OBField({
    super.key,
    required this.label,
    this.placeholder,
    this.icon,
    this.trailing,
    this.focused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: body(12, weight: FontWeight.w700, color: OC.ink2)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: OC.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: focused ? OC.o500 : OC.line2, width: focused ? 2 : 1.5),
            boxShadow: focused
                ? [BoxShadow(color: OC.o500.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: focused ? OC.o500 : OC.muted), const SizedBox(width: 10)],
              Expanded(
                child: Text(
                  placeholder ?? '',
                  style: body(14.5, color: placeholder != null ? OC.ink : OC.muted),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Bottom navigation bar (Pill style — variant B) ──────────────────────────
class OBNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const OBNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _tabs = [
    _NavTab(icon: Icons.dashboard_rounded, label: 'Tableau'),
    _NavTab(icon: Icons.description_outlined, label: 'Résultats'),
    _NavTab(icon: Icons.auto_awesome_rounded, label: 'Tuteur'),
    _NavTab(icon: Icons.menu_book_rounded, label: 'Annales'),
    _NavTab(icon: Icons.play_lesson_rounded, label: 'Cours'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OC.paper,
        border: Border(top: BorderSide(color: OC.line, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final on = i == currentIndex;
              final tab = _tabs[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      height: 30,
                      decoration: BoxDecoration(
                        color: on ? OC.o50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: on ? OC.o100 : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(tab.icon, size: 22, color: on ? OC.o600 : OC.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tab.label,
                      style: body(10.5, weight: on ? FontWeight.w700 : FontWeight.w600, color: on ? OC.o700 : OC.muted),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab({required this.icon, required this.label});
}

// ─── OTP Row ──────────────────────────────────────────────────────────────────
class OTPRow extends StatelessWidget {
  const OTPRow({super.key});

  @override
  Widget build(BuildContext context) {
    final digits = ['1', '2', '4', '', '', ''];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        final filled = digits[i].isNotEmpty;
        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: OC.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: i == 3 ? OC.o500 : OC.line2, width: i == 3 ? 2 : 1.5),
            boxShadow: i == 3
                ? [BoxShadow(color: OC.o500.withOpacity(0.14), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: filled
                ? Text(digits[i], style: display(24, weight: FontWeight.w700))
                : i == 3
                    ? Container(width: 2, height: 22, color: OC.o500)
                    : null,
          ),
        );
      }),
    );
  }
}

// ─── Progress dots ────────────────────────────────────────────────────────────
class ProgressDots extends StatelessWidget {
  final int count;
  final int active;
  const ProgressDots({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: on ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: on ? OC.o500 : OC.o100,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Subject tile (colored initials) ─────────────────────────────────────────
class SubjTile extends StatelessWidget {
  final String subject;
  final double size;
  const SubjTile(this.subject, {super.key, this.size = 48});

  static const _map = {
    'Maths':      ['Ma', Color(0xFF2D6CDF), Color(0xFFE7EEFB)],
    'Phys-Chimie':['PC', Color(0xFF1E9E63), Color(0xFFE5F3EB)],
    'Philo':      ['Ph', Color(0xFF7A5AE0), Color(0xFFEEE9FA)],
    'SVT':        ['SV', Color(0xFF0E9AA0), Color(0xFFE1F2F2)],
    'Français':   ['Fr', Color(0xFFDB4F12), Color(0xFFFDEBE2)],
    'Hist-Géo':   ['HG', Color(0xFFA6651E), Color(0xFFF6ECDC)],
    'Anglais':    ['An', Color(0xFFC0392B), Color(0xFFFAE7E4)],
  };

  @override
  Widget build(BuildContext context) {
    final s = _map[subject] ?? _map['Maths']!;
    final abbr = s[0] as String;
    final c = s[1] as Color;
    final bg = s[2] as Color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.29)),
      child: Center(
        child: Text(abbr, style: display(size * 0.36, weight: FontWeight.w700, color: c)),
      ),
    );
  }
}

// ─── Dot separator ────────────────────────────────────────────────────────────
class HRule extends StatelessWidget {
  const HRule({super.key});

  @override
  Widget build(BuildContext context) => Container(height: 1.5, color: OC.line);
}

// ─── Status-like pill badge ───────────────────────────────────────────────────
class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  const PillBadge(this.label, {super.key, required this.color, required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: body(11, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
