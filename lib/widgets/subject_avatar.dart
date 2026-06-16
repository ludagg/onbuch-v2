import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastille colorée à initiales pour une matière normalisée (cf. categorize.ts).
class SubjectAvatar extends StatelessWidget {
  final String? subject;
  final double size;
  const SubjectAvatar(this.subject, {super.key, this.size = 44});

  // matière normalisée → (abréviation, couleur, fond)
  static const Map<String, (String, Color, Color)> _map = {
    'Mathématiques': ('Ma', Color(0xFF2D6CDF), Color(0xFFE7EEFB)),
    'Physique': ('Phy', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
    'Chimie': ('Chi', Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
    'Physique-Chimie-Tech': ('PCT', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
    'SVT': ('SVT', Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
    'Informatique': ('Inf', Color(0xFF5B5BD6), Color(0xFFEAEAFB)),
    'Français': ('Fr', Color(0xFFDB4F12), Color(0xFFFDEBE2)),
    'Anglais': ('An', Color(0xFFC0392B), Color(0xFFFAE7E4)),
    'Allemand': ('Al', Color(0xFF8B5E3C), Color(0xFFF1E7DD)),
    'Espagnol': ('Es', Color(0xFFD68910), Color(0xFFFBF0DD)),
    'Histoire': ('His', Color(0xFFA6651E), Color(0xFFF6ECDC)),
    'Géographie': ('Géo', Color(0xFF1E7A6B), Color(0xFFE0F0EC)),
    'ECM': ('ECM', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
    'Philosophie': ('Phi', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
    'Économie': ('Éco', Color(0xFF2D6CDF), Color(0xFFE7EEFB)),
    'Comptabilité-Gestion': ('Cpt', Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
    'Enseignement technique': ('Tec', Color(0xFF5B5048), Color(0xFFEFE8E1)),
    'Langues nationales': ('LCN', Color(0xFFA6651E), Color(0xFFF6ECDC)),
    'EPS': ('EPS', Color(0xFF1E9E63), Color(0xFFE5F3EB)),
  };

  @override
  Widget build(BuildContext context) {
    final m = _map[subject] ?? ('Doc', OC.ink2, OC.panel);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: m.$3, borderRadius: BorderRadius.circular(size * 0.29)),
      child: Center(
        child: Text(m.$1, style: display(size * 0.30, weight: FontWeight.w700, color: m.$2)),
      ),
    );
  }
}
