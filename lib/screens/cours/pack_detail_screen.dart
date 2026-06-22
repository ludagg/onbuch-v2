import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ── MOCK (valeurs/libellés EXACTS du wireframe — écran 4). Aucune API. ────────
const _kPack = (
  code: 'PC',
  name: 'Physique-Chimie · Tle D',
  meta: 'Programme MINESEC · 32 leçons',
  lessons: '32',
  videos: '14',
  quizzes: '8',
  coef: '3',
  tier: 'Premium',
  price: '800 F',
);

// preview=true → ✓ + APERÇU ; sinon numéro + cadenas.
const _kModules = <({String title, String lessons, bool preview, int n})>[
  (title: 'Mécanique', lessons: '6 leçons', preview: true, n: 1),
  (title: 'Électricité', lessons: '7 leçons', preview: true, n: 2),
  (title: 'Chimie organique', lessons: '9 leçons', preview: false, n: 3),
  (title: 'Solutions aqueuses', lessons: '10 leçons', preview: false, n: 4),
];

/// Détail d'un pack (fiche produit) — écran 4.
class PackDetailScreen extends StatelessWidget {
  const PackDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(slivers: [
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
              // En-tête : pastille + titre
              Row(children: [
                _avatar(_kPack.code, 48),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_kPack.name, style: display(19, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_kPack.meta, style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
                ])),
              ]),
              const SizedBox(height: 18),

              // Stats : 4 cases distinctes
              Row(children: [
                Expanded(child: _statBox(_kPack.lessons, 'Leçons')),
                const SizedBox(width: 9),
                Expanded(child: _statBox(_kPack.videos, 'Vidéos')),
                const SizedBox(width: 9),
                Expanded(child: _statBox(_kPack.quizzes, 'Quiz')),
                const SizedBox(width: 9),
                Expanded(child: _statBox(_kPack.coef, 'Coef', accent: true)),
              ]),
              const SizedBox(height: 20),

              Text('Au programme', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 10),
              for (final m in _kModules) _moduleRow(context, m),
            ]),
          ),
        ),
      ]),
      bottomSheet: _footer(context),
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

  Widget _moduleRow(BuildContext context, ({String title, String lessons, bool preview, int n}) m) {
    Widget leading = m.preview
        ? Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Icon(Icons.check_rounded, size: 17, color: OC.good),
          )
        : Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Text('${m.n}', style: body(13, weight: FontWeight.w800, color: OC.muted)),
          );
    return GestureDetector(
      onTap: m.preview ? () => context.push('/cours/lecon') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: body(13.5, weight: FontWeight.w700, color: m.preview ? OC.ink : OC.ink2)),
            const SizedBox(height: 2),
            Text(m.lessons, style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ])),
          if (m.preview)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(8)),
              child: Text('APERÇU', style: body(9.5, weight: FontWeight.w800, color: OC.o700).copyWith(letterSpacing: 0.3)),
            )
          else
            Icon(Icons.lock_outline_rounded, size: 17, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _footer(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_kPack.tier, style: body(11, color: OC.muted, weight: FontWeight.w700)),
            Text(_kPack.price, style: display(20, weight: FontWeight.w700, color: OC.o600)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: GestureDetector(
            onTap: () => context.push('/cours/panier'),
            child: Container(
              height: 52,
              decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text('+ Ajouter à ma bibliothèque', style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ),
          )),
        ]),
      );
}
