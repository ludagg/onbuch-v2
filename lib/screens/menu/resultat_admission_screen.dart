import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/concours_application.dart';
import '../../utils/launch.dart';

/// Résultat d'admission (section F · écran 24), affiché depuis une candidature.
class ResultatAdmissionScreen extends StatelessWidget {
  final ConcoursApplication? application;
  const ResultatAdmissionScreen({super.key, this.application});

  ConcoursApplication get a =>
      application ??
      ConcoursApplication(
        id: '-', concoursId: '-', concoursName: 'Concours', status: 'submitted',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  bool get _published => application?.status == 'result';

  void _share(BuildContext context) {
    final text = '🎓 Admis·e au concours ${a.concoursName} — via OnBuch · onbuch.cm';
    openUrl(context, 'https://wa.me/?text=${Uri.encodeComponent(text)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Résultat d\'admission'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: _published ? _admitted(context) : _pending(),
      ),
    );
  }

  Widget _admitted(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Text('🎉', style: display(34, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Admis·e', style: display(24, weight: FontWeight.w800, color: OC.waInk)),
          const SizedBox(height: 4),
          Text(a.concoursName, textAlign: TextAlign.center, style: body(13, color: OC.waInk, weight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          _row('Concours', a.concoursName),
          const SizedBox(height: 9),
          _row('Statut', 'Admis·e'),
          if (a.receiptNo != null) ...[
            const SizedBox(height: 9),
            _row('Récépissé', a.receiptNo!),
          ],
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: OC.line2, width: 1.5), foregroundColor: OC.ink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Partager', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () => _share(context),
        )),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => context.go('/concours'),
          child: const Text('Étapes suivantes', style: TextStyle(fontWeight: FontWeight.w700)),
        )),
      ]),
    ]);
  }

  Widget _pending() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(height: 30),
      Container(
        width: 76, height: 76,
        decoration: BoxDecoration(color: OC.o50, shape: BoxShape.circle),
        child: const Icon(Icons.hourglass_bottom_rounded, size: 36, color: OC.o500),
      ),
      const SizedBox(height: 16),
      Text('Résultat pas encore publié', style: display(18, weight: FontWeight.w700), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Statut actuel : ${a.statusLabel}. Tu seras alerté·e dès que le résultat de « ${a.concoursName} » sera disponible.',
          textAlign: TextAlign.center,
          style: body(13.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.45),
        ),
      ),
    ]);
  }

  Widget _row(String l, String v) => Row(children: [
        Expanded(child: Text(l, style: body(12, color: OC.ink2, weight: FontWeight.w500))),
        Flexible(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right, style: body(12.5, weight: FontWeight.w700))),
      ]);
}
