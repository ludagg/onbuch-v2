import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../ai_config.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../widgets/paywall_sheet.dart';

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
  TutorQuota? _quota;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    final q = await _service.getQuota();
    if (mounted) setState(() => _quota = q);
  }

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
    if (mounted) {
      setState(() => _recent = _service.recentJobs());
      _loadQuota();
    }
  }

  /// Vérifie le quota côté client avant de lancer une correction (l'enforcement
  /// réel est côté serveur). Réouverture d'un job = pas de consommation.
  bool _blockedByQuota() {
    if (_quota != null && !_quota!.canAsk) {
      _showPaywall(context);
      return true;
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_busy) return;
    if (_blockedByQuota()) return;
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
    if (_blockedByQuota()) return;
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
        actions: obTopActions(context),
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

          // ── Quota (réel) ───────────────────────────────────────────────────
          _quotaCard(),
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

  Widget _quotaCard() {
    final q = _quota;
    final remaining = q?.freeRemaining ?? AIConfig.freeDaily;
    final credits = q?.credits ?? 0;
    final loading = q == null;
    return OBCard(
      child: Row(children: [
        SizedBox(
          width: 46, height: 46,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: loading ? null : (remaining / AIConfig.freeDaily).clamp(0.0, 1.0),
              strokeWidth: 5, backgroundColor: OC.o100,
              valueColor: const AlwaysStoppedAnimation(OC.o500), strokeCap: StrokeCap.round,
            ),
            if (!loading) Text('$remaining', style: mono(15, weight: FontWeight.w700, color: OC.o600)),
          ]),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$remaining / ${AIConfig.freeDaily} corrections gratuites', style: body(14, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(credits > 0 ? 'Réinitialisé chaque jour · $credits crédits' : 'Réinitialisé chaque jour · crédits dès 100 F',
              style: body(12, color: OC.muted, weight: FontWeight.w500)),
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

  void _showPaywall(BuildContext context) => PaywallSheet.show(context);
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
