import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../widgets/rich_answer.dart';
import '../../utils/tutor_pdf.dart';

/// Message du fil de conversation avec le Tuteur.
class _Msg {
  final bool isUser;
  final String? text;
  final Uint8List? image;
  final Future<String>? future; // pour les messages de l'assistant
  String? resolved;
  bool failed = false;
  _Msg.user({this.text, this.image})
      : isUser = true,
        future = null;
  _Msg.ai(this.future)
      : isUser = false,
        text = null,
        image = null;
}

class TutorCorrectionScreen extends StatefulWidget {
  final TutorRequest? request;
  const TutorCorrectionScreen({super.key, this.request});

  @override
  State<TutorCorrectionScreen> createState() => _TutorCorrectionScreenState();
}

class _TutorCorrectionScreenState extends State<TutorCorrectionScreen> {
  final _service = TutorService();
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  String? _correctionText; // 1re correction, pour l'export PDF

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _start() {
    final r = widget.request;
    if (r == null) return;
    // Bulle utilisateur initiale (photo ou texte)
    if (r.image != null) {
      _msgs.add(_Msg.user(image: r.image, text: r.question));
    } else if (r.question != null && r.question!.trim().isNotEmpty) {
      _msgs.add(_Msg.user(text: r.question));
    } else if (r.titleHint != null) {
      _msgs.add(_Msg.user(text: r.titleHint));
    }
    // Réponse initiale
    Future<String>? fut;
    if (r.jobId != null) {
      fut = _service.getJobCorrection(r.jobId!);
    } else if (r.image != null) {
      fut = _service.analyzeExercise(image: r.image, subject: r.subject);
    } else if (r.question != null && r.question!.trim().isNotEmpty) {
      fut = _service.analyzeExercise(text: r.question, subject: r.subject, mode: r.mode);
    }
    if (fut != null) _addAi(fut, primary: true);
  }

  void _addAi(Future<String> fut, {bool primary = false}) {
    final m = _Msg.ai(fut);
    _msgs.add(m);
    fut.then((t) {
      if (!mounted) return;
      setState(() {
        m.resolved = t;
        if (primary) _correctionText = t;
      });
      _scrollToBottom();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => m.failed = true);
    });
  }

  List<Map<String, String>> _history() {
    final out = <Map<String, String>>[];
    for (final m in _msgs) {
      if (m.isUser) {
        final c = (m.text != null && m.text!.trim().isNotEmpty)
            ? m.text!.trim()
            : (m.image != null ? '(Exercice envoyé en photo)' : '');
        if (c.isNotEmpty) out.add({'role': 'user', 'content': c});
      } else if (m.resolved != null) {
        out.add({'role': 'assistant', 'content': m.resolved!});
      }
    }
    return out;
  }

  bool get _canSend {
    if (_msgs.isEmpty) return false;
    final last = _msgs.last;
    return last.isUser || last.resolved != null || last.failed;
  }

  void _send() {
    final q = _inputCtrl.text.trim();
    if (q.isEmpty || !_canSend) return;
    _inputCtrl.clear();
    FocusScope.of(context).unfocus();
    final history = _history()..add({'role': 'user', 'content': q});
    setState(() {
      _msgs.add(_Msg.user(text: q));
      _addAi(_service.continueConversation(history));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _exportPdf() async {
    if (_correctionText == null) return;
    final r = widget.request;
    await exportCorrectionPdf(
      correction: _correctionText!,
      image: r?.image,
      question: r?.question,
      title: r?.titleHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _msgs.isNotEmpty;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tuteur IA', style: display(17, weight: FontWeight.w700)),
          Text('Pose tes questions de suivi', style: body(11, color: OC.muted, weight: FontWeight.w500)),
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
      body: hasContent ? _chat() : _empty(),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome_rounded, size: 46, color: OC.o500),
            const SizedBox(height: 14),
            Text('Demande une correction', style: display(19, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Photographie un exercice ou écris-le : le Tuteur te le corrige étape par étape.',
                textAlign: TextAlign.center, style: body(14, color: OC.muted).copyWith(height: 1.5)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => context.go('/tutor'),
              child: Container(
                height: 50, padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text('Aller au Tuteur', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      );

  Widget _chat() {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          itemCount: _msgs.length,
          itemBuilder: (_, i) => _msgs[i].isUser ? _userBubble(_msgs[i]) : _aiBubble(_msgs[i]),
        ),
      ),
      _composer(),
    ]);
  }

  Widget _userBubble(_Msg m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
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
            padding: m.image != null ? const EdgeInsets.all(6) : const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: m.image != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.memory(m.image!, fit: BoxFit.cover)),
                    if (m.text != null && m.text!.trim().isNotEmpty)
                      Padding(padding: const EdgeInsets.fromLTRB(6, 7, 6, 2),
                          child: Text(m.text!.trim(), style: body(12.5, weight: FontWeight.w600, color: Colors.white))),
                  ])
                : Text(m.text ?? '', style: body(13, weight: FontWeight.w600, color: Colors.white).copyWith(height: 1.35)),
          ),
        ),
      ),
    );
  }

  Widget _aiBubble(_Msg m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14)),
            const SizedBox(width: 7),
            Text('Tuteur OnBuch', style: body(12, weight: FontWeight.w700, color: OC.ink2)),
          ]),
          const SizedBox(height: 7),
          Container(
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
              future: m.future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: OC.o500)),
                    const SizedBox(width: 11),
                    Flexible(child: Text('Le Tuteur réfléchit…', style: body(13, color: OC.ink2, weight: FontWeight.w500))),
                  ]);
                }
                if (snap.hasError) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: OC.bad),
                    const SizedBox(width: 9),
                    Flexible(child: Text('${snap.error}',
                        style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4))),
                  ]);
                }
                return RichAnswer(snap.data ?? '');
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _composer() {
    final enabled = _canSend;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: OC.paper,
        border: Border(top: BorderSide(color: OC.line, width: 1.5)),
      ),
      child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(color: OC.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: OC.line2, width: 1.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _inputCtrl,
              minLines: 1, maxLines: 4,
              style: body(14, color: OC.ink),
              decoration: InputDecoration(
                hintText: 'Pose une question de suivi…',
                hintStyle: body(13.5, color: OC.muted, weight: FontWeight.w500),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: enabled ? _send : null,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: enabled ? OC.o500 : OC.line2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 21),
          ),
        ),
      ])),
    );
  }
}
