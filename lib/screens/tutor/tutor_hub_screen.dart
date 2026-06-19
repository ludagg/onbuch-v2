import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../ai_config.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../widgets/paywall_sheet.dart';

/// Page principale du Tuteur — direction « Tableau de bord » (option C des
/// wireframes) : scan + quota + 3 modes (Corriger · Expliquer · S'entraîner) +
/// reprise des corrections récentes.
class TutorHubScreen extends StatefulWidget {
  const TutorHubScreen({super.key});

  @override
  State<TutorHubScreen> createState() => _TutorHubScreenState();
}

class _TutorHubScreenState extends State<TutorHubScreen> {
  final _service = TutorService();
  final _picker = ImagePicker();
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

  Future<void> _open(TutorRequest req) async {
    await context.push('/tutor/correction', extra: req);
    if (mounted) {
      setState(() => _recent = _service.recentJobs());
      _loadQuota();
    }
  }

  bool _blockedByQuota() {
    if (_quota != null && !_quota!.canAsk) {
      PaywallSheet.show(context).then((_) {
        if (mounted) _loadQuota();
      });
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
      await _open(TutorRequest(image: bytes));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Impossible d\'ouvrir la caméra/galerie.');
    }
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
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Scan (action primaire) ────────────────────────────────────────
          Row(children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 7))],
                  ),
                  child: Center(
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 9),
                            Text('Scanner un exercice', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
                          ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: OC.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OC.line2, width: 1.5),
                ),
                child: const Icon(Icons.image_outlined, color: OC.ink2, size: 23),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Quota ─────────────────────────────────────────────────────────
          _quotaCard(),
          const SizedBox(height: 22),

          // ── Modes ─────────────────────────────────────────────────────────
          Text('Que veux-tu faire ?', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 12),
          Row(children: [
            _mode('Corriger', Icons.fact_check_outlined, () => context.push('/tutor/corriger')),
            const SizedBox(width: 11),
            _mode('Expliquer', Icons.school_outlined, () => context.push('/tutor/expliquer')),
            const SizedBox(width: 11),
            _mode('S\'entraîner', Icons.fitness_center_rounded, () => context.push('/tutor/entrainer')),
          ]),
          const SizedBox(height: 24),

          // ── Reprendre ─────────────────────────────────────────────────────
          Text('Reprendre', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
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

  Widget _mode(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: OC.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OC.line, width: 1.5),
          ),
          child: Column(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, size: 22, color: OC.o600),
            ),
            const SizedBox(height: 9),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11.5, weight: FontWeight.w700, color: OC.ink2)),
          ]),
        ),
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
          Text(credits > 0 ? 'Réinitialisé chaque jour · $credits crédits' : 'Réinitialisé chaque jour · recharge via Google Play',
              style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ])),
        GestureDetector(
          onTap: () => PaywallSheet.show(context).then((_) { if (mounted) _loadQuota(); }),
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
}
