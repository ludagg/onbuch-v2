import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/annale.dart';
import '../../widgets/subject_avatar.dart';
import 'pdf_reader_screen.dart';

/// Détail d'une épreuve : métadonnées normalisées, ouverture du PDF,
/// téléchargement et passerelle vers le Tuteur IA.
class AnnaleDetailScreen extends StatelessWidget {
  final Annale annale;
  const AnnaleDetailScreen({super.key, required this.annale});

  void _openPdf(BuildContext context) {
    context.push('/pdf',
        extra: PdfArgs(url: annale.viewUrl, title: annale.heading, subtitle: annale.contextLine));
  }

  Future<void> _download(BuildContext context) async {
    final ok = await launchUrl(Uri.parse(annale.downloadUrl), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = annale;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.heading, style: display(17, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (a.contextLine.isNotEmpty)
            Text(a.contextLine, style: body(12, color: OC.muted, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Couverture
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: OC.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OC.line, width: 1.5),
            ),
            child: Stack(children: [
              Center(child: SubjectAvatar(a.subject, size: 70)),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.description_outlined, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(a.docTypeLabel, style: body(11, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: () => _openPdf(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 10)],
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

          // Actions
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openPdf(context),
                child: _ActionTile(icon: Icons.picture_as_pdf_rounded, label: 'Lire', sub: 'PDF',
                    iconC: const Color(0xFFC0392B), iconBg: const Color(0xFFFAE7E4), selected: true),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GestureDetector(
                onTap: () => _download(context),
                child: const _ActionTile(icon: Icons.download_rounded, label: 'Télécharger', sub: 'Hors-ligne',
                    iconC: OC.good, iconBg: OC.goodBg),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/tutor'),
                child: const _ActionTile(icon: Icons.auto_awesome_rounded, label: 'Tuteur', sub: 'Aide IA',
                    iconC: Color(0xFF7A5AE0), iconBg: Color(0xFFEEE9FA)),
              ),
            ),
          ]),
          const SizedBox(height: 15),

          // Métadonnées
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OC.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OC.line, width: 1.5),
            ),
            child: Column(children: [
              if (a.subject != null) _MetaRow('Matière', a.subject!),
              if (a.classLabel.isNotEmpty) _MetaRow('Classe', a.classLabel),
              if (a.examType != null) _MetaRow('Examen', a.examType!),
              _MetaRow('Type', a.docTypeLabel),
              if (a.year != null) _MetaRow('Session', '${a.year}'),
              if (a.system != null) _MetaRow('Sous-système', a.system!),
              _MetaRow('Téléchargements', '${a.downloads}'),
            ]),
          ),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bloqué·e sur un exercice ?', style: body(14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Corrige-le pas-à-pas avec le Tuteur IA', style: body(12, color: OC.o700, weight: FontWeight.w500)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: OC.o600),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color iconC, iconBg;
  final bool selected;
  const _ActionTile({required this.icon, required this.label, required this.sub, required this.iconC, required this.iconBg, this.selected = false});

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
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: iconC, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: body(12.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(sub, style: body(10, color: OC.muted, weight: FontWeight.w600)),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label, value;
  const _MetaRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: body(12.5, color: OC.muted, weight: FontWeight.w600))),
        Expanded(child: Text(value, style: body(12.5, weight: FontWeight.w700), textAlign: TextAlign.right)),
      ]),
    );
  }
}
