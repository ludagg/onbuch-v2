import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/concours.dart';
import '../../models/tutor_request.dart';

/// Concours blanc (section E des wireframes) : composition chronométrée comme le
/// jour J → résultat + renvoi de la copie au Tuteur. (Score : V2.1, indicatif.)
class ConcoursBlancScreen extends StatefulWidget {
  final Concours? concours;
  const ConcoursBlancScreen({super.key, this.concours});

  @override
  State<ConcoursBlancScreen> createState() => _ConcoursBlancScreenState();
}

enum _Phase { intro, compose, result }

class _ConcoursBlancScreenState extends State<ConcoursBlancScreen> {
  _Phase _phase = _Phase.intro;
  final _answer = TextEditingController();
  int _attachments = 0;

  static const _total = Duration(hours: 4);
  Duration _left = _total;
  Timer? _timer;

  static const _subject = 'Mathématiques';
  static const _statement =
      'Exercice · Probabilités. Une urne contient 5 boules rouges et 3 boules vertes. '
      'On tire successivement et sans remise deux boules. Calculer la probabilité d\'obtenir '
      'deux boules de la même couleur, puis l\'espérance du nombre de boules rouges tirées.';

  @override
  void dispose() {
    _timer?.cancel();
    _answer.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.compose;
      _left = _total;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left.inSeconds <= 1) {
        _submit();
      } else {
        setState(() => _left -= const Duration(seconds: 1));
      }
    });
  }

  void _submit() {
    _timer?.cancel();
    FocusScope.of(context).unfocus();
    setState(() => _phase = _Phase.result);
  }

  Future<void> _attach() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (x != null && mounted) setState(() => _attachments += 1);
    } catch (_) {}
  }

  void _reviewWithTutor() {
    final txt = _answer.text.trim();
    final question = 'Voici un sujet de concours blanc et ma copie. '
        'Corrige-la, note-la sur 20 et explique mes erreurs.\n\n'
        'SUJET : $_statement\n\nMA COPIE : ${txt.isEmpty ? '(aucune réponse rédigée)' : txt}';
    context.push('/tutor/correction',
        extra: TutorRequest(question: question, subject: 'Concours blanc · $_subject', titleHint: 'Concours blanc'));
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_phase == _Phase.compose) {
              _confirmQuit();
            } else {
              context.canPop() ? context.pop() : context.go('/concours');
            }
          },
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Concours blanc', style: display(16, weight: FontWeight.w700)),
          Text(widget.concours?.name ?? 'Comme le jour J',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ),
      body: switch (_phase) {
        _Phase.intro => _intro(),
        _Phase.compose => _compose(),
        _Phase.result => _result(),
      },
    );
  }

  void _confirmQuit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OC.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Quitter l\'épreuve ?', style: display(17, weight: FontWeight.w700)),
        content: Text('Ta composition en cours sera perdue.', style: body(13.5, color: OC.ink2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Continuer', style: body(13.5, weight: FontWeight.w700, color: OC.ink2))),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(ctx);
              context.canPop() ? context.pop() : context.go('/concours');
            },
            child: Text('Quitter', style: body(13.5, weight: FontWeight.w700, color: OC.bad)),
          ),
        ],
      ),
    );
  }

  // ── Intro ──
  Widget _intro() {
    const rules = [
      'Minuteur réel de 4 h, comme au concours',
      'Compose librement puis soumets ta copie',
      'Correction et note par le Tuteur IA',
      'Score & classement estimé (indicatif)',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OC.o100, width: 1.5)),
          child: Column(children: [
            const Icon(Icons.edit_note_rounded, size: 34, color: OC.o600),
            const SizedBox(height: 8),
            Text('Épreuve de $_subject', style: display(20, weight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Format concours · 4 h · chronométré', style: body(12.5, color: OC.o700, weight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Règles', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        ...rules.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(r, style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.35))),
              ]),
            )),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Démarrer l\'épreuve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            onPressed: _start,
          ),
        ),
      ]),
    );
  }

  // ── Composition ──
  Widget _compose() {
    final warn = _left.inMinutes < 15;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(children: [
          Icon(Icons.timer_outlined, size: 18, color: warn ? OC.bad : OC.o600),
          const SizedBox(width: 8),
          Text(_fmt(_left), style: mono(17, weight: FontWeight.w800, color: warn ? OC.bad : OC.ink)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(7)),
            child: Text('Sujet · $_subject', style: body(10.5, weight: FontWeight.w700, color: OC.ink2)),
          ),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
            child: Text(_statement, style: body(13, color: OC.ink, weight: FontWeight.w500).copyWith(height: 1.5)),
          ),
          const SizedBox(height: 16),
          Text('Ta réponse', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 8),
          TextField(
            controller: _answer,
            maxLines: 10, minLines: 6,
            style: body(14, color: OC.ink, weight: FontWeight.w500).copyWith(height: 1.5),
            decoration: InputDecoration(
              hintText: 'Rédige ta composition ici…',
              hintStyle: body(13.5, color: OC.muted),
              filled: true, fillColor: OC.paper,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.line2, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OC.o500, width: 2)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: OC.line2, width: 1.5), foregroundColor: OC.ink2,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.attach_file_rounded, size: 17),
              label: Text(_attachments == 0 ? 'Joindre une photo' : '$_attachments pièce(s) jointe(s)',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _attach,
            )),
          ]),
        ]),
      )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _submit,
            child: const Text('Terminer & soumettre', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ),
      )),
    ]);
  }

  // ── Résultat ──
  Widget _result() {
    const breakdown = [
      ('Exercice 1', '4,5 / 5', true),
      ('Exercice 2', '3 / 5', false),
      ('Exercice 3', '6 / 10', false),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text('13,5 / 20', style: display(28, weight: FontWeight.w800, color: OC.o600)),
            const SizedBox(height: 4),
            Text('Classement estimé : top 18 %', style: body(13, color: OC.o700, weight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Détail par exercice', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        ...breakdown.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: OC.line, width: 1.5)),
              child: Row(children: [
                Icon(r.$3 ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    size: 18, color: r.$3 ? OC.good : OC.warn),
                const SizedBox(width: 10),
                Expanded(child: Text(r.$1, style: body(13, weight: FontWeight.w700))),
                Text(r.$2, style: body(13, weight: FontWeight.w800)),
              ]),
            )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Revoir mes erreurs avec le Tuteur', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _reviewWithTutor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(11)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 15, color: OC.muted),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Score indicatif (V2.1). La correction détaillée est faite par le Tuteur sur ta vraie copie.',
              style: body(11.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.35),
            )),
          ]),
        ),
      ]),
    );
  }
}
