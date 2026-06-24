import 'dart:async';
import 'dart:convert';
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
  String? partial; // texte en cours de streaming (Léo « écrit »)
  String? errorText; // message d'erreur affichable
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
  // Mode « aide sur une épreuve » : le 1er message de Léo (préchargé) demande
  // QUEL exercice bloque (garanti, pas d'IA). L'épreuve est retenue ici puis
  // envoyée à l'IA dès que l'élève précise l'exercice.
  bool _awaitingExamExercise = false;
  Uint8List? _examImage;
  String _examUrl = '';
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
          // Réaffiche la vraie image si elle a été persistée (base64).
          Uint8List? bytes;
          final img64 = m['image'] ?? '';
          if (img64.isNotEmpty) {
            try { bytes = base64Decode(img64); } catch (_) {}
          }
          final content = m['content'] ?? '';
          // Si on a l'image, on n'affiche pas le placeholder texte sous la photo.
          final text = (bytes != null && content == '📷 Photo envoyée') ? null : content;
          _msgs.add(_Msg.user(image: bytes, text: text));
        } else {
          _msgs.add(_Msg.ai(Future.value(m['content'] ?? ''))..resolved = m['content']);
        }
      }
      return;
    }

    // Mode « aide sur une épreuve » : Léo demande D'ABORD quel exercice bloque.
    // Premier message de Léo PRÉCHARGÉ (déterministe → garanti à 100 %), sans
    // appel IA. L'épreuve (image) est retenue et envoyée à l'IA au 1er message
    // de l'élève (cf. `_send`).
    if (r.mode == 'exam_help') {
      _msgs.add(_Msg.user(image: r.image, text: r.image == null ? r.titleHint : (r.titleHint ?? 'Épreuve')));
      final preset = (r.presetAnswer != null && r.presetAnswer!.trim().isNotEmpty)
          ? r.presetAnswer!.trim()
          : 'Sur quel exercice (ou quelle question) bloques-tu ? Donne-moi le numéro et ce que tu as déjà essayé.';
      _msgs.add(_Msg.ai(Future.value(preset))..resolved = preset);
      _awaitingExamExercise = true;
      _examImage = r.image;
      _examUrl = r.examUrl ?? '';
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
      _addAiStream(_service.analyzeExerciseStream(image: r.image, subject: r.subject, notify: true));
    } else if (r.question != null && r.question!.trim().isNotEmpty) {
      // Les corrections (mode libre) tournent en arrière-plan + push ; les
      // modes cachés (lesson/quiz) restent silencieux.
      final bg = r.mode == null || r.mode!.isEmpty;
      _bgNotice = bg;
      _addAiStream(_service.analyzeExerciseStream(
          text: r.question, subject: r.subject, mode: r.mode, chapterId: r.chapterId, notify: bg));
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
    }).catchError((e) {
      if (!mounted) return;
      setState(() { m.failed = true; m.errorText = '$e'; });
    });
  }

  /// Ajoute une réponse de Léo en STREAMING : le texte partiel s'affiche et
  /// grandit au fil de l'eau, puis se fige en réponse finale.
  void _addAiStream(Stream<String> stream) {
    final m = _Msg.ai(null);
    _msgs.add(m);
    StreamSubscription<String>? sub;
    sub = stream.listen((t) {
      if (!mounted) return;
      setState(() => m.partial = t);
      _scrollToBottom();
    }, onDone: () {
      if (!mounted) { sub?.cancel(); return; }
      final fin = m.partial;
      if (m.resolved == null && fin != null && fin.trim().isNotEmpty) {
        AnalyticsService.logEvent('tutor_correction', {'subject': widget.request?.subject ?? ''});
        GamificationService.instance.addXp(15, tutorUses: 1);
        setState(() => m.resolved = fin);
        _scrollToBottom();
        _persistThread();
      } else if (m.resolved == null) {
        setState(() { m.failed = true; m.errorText = 'Le Tuteur n\'a pas pu répondre. Réessaie.'; });
      }
      sub?.cancel();
    }, onError: (e) {
      if (!mounted) { sub?.cancel(); return; }
      setState(() { m.failed = true; m.errorText = '$e'; });
      sub?.cancel();
    });
  }

  // Historique TEXTE (pour le contexte envoyé à l'IA) — sans image.
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

  /// Messages à PERSISTER dans le fil : comme [_history], mais on n'oublie JAMAIS
  /// un message utilisateur (placeholder « 📷 Photo envoyée » si pas de texte) et
  /// on embarque l'IMAGE en base64 (plafonnée) pour la réafficher à la réouverture.
  List<Map<String, String>> _threadMessages() {
    const fieldBudget = 88000; // marge sous la limite (~100k) du champ `messages`
    const maxPerImage = 70000;
    var budget = fieldBudget;
    final out = <Map<String, String>>[];
    for (final m in _msgs) {
      if (m.isUser) {
        final txt = (m.text != null && m.text!.trim().isNotEmpty) ? m.text!.trim() : '';
        final hasImg = m.image != null;
        if (txt.isEmpty && !hasImg) continue; // rien à montrer
        final entry = <String, String>{
          'role': 'user',
          'content': txt.isNotEmpty ? txt : '📷 Photo envoyée',
        };
        if (hasImg) {
          final b64 = base64Encode(m.image!);
          if (b64.length <= maxPerImage && b64.length + 200 <= budget) {
            entry['image'] = b64;
            budget -= b64.length + 200;
          }
        }
        out.add(entry);
      } else if (m.resolved != null) {
        out.add({'role': 'assistant', 'content': m.resolved!});
        budget -= m.resolved!.length;
      }
    }
    return out;
  }

  /// Persiste la conversation dans `tutor_threads` (mémoire) : crée le fil au
  /// 1er échange, le met à jour ensuite. Non bloquant.
  void _persistThread() {
    final history = _threadMessages();
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

    // 1re réponse en mode « épreuve » : la fonction lit l'épreuve (PDF côté
    // serveur, ou image 1ʳᵉ page sur mobile) et corrige l'exercice précisé.
    if (_awaitingExamExercise) {
      _awaitingExamExercise = false;
      final examImg = _examImage;
      final examUrl = _examUrl;
      _examImage = null;
      _examUrl = '';
      final title = (widget.request?.titleHint ?? '').trim();
      final ctx = title.isEmpty ? '' : ' de l\'épreuve « $title »';
      final text = 'Je bloque sur : $q$ctx. Aide-moi à le résoudre étape par étape.';
      setState(() {
        _msgs.add(_Msg.user(text: q));
        _addAiStream(_service.analyzeExamStream(examUrl: examUrl, image: examImg, question: text, subject: widget.request?.subject));
      });
      _scrollToBottom();
      return;
    }

    final history = _history()..add({'role': 'user', 'content': q});
    setState(() {
      _msgs.add(_Msg.user(text: q));
      _addAiStream(_service.continueConversationStream(history));
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

  // Contenu d'une bulle de Léo selon l'état : réfléchit / écrit (partiel) /
  // réponse finale / erreur.
  Widget _aiContent(_Msg m) {
    if (m.failed) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline_rounded, size: 18, color: OC.bad),
        const SizedBox(width: 9),
        Flexible(child: Text(m.errorText ?? 'Le Tuteur a rencontré un problème.',
            style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4))),
      ]);
    }
    if (m.resolved != null) {
      return RichAnswer(m.resolved!);
    }
    final p = m.partial;
    if (p != null && p.trim().isNotEmpty) {
      // En cours de streaming : le texte grandit, avec un discret « Léo écrit… ».
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        RichAnswer(p),
        const SizedBox(height: 8),
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.8, color: OC.o500)),
          const SizedBox(width: 8),
          Text('Léo écrit…', style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const LeoMascot(size: 32, mood: LeoMood.thinking),
      const SizedBox(width: 10),
      Flexible(child: Text('Léo réfléchit…', style: body(13, color: OC.ink2, weight: FontWeight.w500))),
    ]);
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
            child: _aiContent(m),
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
