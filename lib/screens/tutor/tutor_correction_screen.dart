import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../services/analytics_service.dart';
import '../../services/gamification_service.dart';
import '../../widgets/rich_answer.dart';
import '../../widgets/leo_mascot.dart';
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
  bool _bgNotice = false; // génération en arrière-plan → message « tu peux quitter »
  String? _threadId; // fil de conversation persisté (mémoire)
  // Sauvegardes du fil SÉRIALISÉES : garantit que la création (1er tour) fixe
  // `_threadId` avant tout tour suivant → on met à jour le même fil au lieu d'en
  // créer un nouveau à chaque message.
  Future<void> _saveChain = Future.value();

  @override
  void initState() {
    super.initState();
    _start();
    if (_bgNotice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showBgNotice());
    }
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
          child: Text('Tu peux fermer l\'app : Léo te préviendra dès que c\'est prêt.',
              style: body(12.5, weight: FontWeight.w600, color: Colors.white)),
        ),
      ]),
    ));
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

    // Reprise d'un fil de conversation (mémoire) : on précharge les messages,
    // sans relancer d'appel IA. L'élève peut poursuivre la discussion.
    if (r.threadMessages != null && r.threadMessages!.isNotEmpty) {
      _threadId = r.threadId;
      for (final m in r.threadMessages!) {
        if (m['role'] == 'user') {
          _msgs.add(_Msg.user(text: m['content']));
        } else {
          _msgs.add(_Msg.ai(Future.value(m['content'] ?? ''))..resolved = m['content']);
        }
      }
      return;
    }

    // Mode « Résumer un cours » : plusieurs pages → fiche de révision.
    if (r.mode == 'summary' && (r.summaryImages?.isNotEmpty ?? false)) {
      final pages = r.summaryImages!;
      _msgs.add(_Msg.user(
        image: pages.first,
        text: pages.length > 1
            ? '${pages.length} pages de cours · génère une fiche'
            : 'Génère une fiche de révision',
      ));
      _bgNotice = true;
      _addAi(_service.summarizeCourse(images: pages, subject: r.subject));
      return;
    }

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
    if (r.presetAnswer != null && r.presetAnswer!.trim().isNotEmpty) {
      fut = Future.value(r.presetAnswer!.trim()); // contenu déjà en cache → instantané
    } else if (r.jobId != null) {
      fut = _service.getJobCorrection(r.jobId!);
    } else if (r.image != null) {
      _bgNotice = true;
      fut = _service.analyzeExercise(image: r.image, subject: r.subject, notify: true);
    } else if (r.question != null && r.question!.trim().isNotEmpty) {
      // Les corrections (mode libre) tournent en arrière-plan + push ; les
      // modes cachés (lesson/quiz) restent silencieux.
      final bg = r.mode == null || r.mode!.isEmpty;
      _bgNotice = bg;
      fut = _service.analyzeExercise(
          text: r.question, subject: r.subject, mode: r.mode, chapterId: r.chapterId, notify: bg);
    }
    if (fut != null) _addAi(fut);
  }

  void _addAi(Future<String> fut) {
    final m = _Msg.ai(fut);
    _msgs.add(m);
    fut.then((t) {
      AnalyticsService.logEvent('tutor_correction', {'subject': widget.request?.subject ?? ''});
      GamificationService.instance.addXp(15, tutorUses: 1);
      if (!mounted) return;
      setState(() => m.resolved = t);
      _scrollToBottom();
      _persistThread();
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

  /// Persiste la conversation dans `tutor_threads` (mémoire) : crée le fil au
  /// 1er échange, le met à jour ensuite. Non bloquant.
  void _persistThread() {
    final history = _history();
    if (history.isEmpty) return;
    final hint = widget.request?.titleHint?.trim();
    String? title = (hint != null && hint.isNotEmpty) ? hint : null;
    if (title == null) {
      final firstUser = _msgs.where((m) => m.isUser && (m.text?.trim().isNotEmpty ?? false));
      if (firstUser.isNotEmpty) title = firstUser.first.text!.trim();
    }
    final subject = widget.request?.subject;
    _saveChain = _saveChain.then((_) async {
      final id = await _service.saveThread(
        threadId: _threadId,
        messages: history,
        title: title,
        subject: subject,
      );
      if (id != null) _threadId = id;
    });
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

  bool get _hasExportable => _msgs.any((m) => !m.isUser && m.resolved != null);

  // Fiche de révision : première réponse de Léo en mode « summary ».
  bool get _isFiche => widget.request?.mode == 'summary';
  String? get _ficheText {
    for (final m in _msgs) {
      if (!m.isUser && m.resolved != null) return m.resolved;
    }
    return null;
  }

  String? _ficheTitle() {
    final t = _ficheText;
    if (t == null) return null;
    for (final line in t.split('\n')) {
      final l = line.replaceFirst(RegExp(r'^#+\s*'), '').replaceAll('*', '').trim();
      if (l.isNotEmpty) return l.length > 60 ? l.substring(0, 60) : l;
    }
    return null;
  }

  Future<void> _exportPdf() async {
    final turns = <PdfTurn>[];
    for (final m in _msgs) {
      if (m.isUser) {
        turns.add(PdfTurn(isUser: true, text: m.text ?? '', image: m.image));
      } else if (m.resolved != null) {
        turns.add(PdfTurn(isUser: false, text: m.resolved!));
      }
    }
    if (!turns.any((t) => !t.isUser)) return; // aucune réponse à exporter
    await exportConversationPdf(turns: turns, title: widget.request?.titleHint, context: context);
  }

  Future<void> _downloadFiche() async {
    final t = _ficheText;
    if (t == null) return;
    await exportFichePdf(
      content: t,
      subject: widget.request?.subject,
      title: _ficheTitle(),
      context: context,
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
          if (_hasExportable)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 21),
              color: OC.ink2,
              tooltip: 'Exporter la discussion en PDF',
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
      if (_isFiche && _ficheText != null) _downloadFicheBar(),
      _composer(),
    ]);
  }

  Widget _downloadFicheBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      color: OC.paper,
      child: GestureDetector(
        onTap: _downloadFiche,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            gradient: OC.grad,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            Text('Télécharger la fiche (PDF)', style: body(14, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190, maxHeight: 220),
                        child: Image.memory(m.image!, fit: BoxFit.cover),
                      ),
                    ),
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
            SizedBox(width: 26, height: 26, child: Image.asset('assets/images/leo.png', fit: BoxFit.contain)),
            const SizedBox(width: 7),
            Text('Léo · Tuteur OnBuch', style: body(12, weight: FontWeight.w700, color: OC.ink2)),
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
                    const LeoMascot(size: 32, mood: LeoMood.thinking),
                    const SizedBox(width: 10),
                    Flexible(child: Text('Léo réfléchit…', style: body(13, color: OC.ink2, weight: FontWeight.w500))),
                  ]);
                }
                if (snap.hasError) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: OC.bad),
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
      decoration: BoxDecoration(
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
