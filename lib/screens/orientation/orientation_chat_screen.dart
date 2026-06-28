import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/orientation_assistant_service.dart';

/// Chat « Léo Orientation » — assistant DÉDIÉ à l'orientation (séparé du tuteur).
/// Accessible uniquement depuis la page Orientation. Réponses en streaming d'un
/// modèle rapide, personnalisées avec le profil de l'élève.
class OrientationChatScreen extends StatefulWidget {
  const OrientationChatScreen({super.key});

  @override
  State<OrientationChatScreen> createState() => _OrientationChatScreenState();
}

class _Msg {
  final String role; // 'user' | 'assistant'
  String content;
  _Msg(this.role, this.content);
}

class _OrientationChatScreenState extends State<OrientationChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  Map<String, dynamic>? _profile;
  bool _sending = false;

  static const _suggestions = [
    'Quelle filière après mon Bac ?',
    'Quels métiers correspondent à mon profil ?',
    'Comment préparer le concours de Polytechnique (ENSP) ?',
    'Quelles bourses pour étudier au Cameroun ?',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) return;
      final p = await DatabaseService().getUserProfile(user.$id);
      if (p == null) return;
      String? s(dynamic v) => (v?.toString().trim().isNotEmpty ?? false) ? v.toString().trim() : null;
      _profile = {
        if (s(p['classe']) != null) 'classe': s(p['classe']),
        if (s(p['serie']) != null) 'serie': s(p['serie']),
        if (s(p['examen']) != null) 'examen': s(p['examen']),
        if (s(p['careerGoal']) != null) 'careerGoal': s(p['careerGoal']),
        if (s(p['studyField']) != null) 'studyField': s(p['studyField']),
        if (s(p['studyDestination']) != null) 'studyDestination': s(p['studyDestination']),
      };
    } catch (_) {/* profil facultatif */}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    final assistant = _Msg('assistant', '');
    setState(() {
      _msgs.add(_Msg('user', text));
      _msgs.add(assistant);
      _sending = true;
    });
    _scrollToEnd();

    final history = _msgs
        .where((m) => m.content.isNotEmpty || m == assistant)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList()
      ..removeWhere((m) => (m['content'] as String).isEmpty); // retire le placeholder vide

    try {
      await OrientationAssistantService.instance.ask(
        messages: history,
        profile: _profile,
        onDelta: (d) {
          if (!mounted) return;
          setState(() => assistant.content += d);
          _scrollToEnd();
        },
      );
      if (assistant.content.trim().isEmpty) {
        setState(() => assistant.content = 'Désolé, je n\'ai pas pu répondre. Reformule ta question ?');
      }
    } catch (e) {
      if (mounted) setState(() => assistant.content = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Léo Orientation'),
      body: Column(children: [
        Expanded(
          child: _msgs.isEmpty
              ? _intro()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) => _bubble(_msgs[i], i == _msgs.length - 1),
                ),
        ),
        _composer(),
      ]),
    );
  }

  Widget _intro() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Center(child: Column(children: [
          const LeoMascot(size: 84, mood: LeoMood.wave),
          const SizedBox(height: 12),
          Text('Léo Orientation', style: display(20, weight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Ton conseiller pour choisir ta filière, ton école, ton métier et tes concours au Cameroun.',
              textAlign: TextAlign.center,
              style: body(13, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.4)),
        ])),
        const SizedBox(height: 22),
        Text('Pour démarrer', style: body(12.5, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        for (final s in _suggestions)
          GestureDetector(
            onTap: () => _send(s),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.auto_awesome_rounded, size: 17, color: OC.o600),
                const SizedBox(width: 11),
                Expanded(child: Text(s, style: body(13.5, weight: FontWeight.w600))),
                Icon(Icons.arrow_forward_rounded, size: 16, color: OC.faint),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _bubble(_Msg m, bool isLast) {
    final isUser = m.role == 'user';
    final thinking = !isUser && m.content.isEmpty && _sending && isLast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const LeoMascot(size: 30, mood: LeoMood.idle),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? OC.o600 : OC.paper,
                borderRadius: BorderRadius.circular(16),
                border: isUser ? null : Border.all(color: OC.line, width: 1.5),
              ),
              child: thinking
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: OC.o500)),
                      const SizedBox(width: 9),
                      Text('Léo réfléchit…', style: body(13, color: OC.muted, weight: FontWeight.w500)),
                    ])
                  : SelectableText(
                      m.content,
                      style: body(14, weight: FontWeight.w500, color: isUser ? Colors.white : OC.ink).copyWith(height: 1.42),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: body(14.5, color: OC.ink),
              decoration: InputDecoration(
                hintText: 'Pose ta question d\'orientation…',
                hintStyle: body(14, color: OC.muted),
                filled: true,
                fillColor: OC.paper,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: OC.line2, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: OC.line2, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: OC.o500, width: 2)),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: _sending ? null : () => _send(),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _sending ? OC.o600.withValues(alpha: 0.5) : OC.o600,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}
