// Shared UI primitives for OnBuch V2
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_globals.dart';
import '../theme/app_theme.dart';
import '../services/notifications_service.dart';

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
        gradient: LinearGradient(colors: [Color(0xFFFFB347), OC.o500, OC.o600]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
      );
    } else if (isWa) {
      fg = Colors.white;
      dec = BoxDecoration(
        color: OC.wa,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: OC.wa.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
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

// ─── Style de catégorie d'article (accent + teinte) ──────────────────────────
class CatStyle {
  final Color accent, tint;
  const CatStyle(this.accent, this.tint);
}

CatStyle categoryStyle(String category) {
  switch (category.toLowerCase()) {
    case 'examens':
      return CatStyle(OC.o600, OC.o50);
    case 'bourses':
      return CatStyle(OC.blue, OC.blueBg);
    case 'conseil':
      return CatStyle(OC.waInk, OC.goodBg);
    case 'concours':
      return CatStyle(OC.blue, OC.blueBg);
    case 'alerte':
      return CatStyle(OC.bad, OC.badBg);
    default:
      return CatStyle(OC.o600, OC.o50);
  }
}

/// Horodatage relatif court en français ("il y a 2 h", "hier"…).
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  if (diff.inDays < 35) return 'il y a ${(diff.inDays / 7).floor()} sem';
  return 'il y a ${(diff.inDays / 30).floor()} mois';
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
            Icon(Icons.chevron_right, size: 15, color: OC.ink2),
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
          BoxShadow(color: OC.ink.withValues(alpha:0.04), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(color: OC.ink.withValues(alpha:0.05), blurRadius: 14, offset: const Offset(0, 6)),
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
                ? [BoxShadow(color: OC.o500.withValues(alpha:0.12), blurRadius: 8, offset: const Offset(0, 3))]
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
    _NavTab(icon: Icons.dashboard_rounded, label: 'Accueil'),
    _NavTab(icon: Icons.play_lesson_rounded, label: 'Cours'),
    _NavTab(icon: Icons.auto_awesome_rounded, label: 'Tuteur'),
    _NavTab(icon: Icons.menu_book_rounded, label: 'Annales'),
    _NavTab(icon: Icons.track_changes_rounded, label: 'Concours'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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

// ─── Actions standard de la barre supérieure (cloche + profil + menu) ────────
/// À mettre dans `AppBar.actions` / `SliverAppBar.actions` pour avoir la même
/// barre du haut sur toutes les pages.
List<Widget> obTopActions(BuildContext context, {bool showProfile = true}) {
  return [
    const _NotifBell(),
    if (showProfile)
      GestureDetector(
        onTap: () => context.go('/profile'),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: OC.line2, width: 1.5),
          ),
          child: Icon(Icons.person_outline_rounded, size: 22, color: OC.ink),
        ),
      ),
    const SizedBox(width: 10),
    const Padding(padding: EdgeInsets.only(right: 12), child: OBTopMenu()),
  ];
}

/// Cloche de notifications : ouvre le centre de notifications et affiche une
/// pastille tant qu'il reste des notifications non lues.
class _NotifBell extends StatefulWidget {
  const _NotifBell();

  @override
  State<_NotifBell> createState() => _NotifBellState();
}

class _NotifBellState extends State<_NotifBell> {
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final unread = await NotificationsService().hasUnread();
    if (mounted && unread != _hasUnread) setState(() => _hasUnread = unread);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined, size: 23),
        color: OC.ink,
        onPressed: () async {
          await context.push('/notifications');
          _refresh(); // met à jour la pastille au retour
        },
      ),
      if (_hasUnread)
        Positioned(
          top: 10, right: 10,
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: OC.o500,
              shape: BoxShape.circle,
              border: Border.all(color: OC.bg, width: 1.5),
            ),
          ),
        ),
    ]);
  }
}

/// AppBar simple avec bouton retour, pour les sous-pages (menu, détails…).
PreferredSizeWidget obBackAppBar(BuildContext context, String title) => AppBar(
      title: Text(title, style: display(17, weight: FontWeight.w700)),
      backgroundColor: OC.bg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
    );

// ─── Top overflow menu (popup ancré sous le bouton) ──────────────────────────
class OBMenuEntry {
  final IconData icon;
  final String label;
  final String? route; // null = pas encore disponible
  const OBMenuEntry(this.icon, this.label, [this.route]);
}

/// Bouton hamburger de la barre supérieure : ouvre le tiroir latéral (menu)
/// de la coque principale (MainShell), via `shellScaffoldKey`.
class OBTopMenu extends StatelessWidget {
  const OBTopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => shellScaffoldKey.currentState?.openEndDrawer(),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: OC.line2, width: 1.5),
        ),
        child: Icon(Icons.menu_rounded, size: 21, color: OC.ink),
      ),
    );
  }
}

/// Tiroir latéral (menu hamburger) de la coque principale.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _entries = [
    OBMenuEntry(Icons.person_outline_rounded, 'Mon profil', '/profile'),
    OBMenuEntry(Icons.event_note_rounded, 'Campus & agenda', '/campus'),
    OBMenuEntry(Icons.paid_outlined, 'Crédits', '/credits'),
    OBMenuEntry(Icons.groups_rounded, 'Communauté', '/communaute'),
    OBMenuEntry(Icons.settings_outlined, 'Paramètres', '/parametres'),
    OBMenuEntry(Icons.help_outline_rounded, 'Aide & support', '/aide'),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: OC.bg,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
            child: Row(children: [
              const OBWordmark(size: 22),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => shellScaffoldKey.currentState?.closeEndDrawer(),
                child: Container(
                  width: 34, height: 34, alignment: Alignment.center,
                  decoration: BoxDecoration(color: OC.paper, shape: BoxShape.circle, border: Border.all(color: OC.line2, width: 1.5)),
                  child: Icon(Icons.close_rounded, size: 18, color: OC.ink2),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [for (final e in _entries) _row(context, e)],
            ),
          ),
          Divider(height: 1, thickness: 1, color: OC.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text('OnBuch 1.0.0', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, OBMenuEntry e) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        shellScaffoldKey.currentState?.closeEndDrawer();
        if (e.route != null) {
          context.push(e.route!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(children: [
          Container(
            width: 38, height: 38, alignment: Alignment.center,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
            child: Icon(e.icon, size: 19, color: OC.o600),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(e.label, style: body(14, weight: FontWeight.w700, color: OC.ink))),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
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
                ? [BoxShadow(color: OC.o500.withValues(alpha:0.14), blurRadius: 8)]
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

// ─── Logo de matière (icône adaptée + couleur) ─────────────────────────────────
// Mappe n'importe quel nom de matière (FR/EN) vers une icône Material et une
// couleur d'accent. Utilisé par la bibliothèque d'annales (matières réelles par
// série). Le fond est dérivé de l'accent (stable en mode sombre, accents fixes).
class SubjLogo extends StatelessWidget {
  final String subject;
  final double size;
  const SubjLogo(this.subject, {super.key, this.size = 40});

  static (IconData, Color) visual(String name) {
    final n = name.toLowerCase();
    bool has(List<String> ks) => ks.any(n.contains);

    // Santé / médical (avant « phys » pour ne pas confondre physiologie/physique).
    if (has(['anatom', 'physiolog', 'soin', 'pharmac', 'clinique', 'nursing', 'infirm',
        'médic', 'medic', 'santé', 'sante', 'sanitaire', 'haemat', 'hématolog', 'hematolog'])) {
      return (Icons.local_hospital_rounded, const Color(0xFFC0392B));
    }
    if (n.contains('phys') && (n.contains('chim') || n.contains('chem'))) return (Icons.science_rounded, const Color(0xFF1E9E63));
    if (n.contains('math')) return (Icons.calculate_rounded, const Color(0xFF2D6CDF));
    if (n.contains('phys')) return (Icons.bolt_rounded, const Color(0xFF4257B2));
    if (has(['chim', 'chem'])) return (Icons.science_rounded, const Color(0xFF1E9E63));
    if (has(['svt', 'biolog', 'biochim', 'micro', ' vie', 'nature'])) return (Icons.biotech_rounded, const Color(0xFF0E9AA0));
    // Agriculture / élevage (avant « techn » pour zootechnie, phytotechnie).
    if (has(['agri', 'agro', 'aqua', 'zoo', 'phyto', 'végétal', 'animal', 'crop', 'fish', 'élevage'])) {
      return (Icons.agriculture_rounded, const Color(0xFF558B2F));
    }
    if (has(['philo', 'logic', 'logique'])) return (Icons.psychology_rounded, const Color(0xFF7A5AE0));
    if (has(['litt', 'liter', 'religi'])) return (Icons.auto_stories_rounded, const Color(0xFFB23E8E));
    if (has(['culture g'])) return (Icons.lightbulb_rounded, const Color(0xFF7A5AE0));
    if (has(['franç', 'francais', 'lettre', 'rédaction', 'redaction'])) return (Icons.menu_book_rounded, const Color(0xFFDB4F12));
    if (has(['angl', 'english', 'bilingual'])) return (Icons.translate_rounded, const Color(0xFFC0392B));
    if (has(['lv2', 'lv3', 'espagnol', 'allemand', 'latin', 'grec', 'langue', 'french'])) {
      return (Icons.language_rounded, const Color(0xFFC0392B));
    }
    if (n.contains('hist')) return (Icons.account_balance_rounded, const Color(0xFFA6651E));
    if (has(['géo', 'geo', 'topo', 'survey', 'cartograph'])) return (Icons.public_rounded, const Color(0xFF1E7E5A));
    if (has(['ecm', 'citoyen', 'citizen', 'moral'])) return (Icons.diversity_3_rounded, const Color(0xFF00897B));
    if (has(['info', 'numér', 'ict', 'logiciel', 'software', 'réseau', 'reseau', 'network', 'comput',
        'programm', 'algorith', 'données', 'database', 'embarqué', 'embedded', 'operating', 'télécom', 'telecom', 'transmission'])) {
      return (Icons.computer_rounded, const Color(0xFF3F51B5));
    }
    if (has(['droit', 'fiscal', ' law', 'légal', 'legal'])) return (Icons.gavel_rounded, const Color(0xFF6D4C41));
    if (has(['dessin', 'drawing'])) return (Icons.architecture_rounded, const Color(0xFF6D4C41));
    if (has(['électro', 'electro', 'électr', 'electr', 'mesur', 'power', 'machine élec'])) {
      return (Icons.electric_bolt_rounded, const Color(0xFFEF6C00));
    }
    if (has(['froid', 'clim', 'thermo', 'refriger', 'hvac'])) return (Icons.ac_unit_rounded, const Color(0xFF0277BD));
    if (has(['méca', 'meca', 'mecha', 'fabric', 'automat', 'mainten', 'usinage', 'manufactur', 'productique'])) {
      return (Icons.settings_rounded, const Color(0xFF455A64));
    }
    if (has(['génie civ', 'béton', 'beton', 'concrete', 'construct', 'bâtiment', 'batiment', 'building',
        'résistance', 'resistance', 'structural', 'ouvrage'])) {
      return (Icons.architecture_rounded, const Color(0xFF6D4C41));
    }
    if (has(['génie', 'genie', 'technolog', 'industr', 'engineering', 'procédé', 'process'])) {
      return (Icons.engineering_rounded, const Color(0xFF455A64));
    }
    if (has(['hôtel', 'hotel', 'restaur', 'cuisine', 'culinaire', 'catering', 'hospitality', 'nutrition', 'food', 'aliment'])) {
      return (Icons.restaurant_rounded, const Color(0xFFC2185B));
    }
    if (has(['compta', 'account', 'financ', 'banqu', 'banking', 'gestion', 'manage', 'mercat', 'marketing',
        'commerc', 'commerce', 'vente', 'sales', 'éco', 'eco', 'econom', 'assur', 'insurance', 'entrep',
        'logist', 'supply', 'procure', 'transport', 'bancaire', 'business'])) {
      return (Icons.trending_up_rounded, const Color(0xFF2E7D32));
    }
    if (has(['admin', 'organis', 'communic', 'secrét', 'secret', 'bureau', 'office', 'sténo', 'steno',
        'dactylo', 'correspond', 'relation', 'public relation'])) {
      return (Icons.badge_rounded, const Color(0xFF5E35B1));
    }
    if (has(['sécur', 'secur', 'prévention', 'prevention', 'hygiène', 'hygiene', 'safety'])) {
      return (Icons.health_and_safety_rounded, const Color(0xFF00897B));
    }
    if (has(['travaux', 'pratiq', 'practical', 'atelier', 'usinage', 'soudure', 'chaudronn', 'confection', 'couture'])) {
      return (Icons.handyman_rounded, const Color(0xFF8D6E63));
    }
    if (has(['projet', 'project', 'étude de cas', 'etude de cas', 'research', 'synthèse', 'synthese', 'mémoire', 'memoire'])) {
      return (Icons.assignment_rounded, const Color(0xFF455A64));
    }
    if (has(['dissert'])) return (Icons.edit_note_rounded, const Color(0xFF5E35B1));
    if (n.contains('social')) return (Icons.groups_rounded, const Color(0xFF00838F));
    if (has(['art', 'musi', 'dessin'])) return (Icons.palette_rounded, const Color(0xFFB23E8E));
    if (has(['bois', 'wood', 'menuis', 'ébénist', 'ebenist'])) return (Icons.carpenter_rounded, const Color(0xFF8D6E63));
    if (has(['sport', 'eps'])) return (Icons.fitness_center_rounded, const Color(0xFFD84315));
    return (Icons.description_rounded, const Color(0xFF6B7280));
  }

  @override
  Widget build(BuildContext context) {
    final (icon, c) = visual(subject);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(size * 0.29)),
      child: Icon(icon, size: size * 0.52, color: c),
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

// ─── Anneau de progression réutilisable ───────────────────────────────────────
class OBRing extends StatelessWidget {
  final double pct; // 0..1
  final double size;
  final Color color;
  final Color? track; // défaut résolu au build (OC.line dépend du thème)
  final Widget? center;
  const OBRing({super.key, required this.pct, this.size = 40, this.color = OC.o500, this.track, this.center});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(size), painter: _OBRingPainter(pct.clamp(0.0, 1.0), color, track ?? OC.line)),
        if (center != null) center!,
      ]),
    );
  }
}

class _OBRingPainter extends CustomPainter {
  final double pct;
  final Color color, track;
  _OBRingPainter(this.pct, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final bg = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track;
    final fg = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bg);
    if (pct > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false, fg);
  }

  @override
  bool shouldRepaint(covariant _OBRingPainter old) => old.pct != pct || old.color != color || old.track != track;
}
