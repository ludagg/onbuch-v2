import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

class ResultSuccessScreen extends StatelessWidget {
  const ResultSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Ton résultat', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/results'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Celebration header
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(color: OC.goodBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded, size: 34, color: OC.good),
          ),
          const SizedBox(height: 12),
          Text('Félicitations, tu es admise ! 🎉', style: display(24, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Partage la bonne nouvelle avec ta famille.', style: body(14, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 16),

          // Result card
          const _ResultCard(admis: true),
          const SizedBox(height: 16),

          // Share WhatsApp
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: OC.wa,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Partager sur WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              onPressed: () => _showShareSheet(context),
            ),
          ),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: OC.line2, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: OC.ink,
              ),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Carte vérifiée'),
              onPressed: () {},
            )),
            const SizedBox(width: 11),
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: OC.line2, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: OC.ink,
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Enregistrer'),
              onPressed: () {},
            )),
          ]),
        ]),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 5, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Text('Partager ton résultat', style: display(19, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Carte vérifiée OnBuch — infalsifiable', style: body(12.5, color: OC.muted, weight: FontWeight.w500)),
          const SizedBox(height: 18),
          // Shareable card
          _ShareableCard(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: OC.wa,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Partager sur WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _ShareAction(Icons.download_outlined, 'Image'),
            _ShareAction(Icons.share_outlined, 'Plus'),
            _ShareAction(Icons.link_rounded, 'Copier lien'),
          ]),
        ]),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ShareAction(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Icon(icon, size: 22, color: OC.ink2),
      ),
      const SizedBox(height: 7),
      Text(label, style: body(11.5, weight: FontWeight.w600, color: OC.ink2)),
    ]);
  }
}

// ─── Shared result card ───────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final bool admis;
  const _ResultCard({required this.admis});

  @override
  Widget build(BuildContext context) {
    return OBCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        // header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Baccalauréat · Série D', style: body(11, weight: FontWeight.w800, color: OC.muted)
                  .copyWith(letterSpacing: 0.1 * 11)),
              const SizedBox(height: 3),
              Text('Session 2026', style: display(17, weight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: admis ? OC.goodBg : const Color(0xFFFBEFE4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(admis ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                    size: 16, color: admis ? OC.good : OC.warn),
                const SizedBox(width: 6),
                Text(admis ? 'ADMIS' : 'NON ADMIS',
                    style: body(12, weight: FontWeight.w800, color: admis ? OC.waInk : const Color(0xFF9A5B3A))),
              ]),
            ),
          ]),
        ),
        const HRule(),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Candidat', style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('NDJAMÉ Aïcha Larissa', style: display(22, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('N° table 10428 · Centre Lycée de Bonabéri, Douala',
                style: body(12.5, color: OC.ink2, weight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (admis)
              Row(children: [
                Expanded(child: _Stat('Mention', 'Bien')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Moyenne', '14,25/20')),
              ])
            else
              Row(children: [
                Expanded(child: _Stat('Moyenne obtenue', '9,40/20')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Admissibilité', '10,00', warn: true)),
              ]),
          ]),
        ),
        const HRule(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(children: [
            const Icon(Icons.verified_outlined, size: 17, color: OC.o600),
            const SizedBox(width: 8),
            Text('Résultat vérifié OnBuch', style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
            const Spacer(),
            const OBWordmark(size: 14),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final bool warn;
  const _Stat(this.label, this.value, {this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: body(11, weight: FontWeight.w700, color: OC.muted)),
        const SizedBox(height: 3),
        Text(value, style: display(19, weight: FontWeight.w700, color: warn ? OC.warn : OC.ink)),
      ]),
    );
  }
}

// ─── Shareable card ───────────────────────────────────────────────────────────
class _ShareableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: OC.grad,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.34), blurRadius: 26, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned(top: -55, right: -40,
          child: Container(width: 150, height: 150, decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.14), shape: BoxShape.circle))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const OBWordmark(size: 18, light: true),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.22), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text('Vérifié', style: body(11, weight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ]),
          const SizedBox(height: 26),
          Text('BACCALAURÉAT 2026 · SÉRIE D',
              style: body(11.5, weight: FontWeight.w800, color: Colors.white.withValues(alpha:0.85))
                  .copyWith(letterSpacing: 0.12 * 11.5)),
          const SizedBox(height: 8),
          Text('ADMISE', style: display(30, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Mention Bien · 14,25/20', style: display(17, weight: FontWeight.w600, color: Colors.white)),
          Divider(height: 36, color: Colors.white.withValues(alpha:0.22), thickness: 1),
          Row(children: [
            Text('NDJAMÉ Aïcha', style: display(15, weight: FontWeight.w600, color: Colors.white)),
            const Spacer(),
            Text('onbuch.cm', style: body(11.5, color: Colors.white.withValues(alpha:0.82), weight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }
}
