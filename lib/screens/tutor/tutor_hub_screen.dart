import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';

class TutorHubScreen extends StatefulWidget {
  const TutorHubScreen({super.key});

  @override
  State<TutorHubScreen> createState() => _TutorHubScreenState();
}

class _TutorHubScreenState extends State<TutorHubScreen> {
  final _service = TutorService();
  final _picker = ImagePicker();
  final _textCtrl = TextEditingController();
  String? _subject;
  bool _busy = false;
  late Future<List<TutorJob>> _recent = _service.recentJobs();

  static const _subjects = [
    ('Maths', Color(0xFF2D6CDF), Color(0xFFE7EEFB)),
    ('Physique', OC.good, OC.goodBg),
    ('SVT', Color(0xFF0E9AA0), Color(0xFFE1F2F2)),
    ('Philo', Color(0xFF7A5AE0), Color(0xFFEEE9FA)),
    ('Français', Color(0xFFDB4F12), Color(0xFFFDEBE2)),
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _open(TutorRequest req) async {
    await context.push('/tutor/correction', extra: req);
    if (mounted) setState(() => _recent = _service.recentJobs());
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 90);
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _busy = false);
      await _open(TutorRequest(image: bytes, subject: _subject));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Impossible d\'ouvrir la caméra/galerie.');
    }
  }

  void _askText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _toast('Écris ton exercice d\'abord.');
      return;
    }
    FocusScope.of(context).unfocus();
    _textCtrl.clear();
    _open(TutorRequest(question: text, subject: _subject));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tuteur IA', style: display(17, weight: FontWeight.w700)),
          Text('Programme MINESEC · français', style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Hero : photographie ton exercice ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 26, offset: const Offset(0, 10))],
            ),
            child: Stack(children: [
              Positioned(top: -60, right: -40, child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)),
                  child: _busy
                      ? const Padding(padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 14),
                Text('Photographie\nton exercice', style: display(21, weight: FontWeight.w600, color: Colors.white).copyWith(height: 1.1)),
                const SizedBox(height: 6),
                Text('Correction, explication pas-à-pas et réponse adaptées à ton programme.',
                    style: body(13, color: Colors.white.withValues(alpha: 0.9)).copyWith(height: 1.4)),
                const SizedBox(height: 16),
                Row(children: [
                  _heroBtn('Scanner', Icons.camera_alt_outlined, true, () => _pickImage(ImageSource.camera)),
                  const SizedBox(width: 10),
                  _heroBtn('Importer', Icons.image_outlined, false, () => _pickImage(ImageSource.gallery)),
                ]),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Saisie texte (nouvelle fonctionnalité) ────────────────────────
          OBCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.edit_note_rounded, size: 20, color: OC.o600),
                const SizedBox(width: 8),
                Text('Écris ou colle ton exercice', style: body(13.5, weight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                minLines: 2,
                textInputAction: TextInputAction.newline,
                style: body(13.5, color: OC.ink),
                decoration: InputDecoration(
                  hintText: 'Ex : Résous dans IR : x² − 5x + 6 = 0',
                  hintStyle: body(13, color: OC.muted),
                  filled: true,
                  fillColor: OC.bg,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.line2, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OC.o500, width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _askText,
                child: Container(
                  width: double.infinity, height: 46,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Corriger ce texte', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Quota (statique pour l'instant) ────────────────────────────────
          OBCard(
            child: Row(children: [
              SizedBox(
                width: 46, height: 46,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: 2 / 3, strokeWidth: 5, backgroundColor: OC.o100,
                    valueColor: const AlwaysStoppedAnimation(OC.o500), strokeCap: StrokeCap.round,
                  ),
                  Text('2', style: mono(15, weight: FontWeight.w700, color: OC.o600)),
                ]),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('2 / 3 corrections gratuites', style: body(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Réinitialisé chaque jour · crédits dès 100 F', style: body(12, color: OC.muted, weight: FontWeight.w500)),
              ])),
              GestureDetector(
                onTap: () => _showPaywall(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: OC.o50, border: Border.all(color: OC.o100, width: 1.5), borderRadius: BorderRadius.circular(12)),
                  child: Text('Recharger', style: body(12.5, weight: FontWeight.w700, color: OC.o700)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Matières (contexte) ────────────────────────────────────────────
          Text('Matière (optionnel)', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in _subjects) ...[
                _SubjectChip(
                  label: s.$1, c: s.$2, bg: s.$3,
                  selected: _subject == s.$1,
                  onTap: () => setState(() => _subject = _subject == s.$1 ? null : s.$1),
                ),
                const SizedBox(width: 9),
              ],
            ]),
          ),
          const SizedBox(height: 18),

          // ── Corrections récentes (dynamiques) ──────────────────────────────
          Text('Corrections récentes', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          FutureBuilder<List<TutorJob>>(
            future: _recent,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: OC.o500))),
                );
              }
              final jobs = snap.data ?? const <TutorJob>[];
              if (jobs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OC.paper, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OC.line, width: 1.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.history_rounded, size: 18, color: OC.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Tes corrections apparaîtront ici.',
                        style: body(13, color: OC.muted, weight: FontWeight.w500))),
                  ]),
                );
              }
              return Column(children: jobs.map(_recentTile).toList());
            },
          ),
        ]),
      ),
    );
  }

  Widget _recentTile(TutorJob job) {
    return GestureDetector(
      onTap: () => _open(TutorRequest(jobId: job.id, titleHint: job.title, subject: job.subject)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: OC.paper, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.check_circle_outline_rounded, size: 19, color: OC.good),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(job.subject.isNotEmpty ? '${job.subject} · résolu' : 'résolu',
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _heroBtn(String label, IconData icon, bool filled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          Icon(icon, color: filled ? OC.o600 : Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: body(14, weight: FontWeight.w700, color: filled ? OC.o600 : Colors.white)),
        ]),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _PaywallSheet(),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final Color c, bg;
  final bool selected;
  final VoidCallback onTap;
  const _SubjectChip({required this.label, required this.c, required this.bg, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c : Colors.transparent, width: 1.8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) ...[Icon(Icons.check_rounded, size: 14, color: c), const SizedBox(width: 5)],
            Text(label, style: body(13, weight: FontWeight.w700, color: c)),
          ]),
        ),
      );
}

class _PaywallSheet extends StatefulWidget {
  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  int _selectedPack = 1;
  int _selectedPayment = 0;

  static const _packs = [('5 crédits', '100 F'), ('15 crédits', '250 F'), ('40 crédits', '500 F')];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 5, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 16),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5)),
          child: const Icon(Icons.bolt_rounded, size: 28, color: OC.o500),
        ),
        const SizedBox(height: 12),
        Text('Quota du jour atteint', style: display(21, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Recharge des crédits pour continuer maintenant — ou reviens demain (gratuit).',
            textAlign: TextAlign.center, style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.45)),
        const SizedBox(height: 18),
        Row(children: List.generate(_packs.length, (i) {
          final p = _packs[i];
          final sel = i == _selectedPack;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPack = i),
              child: Stack(clipBehavior: Clip.none, children: [
                if (sel) Positioned(top: -9, left: 0, right: 0, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(999)),
                  child: Text('POPULAIRE', style: body(9, weight: FontWeight.w800, color: Colors.white)),
                ))),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: sel ? OC.o50 : OC.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? OC.o500 : OC.line, width: sel ? 2 : 1.5),
                  ),
                  child: Column(children: [
                    Text(p.$2, style: display(15, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(p.$1, style: body(11, color: OC.muted, weight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ));
        })),
        const SizedBox(height: 18),
        Text('Payer avec', style: body(12, weight: FontWeight.w800, color: OC.ink2)),
        const SizedBox(height: 10),
        Row(children: [
          _PayMethod(0, OC.mtn, 'MTN', 'MTN MoMo', _selectedPayment == 0, () => setState(() => _selectedPayment = 0)),
          const SizedBox(width: 10),
          _PayMethod(1, OC.orange, 'Or.', 'Orange Money', _selectedPayment == 1, () => setState(() => _selectedPayment = 1)),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            gradient: OC.grad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Payer ${_packs[_selectedPack].$2} · ${_selectedPayment == 0 ? 'MTN MoMo' : 'Orange Money'}',
                style: body(14, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
          ]),
        ),
        const SizedBox(height: 10),
        Text('Micro-paiement ponctuel · sans abonnement', style: body(11, color: OC.muted, weight: FontWeight.w500)),
      ]),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final int idx;
  final Color c;
  final String abbr, name;
  final bool selected;
  final VoidCallback onTap;
  const _PayMethod(this.idx, this.c, this.abbr, this.name, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? OC.o500 : OC.line, width: selected ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(abbr, style: body(9, weight: FontWeight.w900, color: c == OC.mtn ? Colors.black : Colors.white))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: body(12.5, weight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: selected ? OC.o500 : Colors.transparent,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: OC.line2, width: 2),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null,
          ),
        ]),
      ),
    ));
  }
}
