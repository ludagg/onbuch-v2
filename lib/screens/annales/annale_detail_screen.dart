import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class AnnaleDetailScreen extends StatelessWidget {
  const AnnaleDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mathématiques', style: display(17, weight: FontWeight.w700)),
          Text('Bac D · 2025', style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/annales/folder/Baccalauréat'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border_rounded, size: 19), color: OC.ink2, onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: OC.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OC.line, width: 1.5),
            ),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: const Center(child: Icon(Icons.description_outlined, size: 60, color: OC.faint)),
              ),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.72), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text('4 h · coef 4', style: body(11, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
              Positioned(right: 12, bottom: 12,
                child: GestureDetector(
                  onTap: () => context.go('/annales/pdf'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.16), blurRadius: 10)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.visibility_outlined, size: 17, color: OC.ink),
                      const SizedBox(width: 7),
                      Text('Ouvrir le PDF', style: body(12.5, weight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 15),

          // Resource tabs
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/annales/pdf'),
                child: _ResourceTab(icon: Icons.picture_as_pdf_rounded, label: 'Sujet', sub: 'PDF',
                    iconC: const Color(0xFFC0392B), iconBg: const Color(0xFFFAE7E4), selected: true),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _ResourceTab(icon: Icons.check_circle_outline_rounded, label: 'Corrigé', sub: 'Texte',
                  iconC: OC.good, iconBg: OC.goodBg),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/annales/video'),
                child: _ResourceTab(icon: Icons.play_circle_outline_rounded, label: 'Vidéo', sub: '8 min',
                    iconC: const Color(0xFF7A5AE0), iconBg: const Color(0xFFEEE9FA)),
              ),
            ),
          ]),
          const SizedBox(height: 15),

          // Tuteur bridge
          GestureDetector(
            onTap: () => context.go('/tutor'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OC.o50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OC.o100, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bloqué·e sur un exercice ?', style: body(14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Corrige-le pas-à-pas avec le Tuteur IA', style: body(12, color: OC.o700, weight: FontWeight.w500)),
                ])),
                const Icon(Icons.chevron_right_rounded, size: 20, color: OC.o600),
              ]),
            ),
          ),
          const SizedBox(height: 15),

          // Corrigés list
          Text('Corrigés · 4 exercices', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          ...[
            ('Exercice 1 — Nombres complexes', true, true),
            ('Exercice 2 — Probabilités', true, false),
            ('Exercice 3 — Fonctions', false, false),
            ('Problème — Étude de fonction', false, true),
          ].map((c) => Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OC.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OC.line, width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: c.$2 ? OC.goodBg : OC.panel,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c.$2 ? Icons.article_outlined : Icons.lock_outline_rounded,
                    size: 17, color: c.$2 ? OC.waInk : OC.muted),
              ),
              const SizedBox(width: 12),
              Expanded(child: Row(children: [
                Expanded(child: Text(c.$1, style: body(13.5, weight: FontWeight.w700, color: c.$2 ? OC.ink : OC.ink2))),
                if (c.$3) const Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: Icon(Icons.play_circle_outline_rounded, size: 14, color: Color(0xFF7A5AE0)),
                ),
              ])),
              c.$2
                  ? const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted)
                  : Text('Premium', style: body(10.5, weight: FontWeight.w800, color: Color(0xFFA6701A))),
            ]),
          )),
          const SizedBox(height: 4),

          // Unlock
          Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2A2238), Color(0xFF171019)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Débloquer tous les corrigés · 500 F', style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ResourceTab extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color iconC, iconBg;
  final bool selected;
  const _ResourceTab({required this.icon, required this.label, required this.sub,
      required this.iconC, required this.iconBg, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? OC.line2 : OC.line, width: 1.5),
      ),
      child: Column(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: iconC, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: body(12.5, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sub, style: body(10, color: OC.muted, weight: FontWeight.w600)),
      ]),
    );
  }
}
