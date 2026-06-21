import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../ai_config.dart';
import '../../models/tutor_request.dart';
import '../../services/tutor_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/paywall_sheet.dart';
import '../../widgets/leo_mascot.dart';

/// Page principale du Tuteur « Léo » — direction « tableau de bord » (option C)
/// modernisée avec l'accueil conversationnel (option A) : en-tête de marque,
/// salut + mascotte + suggestions, puis scan / quota / modes / reprise.
class TutorHubScreen extends StatefulWidget {
  const TutorHubScreen({super.key});

  @override
  State<TutorHubScreen> createState() => _TutorHubScreenState();
}

class _TutorHubScreenState extends State<TutorHubScreen> {
  final _service = TutorService();
  late Future<List<TutorJob>> _recent = _service.recentJobs();
  TutorQuota? _quota;
  String? _firstName = AuthService.cachedFirstName;

  @override
  void initState() {
    super.initState();
    _loadQuota();
    if (_firstName == null) _loadName();
  }

  Future<void> _loadQuota() async {
    final q = await _service.getQuota();
    if (mounted) setState(() => _quota = q);
  }

  Future<void> _loadName() async {
    final user = await AuthService().getCurrentUser();
    final name = user?.name.trim() ?? '';
    final f = name.isEmpty ? null : DatabaseService.splitFullName(name)['firstName'] as String?;
    if (mounted && f != null) setState(() => _firstName = f);
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

  Future<void> _scan() async {
    if (_blockedByQuota()) return;
    await context.push('/tutor/capture');
    if (mounted) {
      setState(() => _recent = _service.recentJobs());
      _loadQuota();
    }
  }

  void _ask(String question, {String? title}) {
    if (_blockedByQuota()) return;
    _open(TutorRequest(question: question, titleHint: title));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const OBWordmark(size: 23),
        actions: obTopActions(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Salut + mascotte (option A) ───────────────────────────────────
          _greeting(),
          const SizedBox(height: 18),

          // ── Suggestions (option A) ────────────────────────────────────────
          Text('Essaie de demander', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          _suggestion(Icons.fact_check_outlined, 'Corrige cet exercice de maths', _scan),
          _suggestion(Icons.school_outlined, 'Explique-moi le théorème de Thalès',
              () => _ask('Explique-moi clairement, avec un exemple : le théorème de Thalès.', title: 'Théorème de Thalès')),
          _suggestion(Icons.bolt_rounded, 'Génère 5 exercices similaires',
              () => _ask('Génère 5 exercices de maths de niveau lycée, variés, avec un corrigé détaillé pour chacun.', title: 'Exercices générés')),
          const SizedBox(height: 20),

          // ── Scan (action primaire) ────────────────────────────────────────
          Row(children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _scan,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 7))],
                  ),
                  child: Center(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
              onTap: _scan,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: OC.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OC.line2, width: 1.5),
                ),
                child: Icon(Icons.image_outlined, color: OC.ink2, size: 23),
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
          const SizedBox(height: 12),
          _summaryCard(),
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
                    Icon(Icons.history_rounded, size: 18, color: OC.muted),
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

  // ── Salut + mascotte ─────────────────────────────────────────────────────
  Widget _greeting() {
    final hello = _firstName == null ? 'Bonjour 👋' : 'Bonjour, $_firstName 👋';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.o50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Row(children: [
        // Mascotte Léo, animée (jamais figée).
        const SizedBox(
          width: 64, height: 64,
          child: Center(child: LeoMascot(size: 64, mood: LeoMood.wave)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hello, style: display(20, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Sur quoi bloques-tu ?', style: body(13, color: OC.o700, weight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _suggestion(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('« $text »', style: body(13, weight: FontWeight.w600, color: OC.ink2))),
          Icon(Icons.north_east_rounded, size: 16, color: OC.muted),
        ]),
      ),
    );
  }

  // Carte « Résumer un cours » → fiche de révision (gratuit).
  Widget _summaryCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await context.push('/tutor/resume');
        if (mounted) setState(() => _recent = _service.recentJobs());
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OC.o50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.o100, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: OC.o100, width: 1.5)),
            child: Icon(Icons.auto_stories_outlined, size: 22, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Résumer un cours', style: body(14.5, weight: FontWeight.w700, color: OC.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: OC.good.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                child: Text('Gratuit', style: body(10.5, weight: FontWeight.w800, color: OC.good)),
              ),
            ]),
            const SizedBox(height: 3),
            Text('Photos ou PDF → fiche de révision', style: body(12, color: OC.o700, weight: FontWeight.w600)),
          ])),
          Icon(Icons.chevron_right_rounded, color: OC.o600, size: 22),
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
            child: Icon(Icons.check_circle_outline_rounded, size: 19, color: OC.good),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(job.subject.isNotEmpty ? '${job.subject} · résolu' : 'résolu',
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }
}
