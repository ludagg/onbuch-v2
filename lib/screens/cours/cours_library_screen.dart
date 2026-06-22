import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

// ── MOCK (valeurs/libellés EXACTS du wireframe — écran 5). Aucune API. ────────
const _kResume = (pct: 0.42, lesson: 'Forme exponentielle', sub: 'Maths · ch. 3/7');

const _kPacks = <({String code, String name, String trailing, bool premium, double pct})>[
  (code: 'Ma', name: 'Maths · Tle D', trailing: '38 leçons', premium: false, pct: 0.42),
  (code: 'Ph', name: 'Philosophie', trailing: '20 leçons', premium: false, pct: 0.10),
  (code: 'PC', name: 'Physique-Chimie', trailing: 'Premium ✓', premium: true, pct: 0.0),
];

const _kAddMore = 'SVT, Anglais…';

/// Ma bibliothèque (« Mes cours ») — écran 5.
class CoursLibraryScreen extends StatelessWidget {
  const CoursLibraryScreen({super.key});

  void _toCatalogue(BuildContext context) => context.canPop() ? context.pop() : context.go('/cours');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mes cours', style: display(18, weight: FontWeight.w700)),
          Text('Bac · Série D', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _toCatalogue(context),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(11), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  Icon(Icons.add_rounded, size: 16, color: OC.o600),
                  const SizedBox(width: 4),
                  Text('Packs', style: body(12.5, weight: FontWeight.w700, color: OC.ink)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _resumeCard(context),
          const SizedBox(height: 22),
          Text('Packs ajoutés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          for (final p in _kPacks) _packRow(context, p),
          const SizedBox(height: 6),
          _addMoreRow(context),
        ],
      ),
    );
  }

  Widget _resumeCard(BuildContext context) => GestureDetector(
        onTap: () => context.push('/cours/lecon'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.o50, OC.paper]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OC.o100, width: 1.5),
          ),
          child: Row(children: [
            SizedBox(
              width: 48, height: 48,
              child: OBRing(pct: _kResume.pct, size: 48, color: OC.o500,
                  center: Text('${(_kResume.pct * 100).round()}%', style: body(11, weight: FontWeight.w800, color: OC.o700))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reprendre : ${_kResume.lesson}', maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14.5, weight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(_kResume.sub, style: body(12, weight: FontWeight.w600, color: OC.muted)),
            ])),
            const SizedBox(width: 10),
            Container(width: 42, height: 42, decoration: const BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24)),
          ]),
        ),
      );

  Widget _packRow(BuildContext context, ({String code, String name, String trailing, bool premium, double pct}) p) => GestureDetector(
        onTap: () => context.push('/cours/test'), // ouverture du pack → test de positionnement
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
          child: Column(children: [
            Row(children: [
              _avatar(p.code),
              const SizedBox(width: 12),
              Expanded(child: Text(p.name, style: body(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(p.trailing,
                  style: body(p.premium ? 10.5 : 11, weight: p.premium ? FontWeight.w700 : FontWeight.w600,
                      color: p.premium ? const Color(0xFFA6701A) : OC.muted)),
              const SizedBox(width: 6),
              // Accès hors-ligne (téléchargement du pack)
              GestureDetector(
                onTap: () => context.push('/cours/hors-ligne'),
                child: Icon(Icons.download_rounded, size: 18, color: OC.muted),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: p.pct, minHeight: 6, backgroundColor: OC.line, valueColor: const AlwaysStoppedAnimation(OC.o500)),
            ),
          ]),
        ),
      );

  Widget _addMoreRow(BuildContext context) => GestureDetector(
        onTap: () => _toCatalogue(context),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.o100, width: 1.5)),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(11)),
                child: Icon(Icons.add_rounded, color: OC.o600, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text('Ajouter $_kAddMore', style: body(13, weight: FontWeight.w700, color: OC.ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(8)),
              child: Text('CATALOGUE', style: body(9.5, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.3)),
            ),
          ]),
        ),
      );

  Widget _avatar(String code) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(code, style: display(13, weight: FontWeight.w800, color: OC.o600)),
      );
}
