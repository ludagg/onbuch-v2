import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../widgets/paywall_sheet.dart';

// ── Outils partagés aux 3 modes ──────────────────────────────────────────────
mixin _TutorMode<T extends StatefulWidget> on State<T> {
  final TutorService tutor = TutorService();
  TutorQuota? quota;

  @override
  void initState() {
    super.initState();
    tutor.getQuota().then((q) {
      if (mounted) setState(() => quota = q);
    });
  }

  bool blocked() {
    if (quota != null && !quota!.canAsk) {
      PaywallSheet.show(context);
      return true;
    }
    return false;
  }

  void send(TutorRequest req) {
    if (blocked()) return;
    context.push('/tutor/correction', extra: req);
  }

  void toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }
}

PreferredSizeWidget _bar(BuildContext context, String title) => AppBar(
      backgroundColor: OC.bg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.canPop() ? context.pop() : context.go('/tutor'),
      ),
      title: Text(title, style: display(17, weight: FontWeight.w700)),
    );

Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? OC.ink : OC.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? OC.ink : OC.line2, width: 1.5),
        ),
        child: Text(label, style: body(12.5, weight: FontWeight.w700, color: on ? Colors.white : OC.ink2)),
      ),
    );

Widget _sectionLabel(String t) => Text(t, style: body(13, weight: FontWeight.w800, color: OC.ink2));

const _subjects = ['Maths', 'Physique', 'SVT', 'Philo', 'Français'];

// ═══════════════════════════ CORRIGER ═══════════════════════════
class TutorCorrigerScreen extends StatefulWidget {
  const TutorCorrigerScreen({super.key});
  @override
  State<TutorCorrigerScreen> createState() => _TutorCorrigerScreenState();
}

class _TutorCorrigerScreenState extends State<TutorCorrigerScreen> with _TutorMode {
  final _picker = ImagePicker();
  final _text = TextEditingController();
  String? _subject;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy || blocked()) return;
    setState(() => _busy = true);
    try {
      final f = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 90);
      if (f == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() => _busy = false);
      send(TutorRequest(image: bytes, subject: _subject));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      toast('Impossible d\'ouvrir la caméra/galerie.');
    }
  }

  void _sendText() {
    final t = _text.text.trim();
    if (t.isEmpty) {
      toast('Écris ton exercice d\'abord.');
      return;
    }
    FocusScope.of(context).unfocus();
    send(TutorRequest(question: t, subject: _subject));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: _bar(context, 'Corriger'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Photographie, importe ou écris l\'exercice à corriger.',
              style: body(13, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 16),
          _sectionLabel('Matière (optionnel)'),
          const SizedBox(height: 10),
          Wrap(children: _subjects.map((s) => _chip(s, _subject == s,
              () => setState(() => _subject = _subject == s ? null : s))).toList()),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pick(ImageSource.camera),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: OC.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OC.line2, width: 1.5, style: BorderStyle.solid),
              ),
              child: Column(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                  child: _busy
                      ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 10),
                Text('Cadre la copie ou l\'énoncé', style: body(12.5, color: OC.ink2, weight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(child: _actionBtn('Scanner', Icons.camera_alt_outlined, true, () => _pick(ImageSource.camera))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Importer', Icons.image_outlined, false, () => _pick(ImageSource.gallery))),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Ou écris l\'exercice'),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: 2, maxLines: 5,
            style: body(13.5, color: OC.ink),
            decoration: InputDecoration(
              hintText: 'Ex : Résous dans ℝ : x² − 5x + 6 = 0',
              hintStyle: body(13, color: OC.muted),
              filled: true, fillColor: OC.paper,
              contentPadding: const EdgeInsets.all(13),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.o500, width: 2)),
            ),
          ),
          const SizedBox(height: 11),
          _primaryBtn('Corriger ce texte', Icons.auto_awesome_rounded, _sendText),
        ]),
      ),
    );
  }
}

// ═══════════════════════════ EXPLIQUER ═══════════════════════════
class TutorExpliquerScreen extends StatefulWidget {
  const TutorExpliquerScreen({super.key});
  @override
  State<TutorExpliquerScreen> createState() => _TutorExpliquerScreenState();
}

class _TutorExpliquerScreenState extends State<TutorExpliquerScreen> with _TutorMode {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _explain(String notion) {
    final q = notion.trim();
    if (q.isEmpty) {
      toast('Indique une notion à expliquer.');
      return;
    }
    FocusScope.of(context).unfocus();
    send(TutorRequest(question: 'Explique-moi clairement, avec un exemple : $q', titleHint: q));
  }

  static const _popular = ['Théorème de Thalès', 'Nombres complexes', 'Photosynthèse', 'Dérivées', 'Lois de Newton'];
  static const _bySubject = [
    ('Maths — Fonctions & limites', Icons.functions_rounded),
    ('Physique — Lois de Newton', Icons.science_outlined),
    ('SVT — La photosynthèse', Icons.eco_outlined),
    ('Philo — Le bonheur', Icons.psychology_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: _bar(context, 'Expliquer'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            decoration: BoxDecoration(
              color: OC.paper,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: OC.ink, width: 1.6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 18, color: OC.ink2),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                onSubmitted: _explain,
                style: body(13.5, color: OC.ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: InputBorder.none,
                  hintText: 'Un cours, une notion, un mot…',
                  hintStyle: body(13.5, color: OC.muted),
                ),
              )),
              GestureDetector(
                onTap: () => _explain(_text.text),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: OC.o500, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _sectionLabel('Notions populaires'),
          const SizedBox(height: 10),
          Wrap(children: _popular.map((n) => _chip(n, false, () => _explain(n))).toList()),
          const SizedBox(height: 12),
          _sectionLabel('Par matière'),
          const SizedBox(height: 10),
          ..._bySubject.map((s) => GestureDetector(
                onTap: () => _explain(s.$1),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.line, width: 1.5)),
                  child: Row(children: [
                    Icon(s.$2, size: 19, color: OC.o600),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.$1, style: body(13, weight: FontWeight.w600))),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
                  ]),
                ),
              )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════ S'ENTRAÎNER ═══════════════════════════
class TutorEntrainerScreen extends StatefulWidget {
  const TutorEntrainerScreen({super.key});
  @override
  State<TutorEntrainerScreen> createState() => _TutorEntrainerScreenState();
}

class _TutorEntrainerScreenState extends State<TutorEntrainerScreen> with _TutorMode {
  final _chapter = TextEditingController();
  String _subject = 'Maths';
  int _difficulty = 1; // 0=Facile,1=Moyen,2=Difficile
  int _count = 1; // index into _counts

  static const _diffs = ['Facile', 'Moyen', 'Difficile'];
  static const _counts = [3, 5, 10];

  @override
  void dispose() {
    _chapter.dispose();
    super.dispose();
  }

  void _generate() {
    final chap = _chapter.text.trim();
    final diff = _diffs[_difficulty].toLowerCase();
    final n = _counts[_count];
    final q = 'Génère $n exercices de $_subject de niveau $diff'
        '${chap.isEmpty ? '' : ' sur le chapitre « $chap »'}, '
        'numérotés, avec un corrigé détaillé pour chacun.';
    send(TutorRequest(question: q, subject: _subject, titleHint: chap.isEmpty ? '$_subject · $diff' : chap));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: _bar(context, 'S\'entraîner'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Génère des exercices sur mesure, avec corrigés.',
              style: body(13, color: OC.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 18),
          _sectionLabel('Matière'),
          const SizedBox(height: 10),
          Wrap(children: _subjects.map((s) => _chip(s, _subject == s, () => setState(() => _subject = s))).toList()),
          const SizedBox(height: 14),
          _sectionLabel('Chapitre (optionnel)'),
          const SizedBox(height: 10),
          TextField(
            controller: _chapter,
            style: body(13.5, color: OC.ink),
            decoration: InputDecoration(
              hintText: 'Ex : Équations du 2nd degré',
              hintStyle: body(13, color: OC.muted),
              filled: true, fillColor: OC.paper,
              contentPadding: const EdgeInsets.all(13),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.o500, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Difficulté'),
          const SizedBox(height: 10),
          Wrap(children: List.generate(_diffs.length, (i) => _chip(_diffs[i], _difficulty == i, () => setState(() => _difficulty = i)))),
          const SizedBox(height: 14),
          _sectionLabel('Nombre d\'exercices'),
          const SizedBox(height: 10),
          Wrap(children: List.generate(_counts.length, (i) => _chip('${_counts[i]}', _count == i, () => setState(() => _count = i)))),
          const SizedBox(height: 22),
          _primaryBtn('Générer les exercices', Icons.bolt_rounded, _generate),
        ]),
      ),
    );
  }
}

// ── Boutons partagés ─────────────────────────────────────────────────────────
Widget _actionBtn(String label, IconData icon, bool filled, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: filled ? OC.grad : null,
          color: filled ? null : OC.paper,
          borderRadius: BorderRadius.circular(13),
          border: filled ? null : Border.all(color: OC.line2, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 17, color: filled ? Colors.white : OC.ink2),
          const SizedBox(width: 8),
          Text(label, style: body(13.5, weight: FontWeight.w700, color: filled ? Colors.white : OC.ink2)),
        ]),
      ),
    );

Widget _primaryBtn(String label, IconData icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 50,
        decoration: BoxDecoration(
          gradient: OC.grad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: body(14, weight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
