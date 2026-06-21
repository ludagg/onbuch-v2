import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../ai_config.dart';
import '../../models/tutor_request.dart';
import '../../models/review.dart';
import '../../models/course.dart';
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
  final _db = DatabaseService();
  late Future<List<TutorJob>> _recent = _service.recentJobs();
  late Future<List<TutorThread>> _threads = _service.recentThreads(limit: 6);
  late Future<List<ReviewItem>> _due = _db.dueReviews();
  TutorQuota? _quota;
  String? _firstName = AuthService.cachedFirstName;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuota();
    if (_firstName == null) _loadName();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _sendTyped() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _ctrl.clear();
    FocusScope.of(context).unfocus();
    _ask(q, title: q);
  }

  void _openPlus() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: OC.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 38, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          _plusOption(Icons.camera_alt_rounded, 'Scanner un exercice', 'Photo ou galerie', () { Navigator.pop(ctx); _scan(); }),
          _plusOption(Icons.auto_stories_outlined, 'Résumer un cours', 'Photos / PDF → fiche', () { Navigator.pop(ctx); context.push('/tutor/resume'); }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _plusOption(IconData icon, String title, String sub, VoidCallback onTap) => ListTile(
        leading: Container(
          width: 40, height: 40, alignment: Alignment.center,
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: OC.o600),
        ),
        title: Text(title, style: body(14.5, weight: FontWeight.w700, color: OC.ink)),
        subtitle: Text(sub, style: body(12, color: OC.muted, weight: FontWeight.w500)),
        onTap: onTap,
      );

  // Composeur de saisie (style chat) : tape ta question, « + » pour scanner.
  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.line2, width: 1.5),
        boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _ctrl,
          minLines: 1, maxLines: 5,
          style: body(15, color: OC.ink),
          onSubmitted: (_) => _sendTyped(),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'Pose ta question à Léo…',
            hintStyle: body(15, color: OC.muted, weight: FontWeight.w500),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: _openPlus,
            child: Container(
              width: 38, height: 38, alignment: Alignment.center,
              decoration: BoxDecoration(color: OC.bg, shape: BoxShape.circle, border: Border.all(color: OC.line2, width: 1.5)),
              child: Icon(Icons.add_rounded, size: 22, color: OC.ink2),
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (_, val, __) {
              final on = val.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: on ? _sendTyped : null,
                child: Container(
                  width: 40, height: 40, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: on ? OC.grad : null,
                    color: on ? null : OC.line2,
                    shape: BoxShape.circle,
                    boxShadow: on ? [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 5))] : null,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 21),
                ),
              );
            },
          ),
        ]),
      ]),
    );
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
      setState(() {
        _recent = _service.recentJobs();
        _threads = _service.recentThreads(limit: 6);
      });
      _loadQuota();
    }
  }

  Future<void> _openThread(TutorThread t) async {
    final messages = await _service.getThreadMessages(t.id);
    if (!mounted) return;
    _open(TutorRequest(
      threadId: t.id,
      threadMessages: messages,
      subject: t.subject,
      titleHint: t.title,
    ));
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
          const SizedBox(height: 16),

          // ── Composeur (saisie directe d'une question) ─────────────────────
          _composer(),
          const SizedBox(height: 20),

          // ── Suggestions (option A) ────────────────────────────────────────
          Text('Essaie de demander', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          _suggestion(Icons.school_outlined, 'Explique-moi le théorème de Thalès',
              () => _ask('Explique-moi clairement, avec un exemple : le théorème de Thalès.', title: 'Théorème de Thalès')),
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
          const SizedBox(height: 12),
          _coachCard(),
          const SizedBox(height: 24),

          // ── Révisions du jour (révision espacée) ──────────────────────────
          FutureBuilder<List<ReviewItem>>(
            future: _due,
            builder: (context, snap) {
              final due = snap.data ?? const <ReviewItem>[];
              if (due.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Révisions du jour', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999)),
                    child: Text('${due.length}', style: body(11, weight: FontWeight.w800, color: OC.o700)),
                  ),
                ]),
                const SizedBox(height: 10),
                ...due.take(4).map(_reviewTile),
                const SizedBox(height: 22),
              ]);
            },
          ),

          // ── Mes discussions (mémoire conversationnelle) ───────────────────
          FutureBuilder<List<TutorThread>>(
            future: _threads,
            builder: (context, snap) {
              final threads = snap.data ?? const <TutorThread>[];
              if (threads.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mes discussions', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 10),
                ...threads.map(_threadTile),
                const SizedBox(height: 22),
              ]);
            },
          ),

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
    final hello = _firstName == null ? 'Salut 👋' : 'Salut, $_firstName 👋';
    return SizedBox(
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Mascotte Léo, animée (jamais figée).
        const LeoMascot(size: 72, mood: LeoMood.wave),
        const SizedBox(height: 10),
        Text(hello, textAlign: TextAlign.center, style: display(20, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Sur quoi bloques-tu ?', textAlign: TextAlign.center,
            style: body(13, color: OC.o700, weight: FontWeight.w600)),
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

  Future<void> _openReview(ReviewItem r) async {
    final chapters = await _db.getChapters();
    Chapter? ch;
    for (final c in chapters) {
      if (c.id == r.chapterId) { ch = c; break; }
    }
    if (!mounted || ch == null) return;
    await context.push('/cours-quiz', extra: {'chapter': ch, 'subject': r.subject});
    if (mounted) setState(() => _due = _db.dueReviews());
  }

  // Carte « Mon coach » → tableau de bord (compte à rebours, points faibles…).
  Widget _coachCard() {
    return GestureDetector(
      onTap: () async {
        await context.push('/tutor/coach');
        if (mounted) setState(() => _due = _db.dueReviews());
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.insights_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mon coach', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 3),
            Text('Compte à rebours, points faibles, plan de révision',
                style: body(12, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.8), size: 22),
        ]),
      ),
    );
  }

  Widget _reviewTile(ReviewItem r) {
    final label = r.topic.isNotEmpty ? r.topic : 'Chapitre à réviser';
    return GestureDetector(
      onTap: () => _openReview(r),
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
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.refresh_rounded, size: 19, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(r.subject.isNotEmpty ? '${r.subject} · à réviser' : 'à réviser',
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
        ]),
      ),
    );
  }

  Widget _threadTile(TutorThread t) {
    return GestureDetector(
      onTap: () => _openThread(t),
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
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.forum_outlined, size: 19, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(t.subject.isNotEmpty ? '${t.subject} · reprendre' : 'reprendre la discussion',
                style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: OC.muted),
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
