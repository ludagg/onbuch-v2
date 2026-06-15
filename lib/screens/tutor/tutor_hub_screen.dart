import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class TutorHubScreen extends StatelessWidget {
  const TutorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tuteur IA', style: display(17, weight: FontWeight.w700)),
          Text('Programme MINESEC · français', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.access_time_rounded, size: 20), color: OC.ink2, onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Big scan hero
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.30), blurRadius: 26, offset: const Offset(0, 10))],
            ),
            child: Stack(children: [
              Positioned(top: -60, right: -40, child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 14),
                Text('Photographie\nton exercice', style: display(21, weight: FontWeight.w600, color: Colors.white).copyWith(height: 1.1)),
                const SizedBox(height: 6),
                Text('Correction, explication pas-à-pas et réponse adaptées à ton programme.',
                    style: body(13, color: Colors.white.withOpacity(0.9)).copyWith(height: 1.4)),
                const SizedBox(height: 16),
                Row(children: [
                  GestureDetector(
                    onTap: () => context.go('/tutor/camera'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                      child: Row(children: [
                        const Icon(Icons.camera_alt_outlined, color: OC.o600, size: 18),
                        const SizedBox(width: 8),
                        Text('Scanner', style: body(14, weight: FontWeight.w700, color: OC.o600)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(children: [
                      const Icon(Icons.image_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Importer', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ]),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Quota
          OBCard(
            child: Row(children: [
              SizedBox(
                width: 46, height: 46,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: 2 / 3,
                    strokeWidth: 5,
                    backgroundColor: OC.o100,
                    valueColor: const AlwaysStoppedAnimation(OC.o500),
                    strokeCap: StrokeCap.round,
                  ),
                  Text('2', style: mono(15, weight: FontWeight.w700, color: OC.o600)),
                ]),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('2 / 3 corrections gratuites', style: body(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Réinitialisé chaque jour · crédits dès 100 F', style: body(12, color: OC.muted, weight: FontWeight.w500)),
              ])),
              GestureDetector(
                onTap: () => _showPaywall(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: OC.o50, border: Border.all(color: OC.o100, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Recharger', style: body(12.5, weight: FontWeight.w700, color: OC.o700)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Subjects
          Text('Matières', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _SubjectChip('Maths', const Color(0xFF2D6CDF), const Color(0xFFE7EEFB)),
              const SizedBox(width: 9),
              _SubjectChip('Physique', OC.good, OC.goodBg),
              const SizedBox(width: 9),
              _SubjectChip('SVT', const Color(0xFF0E9AA0), const Color(0xFFE1F2F2)),
              const SizedBox(width: 9),
              _SubjectChip('Philo', const Color(0xFF7A5AE0), const Color(0xFFEEE9FA)),
            ]),
          ),
          const SizedBox(height: 16),

          // Recent corrections
          Text('Corrections récentes', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          ...[
            ('Équation du 2nd degré', 'Maths · résolu'),
            ('Dissertation — la liberté', 'Philo · résolu'),
          ].map((r) => GestureDetector(
            onTap: () => context.go('/tutor/correction'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.check_circle_outline_rounded, size: 19, color: OC.good),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$1, style: body(13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(r.$2, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
                ])),
                const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _PaywallSheet(),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final Color c, bg;
  const _SubjectChip(this.label, this.c, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: body(13, weight: FontWeight.w700, color: c)),
  );
}

class _PaywallSheet extends StatefulWidget {
  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  int _selectedPack = 1;
  int _selectedPayment = 0;

  static const _packs = [('5 crédits', '100 F'), ('15 crédits', '250 F'), ('40 crédits', '500 F')];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 5, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 16),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5)),
          child: const Icon(Icons.bolt_rounded, size: 28, color: OC.o500),
        ),
        const SizedBox(height: 12),
        Text('Quota du jour atteint', style: display(21, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Recharge des crédits pour continuer maintenant — ou reviens demain (gratuit).',
            textAlign: TextAlign.center, style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        const SizedBox(height: 18),
        Row(children: List.generate(_packs.length, (i) {
          final p = _packs[i];
          final sel = i == _selectedPack;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPack = i),
              child: Stack(clipBehavior: Clip.none, children: [
                if (sel) Positioned(top: -9, left: 0, right: 0, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(999)),
                  child: Text('POPULAIRE', style: body(9, weight: FontWeight.w800, color: Colors.white)),
                ))),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: sel ? OC.o50 : OC.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? OC.o500 : OC.line, width: sel ? 2 : 1.5),
                  ),
                  child: Column(children: [
                    Text(p.$2, style: display(15, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(p.$1, style: body(11, color: OC.muted, weight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ));
        })),
        const SizedBox(height: 18),
        Text('Payer avec', style: body(12, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        Row(children: [
          _PayMethod(0, OC.mtn, 'MTN', 'MTN MoMo', _selectedPayment == 0, () => setState(() => _selectedPayment = 0)),
          const SizedBox(width: 10),
          _PayMethod(1, OC.orange, 'Or.', 'Orange Money', _selectedPayment == 1, () => setState(() => _selectedPayment = 1)),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            gradient: OC.grad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Payer ${_packs[_selectedPack].$2} · ${_selectedPayment == 0 ? 'MTN MoMo' : 'Orange Money'}',
                style: body(14, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
          ]),
        ),
        const SizedBox(height: 10),
        Text('Micro-paiement ponctuel · sans abonnement', style: body(11, color: OC.muted, weight: FontWeight.w500)),
      ]),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final int idx;
  final Color c;
  final String abbr, name;
  final bool selected;
  final VoidCallback onTap;
  const _PayMethod(this.idx, this.c, this.abbr, this.name, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? OC.o500 : OC.line, width: selected ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(abbr, style: body(9, weight: FontWeight.w900, color: c == OC.mtn ? Colors.black : Colors.white))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: body(12.5, weight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: selected ? OC.o500 : Colors.transparent,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: OC.line2, width: 2),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null,
          ),
        ]),
      ),
    ));
  }
}
