import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/exam_result.dart';

class ResultSuccessScreen extends StatelessWidget {
  final ExamResult? result;
  const ResultSuccessScreen({super.key, this.result});

  // Valeurs d'exemple si l'écran est ouvert sans résultat (démo).
  String get _examLine => result?.examLine ?? 'Baccalauréat · Série D';
  String get _session => result?.sessionLine ?? 'Session 2026';
  String get _name => result?.candidateName ?? 'NDJAMÉ Aïcha Larissa';
  String get _meta => result?.candidateMeta ?? 'N° table 10428 · Centre Lycée de Bonabéri, Douala';
  String get _mention => result?.mention ?? 'Bien';
  String get _average => result?.average ?? '14,25/20';

  String _shareText() {
    final buf = StringBuffer()
      ..writeln('🎓 $_examLine · $_session')
      ..writeln('✅ ADMIS·E${result?.mention != null ? ' — Mention $_mention' : ''}'
          '${result?.average != null ? ' ($_average)' : ''}')
      ..writeln('$_name · $_meta')
      ..write('Vérifié sur OnBuch · onbuch.cm');
    return buf.toString();
  }

  Future<void> _shareWhatsApp() async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareText())}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
          const LeoMascot(size: 104, mood: LeoMood.celebrate),
          const SizedBox(height: 6),
          Text('Félicitations, tu es admis·e ! 🎉', style: display(24, weight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Partage la bonne nouvelle avec ta famille.', style: body(14, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 16),

          _ResultCard(
            admis: true,
            examLine: _examLine,
            session: _session,
            name: _name,
            meta: _meta,
            mention: _mention,
            average: _average,
          ),
          const SizedBox(height: 16),

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
              onPressed: () => _showShareSheet(context),
            )),
            const SizedBox(width: 11),
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: OC.line2, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: OC.ink,
              ),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Partager'),
              onPressed: _shareWhatsApp,
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
          _ShareableCard(examLine: _examLine, mention: _mention, average: _average, name: _name, admis: true),
          const SizedBox(height: 18),
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
              onPressed: () { Navigator.pop(context); _shareWhatsApp(); },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared result card ───────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final bool admis;
  final String examLine, session, name, meta;
  final String? mention, average, threshold;
  const _ResultCard({
    required this.admis,
    required this.examLine,
    required this.session,
    required this.name,
    required this.meta,
    this.mention,
    this.average,
    this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    return OBCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(examLine.toUpperCase(), style: body(11, weight: FontWeight.w800, color: OC.muted)
                  .copyWith(letterSpacing: 0.1 * 11)),
              const SizedBox(height: 3),
              Text(session, style: display(17, weight: FontWeight.w600)),
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
            Text(name, style: display(22, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(meta, style: body(12.5, color: OC.ink2, weight: FontWeight.w500)),
            if (admis && (mention != null || average != null)) ...[
              const SizedBox(height: 16),
              Row(children: [
                if (mention != null) Expanded(child: _Stat('Mention', mention!)),
                if (mention != null && average != null) const SizedBox(width: 10),
                if (average != null) Expanded(child: _Stat('Moyenne', average!)),
              ]),
            ],
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
  final String examLine, name;
  final String? mention, average;
  final bool admis;
  const _ShareableCard({required this.examLine, required this.name, this.mention, this.average, required this.admis});

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (mention != null) 'Mention $mention',
      if (average != null) average,
    ].join(' · ');
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
          Text(examLine.toUpperCase(),
              style: body(11.5, weight: FontWeight.w800, color: Colors.white.withValues(alpha:0.85))
                  .copyWith(letterSpacing: 0.12 * 11.5)),
          const SizedBox(height: 8),
          Text(admis ? 'ADMIS·E' : 'NON ADMIS', style: display(30, weight: FontWeight.w700, color: Colors.white)),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(detail, style: display(17, weight: FontWeight.w600, color: Colors.white)),
          ],
          Divider(height: 36, color: Colors.white.withValues(alpha:0.22), thickness: 1),
          Row(children: [
            Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: display(15, weight: FontWeight.w600, color: Colors.white))),
            const SizedBox(width: 8),
            Text('onbuch.cm', style: body(11.5, color: Colors.white.withValues(alpha:0.82), weight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }
}
