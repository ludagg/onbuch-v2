import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/tutor_service.dart';
import '../../widgets/rich_answer.dart';

class TutorCorrectionScreen extends StatefulWidget {
  /// Photo de l'exercice à corriger (octets).
  final Uint8List? image;
  final String? question;
  const TutorCorrectionScreen({super.key, this.image, this.question});

  @override
  State<TutorCorrectionScreen> createState() => _TutorCorrectionScreenState();
}

class _TutorCorrectionScreenState extends State<TutorCorrectionScreen> {
  final _service = TutorService();
  Future<String>? _future;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() {
    if (widget.image != null) {
      setState(() {
        _future = _service.analyzeExercise(widget.image!, question: widget.question);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: widget.image == null ? _empty() : _conversation(),
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
          Text('Scanne un exercice', style: display(19, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Prends une photo d\'un exercice et le Tuteur IA te le corrige étape par étape.',
              textAlign: TextAlign.center, style: body(14, color: OC.muted).copyWith(height: 1.5)),
          const SizedBox(height: 18),
          _scanButton('Scanner un exercice'),
        ]),
      ),
    );
  }

  // ── Conversation (photo + correction) ──────────────────────────────────────
  Widget _conversation() {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(children: [
            // Bulle utilisateur : la photo
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 230),
                decoration: BoxDecoration(
                  color: OC.o500,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18), topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18), bottomRight: Radius.circular(5),
                  ),
                  boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(widget.image!, fit: BoxFit.cover),
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
      // Barre d'action
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: OC.paper,
          border: Border(top: BorderSide(color: OC.line, width: 1.5)),
        ),
        child: SafeArea(top: false, child: _scanButton('Scanner un autre exercice')),
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
      onTap: () => context.go('/tutor/camera'),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: OC.grad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Text(label, style: body(14, weight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }
}
