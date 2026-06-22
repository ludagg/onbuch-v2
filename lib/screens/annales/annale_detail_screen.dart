import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/annale.dart';
import '../../services/database_service.dart';
import '../../services/annales_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/launch.dart';
import '../../widgets/states.dart';

/// Détail d'une épreuve : regroupe le sujet, le corrigé et la vidéo d'un même
/// examen → série → matière → année (collection `annales`).
class AnnaleDetailScreen extends StatefulWidget {
  final AnnaleRef? ref;
  const AnnaleDetailScreen({super.key, this.ref});

  @override
  State<AnnaleDetailScreen> createState() => _AnnaleDetailScreenState();
}

class _AnnaleDetailScreenState extends State<AnnaleDetailScreen> {
  final _db = DatabaseService();
  final _store = AnnalesStore.instance;

  bool _loading = true;
  bool _downloading = false;
  String _chosenYear = '';
  List<Annale> _group = const [];

  AnnaleRef get _ref => widget.ref ?? const AnnaleRef(exam: '', subject: '');

  Annale? _firstWhere(bool Function(Annale) test) {
    for (final a in _group) {
      if (test(a)) return a;
    }
    return null;
  }

  Annale? get _sujet => _firstWhere((a) => a.isSujet && a.hasFile);
  Annale? get _corrige => _firstWhere((a) => a.isCorrige && a.hasFile);
  Annale? get _video => _firstWhere((a) => a.isVideo && a.hasFile);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.ensureLoaded();
    if (_ref.exam.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final all = await _db.getAnnales(_ref.exam);
    // Documents de la matière dans cette série.
    var matching = all.where((a) =>
        a.subject == _ref.subject &&
        (_ref.track.isEmpty || a.track == _ref.track));
    // Année : celle demandée, sinon la plus récente disponible.
    var year = _ref.year;
    if (year.isEmpty) {
      final years = matching.map((a) => a.year).where((y) => y.isNotEmpty).toList()
        ..sort((a, b) => b.compareTo(a));
      year = years.isNotEmpty ? years.first : '';
    }
    final group = matching
        .where((a) => year.isEmpty || a.year == year)
        .toList();
    if (!mounted) return;
    setState(() {
      _chosenYear = year;
      _group = group;
      _loading = false;
    });
    // Trace dans « Récents ».
    if (group.isNotEmpty) {
      _store.pushRecent(AnnaleRef(
        exam: _ref.exam, track: _ref.track, subject: _ref.subject,
        year: year, title: _ref.title.isEmpty ? _ref.subject : _ref.title,
      ));
    }
  }

  String get _subtitle => [_ref.exam, _ref.track, _chosenYear]
      .where((s) => s.trim().isNotEmpty)
      .join(' · ');

  String get _session =>
      _group.isEmpty ? '' : _group.map((a) => a.session).firstWhere(
            (s) => s.isNotEmpty, orElse: () => '');

  void _openPdf(Annale a) {
    final offline = _store.localPath(a.id);
    context.push('/annales/pdf', extra: PdfArgs(
      title: a.title.isEmpty ? '${_ref.subject} · $_chosenYear' : a.title,
      subtitle: a.isCorrige ? 'Corrigé · PDF' : 'Sujet · PDF',
      url: a.fileUrl,
      localPath: offline,
    ));
  }

  void _onResourceTap(Annale? a, {required bool isVideoTab}) {
    if (a == null) {
      _toast('Pas encore disponible pour cette épreuve.');
      return;
    }
    if (a.premium) {
      _toast('Contenu premium — bientôt disponible.');
      return;
    }
    if (isVideoTab || a.isVideo) {
      openUrl(context, a.fileUrl);
    } else {
      _openPdf(a);
    }
  }

  Future<void> _toggleDownload(Annale sujet) async {
    if (_store.isDownloaded(sujet.id)) {
      await _store.removeDownload(sujet.id);
      if (mounted) setState(() {});
      return;
    }
    setState(() => _downloading = true);
    final ok = await _store.download(sujet);
    if (!mounted) return;
    setState(() => _downloading = false);
    _toast(ok ? 'Disponible hors-ligne ✓' : 'Téléchargement impossible.');
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
    final fav = _store.isFavorite(_ref.groupKey);
    final sujet = _sujet;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_ref.subject.isEmpty ? 'Épreuve' : _ref.subject,
              style: display(17, weight: FontWeight.w700)),
          if (_subtitle.isNotEmpty)
            Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
        ),
        actions: [
          IconButton(
            icon: Icon(fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 20, color: fav ? OC.o600 : OC.ink2),
            onPressed: () async {
              await _store.toggleFavorite(AnnaleRef(
                exam: _ref.exam, track: _ref.track, subject: _ref.subject,
                year: _chosenYear, title: _ref.title.isEmpty ? _ref.subject : _ref.title,
              ));
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _group.isEmpty
              ? EmptyState(
                  icon: Icons.description_outlined,
                  title: 'Épreuve indisponible',
                  message: 'Aucun document pour cette matière pour le moment.',
                  actionLabel: 'Retour', onAction: () => context.pop())
              : _content(sujet),
    );
  }

  Widget _content(Annale? sujet) {
    final corrige = _corrige;
    final video = _video;
    final downloaded = sujet != null && _store.isDownloaded(sujet.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cover
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: OC.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OC.line, width: 1.5),
          ),
          child: Stack(children: [
            Center(child: Icon(Icons.description_outlined, size: 60, color: OC.faint)),
            if (_session.isNotEmpty)
              Positioned(top: 10, left: 10, child: _coverTag(_session)),
            if (sujet != null)
              Positioned(right: 12, bottom: 12,
                child: GestureDetector(
                  onTap: () => _openPdf(sujet),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 10)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.visibility_outlined, size: 17, color: OC.ink),
                      const SizedBox(width: 7),
                      Text('Ouvrir le PDF', style: body(12.5, weight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 15),

        // Onglets de ressources
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => _onResourceTap(sujet, isVideoTab: false),
            child: _ResourceTab(icon: Icons.picture_as_pdf_rounded, label: 'Sujet', sub: 'PDF',
                iconC: const Color(0xFFC0392B), iconBg: const Color(0xFFFAE7E4),
                selected: true, disabled: sujet == null),
          )),
          const SizedBox(width: 9),
          Expanded(child: GestureDetector(
            onTap: () => _onResourceTap(corrige, isVideoTab: false),
            child: _ResourceTab(icon: Icons.check_circle_outline_rounded, label: 'Corrigé',
                sub: corrige == null ? '—' : (corrige.premium ? 'Premium' : 'PDF'),
                iconC: OC.good, iconBg: OC.goodBg, disabled: corrige == null,
                locked: corrige?.premium ?? false),
          )),
          const SizedBox(width: 9),
          Expanded(child: GestureDetector(
            onTap: () => _onResourceTap(video, isVideoTab: true),
            child: _ResourceTab(icon: Icons.play_circle_outline_rounded, label: 'Vidéo',
                sub: video == null ? '—' : 'Voir',
                iconC: const Color(0xFF7A5AE0), iconBg: const Color(0xFFEEE9FA),
                disabled: video == null, locked: video?.premium ?? false),
          )),
        ]),
        const SizedBox(height: 15),

        // Télécharger hors-ligne
        if (sujet != null && _store.offlineSupported)
          GestureDetector(
            onTap: _downloading ? null : () => _toggleDownload(sujet),
            child: Container(
              padding: const EdgeInsets.all(13),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Row(children: [
                Icon(downloaded ? Icons.download_done_rounded : Icons.download_rounded,
                    size: 20, color: downloaded ? OC.waInk : OC.ink2),
                const SizedBox(width: 11),
                Expanded(child: Text(
                  _downloading
                      ? 'Téléchargement…'
                      : downloaded ? 'Disponible hors-ligne' : 'Télécharger pour hors-ligne',
                  style: body(13.5, weight: FontWeight.w700))),
                if (_downloading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else if (downloaded)
                  Text('Retirer', style: body(12, weight: FontWeight.w700, color: OC.bad)),
              ]),
            ),
          ),

        // Pont Tuteur IA
        GestureDetector(
          onTap: () => context.go('/tutor'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OC.o50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OC.o100, width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bloqué·e sur un exercice ?', style: body(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Corrige-le pas-à-pas avec le Tuteur IA',
                    style: body(12, color: OC.o700, weight: FontWeight.w500)),
              ])),
              Icon(Icons.chevron_right_rounded, size: 20, color: OC.o600),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _coverTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: body(11, weight: FontWeight.w700, color: Colors.white)),
      );
}

class _ResourceTab extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color iconC, iconBg;
  final bool selected, disabled, locked;
  const _ResourceTab({required this.icon, required this.label, required this.sub,
      required this.iconC, required this.iconBg,
      this.selected = false, this.disabled = false, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? OC.line2 : OC.line, width: 1.5),
        ),
        child: Column(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
            child: Icon(locked ? Icons.lock_outline_rounded : icon, color: iconC, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: body(12.5, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: body(10, color: OC.muted, weight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
