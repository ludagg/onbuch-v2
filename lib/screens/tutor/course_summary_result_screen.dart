import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/rich_answer.dart';
import '../../widgets/leo_mascot.dart';
import '../../utils/tutor_pdf.dart';

/// Résultat de « Résumer un cours » présenté comme un **document** (et non comme
/// une réponse de chat) : fiche de révision mise en page proprement, prête à être
/// **téléchargée en PDF**. Pas de fil de conversation ni de question de suivi.
class CourseSummaryResultScreen extends StatefulWidget {
  final TutorRequest? request;
  const CourseSummaryResultScreen({super.key, this.request});

  @override
  State<CourseSummaryResultScreen> createState() => _CourseSummaryResultScreenState();
}

class _CourseSummaryResultScreenState extends State<CourseSummaryResultScreen> {
  final _service = TutorService();
  late Future<String> _fiche;
  String? _content; // texte résolu (pour activer le téléchargement)
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _fiche = _load();
    _fiche.then((t) {
      AnalyticsService.logEvent('course_summary', {'subject': widget.request?.subject ?? ''});
      if (mounted) setState(() => _content = t);
    }).catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBgNotice());
  }

  Future<String> _load() {
    final r = widget.request;
    final pages = r?.summaryImages ?? const <Uint8List>[];
    if (pages.isEmpty) return Future.error('Aucune page à résumer.');
    return _service.summarizeCourse(images: pages, subject: r?.subject);
  }

  void _retry() {
    setState(() {
      _content = null;
      _fiche = _load();
    });
    _fiche.then((t) {
      if (mounted) setState(() => _content = t);
    }).catchError((_) {});
  }

  void _showBgNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 5),
      backgroundColor: OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(children: [
        const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Tu peux fermer l\'app : Léo te préviendra dès que ta fiche est prête.',
              style: body(12.5, weight: FontWeight.w600, color: Colors.white)),
        ),
      ]),
    ));
  }

  /// Titre dérivé de la 1re ligne de titre du document.
  String _title() {
    final t = _content;
    if (t != null) {
      for (final line in t.split('\n')) {
        final l = line.replaceFirst(RegExp(r'^#+\s*'), '').replaceAll('*', '').trim();
        if (l.isNotEmpty) return l.length > 60 ? l.substring(0, 60) : l;
      }
    }
    final s = widget.request?.subject;
    return (s != null && s.trim().isNotEmpty) ? 'Fiche · ${s.trim()}' : 'Fiche de révision';
  }

  Future<void> _download() async {
    final t = _content;
    if (t == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await exportFichePdf(
        content: t,
        subject: widget.request?.subject,
        title: _title(),
        context: context,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.request?.subject;
    final date = DateFormat('d MMMM y', 'fr_FR').format(DateTime.now());
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/tutor'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fiche de révision', style: display(17, weight: FontWeight.w700)),
          Text('Document à télécharger', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ),
      body: FutureBuilder<String>(
        future: _fiche,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _loading();
          if (snap.hasError) return _error(snap.error);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _docHeader(subject, date),
              const SizedBox(height: 14),
              // Le document lui-même (mise en page « feuille »).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                decoration: BoxDecoration(
                  color: OC.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: OC.line, width: 1.5),
                  boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: RichAnswer(snap.data ?? ''),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _content == null ? null : _downloadBar(),
    );
  }

  // En-tête « document » : pastille + titre + matière · date.
  Widget _docHeader(String? subject, String date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(6)),
            child: Text('FICHE DE RÉVISION', style: body(9, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.06 * 9)),
          ),
          const Spacer(),
          const SizedBox(width: 30, height: 30, child: LeoMascot(size: 30, mood: LeoMood.celebrate)),
        ]),
        const SizedBox(height: 12),
        Text(_title(), style: display(20, weight: FontWeight.w700, color: Colors.white).copyWith(height: 1.12)),
        const SizedBox(height: 6),
        Text([if (subject != null && subject.trim().isNotEmpty) subject.trim(), date].join(' · '),
            style: body(12, color: Colors.white.withValues(alpha: 0.78), weight: FontWeight.w600)),
      ]),
    );
  }

  Widget _downloadBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: BoxDecoration(color: OC.paper, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
        child: GestureDetector(
          onTap: _exporting ? null : _download,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: _exporting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Télécharger la fiche (PDF)', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loading() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const LeoMascot(size: 86, mood: LeoMood.thinking),
            const SizedBox(height: 14),
            Text('Léo rédige ta fiche…', style: display(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Il met en page l\'essentiel, les définitions et les formules.\nÇa prend quelques instants.',
                textAlign: TextAlign.center, style: body(13.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.45)),
          ]),
        ),
      );

  Widget _error(Object? e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 40, color: OC.bad),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center, style: body(14, color: OC.ink2).copyWith(height: 1.4)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _retry,
              child: Container(
                height: 48, padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text('Réessayer', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      );
}
