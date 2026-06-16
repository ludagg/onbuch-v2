import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../widgets/rich_answer.dart';
import '../../utils/tutor_pdf.dart';

class TutorCorrectionScreen extends StatefulWidget {
  final TutorRequest? request;
  const TutorCorrectionScreen({super.key, this.request});

  @override
  State<TutorCorrectionScreen> createState() => _TutorCorrectionScreenState();
}

class _TutorCorrectionScreenState extends State<TutorCorrectionScreen> {
  final _service = TutorService();
  Future<String>? _future;
  String? _correctionText; // mémorise la correction pour l'export PDF

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() {
    final r = widget.request;
    _correctionText = null;
    if (r == null) {
      setState(() => _future = null);
      return;
    }
    Future<String>? f;
    if (r.jobId != null) {
      f = _service.getJobCorrection(r.jobId!);
    } else if (r.image != null) {
      f = _service.analyzeExercise(image: r.image, subject: r.subject);
    } else if (r.question != null && r.question!.trim().isNotEmpty) {
      f = _service.analyzeExercise(text: r.question, subject: r.subject);
    }
    setState(() => _future = f);
    f?.then((c) {
      if (mounted) setState(() => _correctionText = c);
    }).catchError((_) {});
  }

  Future<void> _exportPdf() async {
    final r = widget.request;
    if (_correctionText == null) return;
    await exportCorrectionPdf(
      correction: _correctionText!,
      image: r?.image,
      question: r?.question,
      title: r?.titleHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final hasContent = r != null &&
        (r.image != null ||
            (r.question != null && r.question!.trim().isNotEmpty) ||
            r.jobId != null);
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Correction', style: display(17, weight: FontWeight.w700)),
          Text('Tuteur IA', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/tutor'),
        ),
        actions: [
          if (_correctionText != null)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 21),
              color: OC.ink2,
              tooltip: 'Exporter en PDF',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: hasContent ? _conversation(r) : _empty(),
    );
  }

  // ── Aucun exercice fourni ──────────────────────────────────────────────────
  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome_rounded, size: 46, color: OC.o500),
          const SizedBox(height: 14),
          Text('Demande une correction', style: display(19, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Photographie un exercice ou écris-le : le Tuteur IA te le corrige étape par étape.',
              textAlign: TextAlign.center, style: body(14, color: OC.muted).copyWith(height: 1.5)),
          const SizedBox(height: 18),
          _scanButton('Aller au Tuteur'),
        ]),
      ),
    );
  }

  // ── Conversation (énoncé + correction) ─────────────────────────────────────
  Widget _conversation(TutorRequest r) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(children: [
            // Bulle utilisateur : la photo, ou le texte de l'énoncé.
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Container(
                  decoration: BoxDecoration(
                    color: OC.o500,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18), topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18), bottomRight: Radius.circular(5),
                    ),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  padding: r.image != null ? const EdgeInsets.all(6) : const EdgeInsets.fromLTRB(14, 11, 14, 11),
                  child: r.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.memory(r.image!, fit: BoxFit.cover),
                        )
                      : Text(
                          r.question?.trim().isNotEmpty == true ? r.question!.trim() : (r.titleHint ?? 'Exercice'),
                          style: body(13, weight: FontWeight.w600, color: Colors.white).copyWith(height: 1.35),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Bulle IA
            Align(
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 7),
                  Text('Tuteur OnBuch', style: body(12, weight: FontWeight.w700, color: OC.ink2)),
                ]),
                const SizedBox(height: 7),
                _aiBubble(),
              ]),
            ),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: OC.paper,
          border: Border(top: BorderSide(color: OC.line, width: 1.5)),
        ),
        child: SafeArea(top: false, child: _scanButton('Nouvelle question')),
      ),
    ]);
  }

  Widget _aiBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      width: double.infinity,
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(18), bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18), topLeft: Radius.circular(5),
        ),
        border: Border.all(color: OC.line, width: 1.5),
        boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(14),
      child: FutureBuilder<String>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: OC.o500),
              ),
              const SizedBox(width: 11),
              Flexible(
                child: Text('Le Tuteur analyse ton exercice…',
                    style: body(13, color: OC.ink2, weight: FontWeight.w500)),
              ),
            ]);
          }
          if (snap.hasError) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: OC.bad),
                const SizedBox(width: 9),
                Flexible(
                  child: Text('${snap.error}',
                      style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
                ),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _run,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: OC.o100, width: 1.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded, size: 16, color: OC.o700),
                    const SizedBox(width: 6),
                    Text('Réessayer', style: body(13, weight: FontWeight.w700, color: OC.o700)),
                  ]),
                ),
              ),
            ]);
          }
          return RichAnswer(snap.data ?? '');
        },
      ),
    );
  }

  Widget _scanButton(String label) {
    return GestureDetector(
      onTap: () => context.go('/tutor'),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: OC.grad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Text(label, style: body(14, weight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }
}
