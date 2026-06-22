import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/annale.dart';
import '../../services/annale_store.dart';

/// Page d'un document (épreuve/cours/fiche) : aperçu + ressources (Sujet PDF,
/// Corrigé, Vidéo) ouvertes dans les lecteurs intégrés, + passerelle Tuteur IA.
/// Données réelles passées via `extra` (un [Annale]).
class AnnaleDetailScreen extends StatefulWidget {
  final Annale? annale;
  const AnnaleDetailScreen({super.key, this.annale});

  @override
  State<AnnaleDetailScreen> createState() => _AnnaleDetailScreenState();
}

class _AnnaleDetailScreenState extends State<AnnaleDetailScreen> {
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    final a = widget.annale;
    if (a != null) {
      AnnaleStore.instance.recordRecent(a);
      AnnaleStore.instance.isFavorite(a.id).then((v) {
        if (mounted) setState(() => _fav = v);
      });
    }
  }

  Future<void> _toggleFav() async {
    final a = widget.annale;
    if (a == null) return;
    final now = await AnnaleStore.instance.toggleFavorite(a);
    if (mounted) setState(() => _fav = now);
  }

  String get _subtitle {
    final a = widget.annale;
    if (a == null) return '';
    return [a.track, a.year].where((e) => e.isNotEmpty).join(' · ');
  }

  Map<String, dynamic> _extra(String url) {
    final a = widget.annale;
    return {
      'url': url,
      'title': a?.title ?? 'Document',
      'subtitle': [a?.exam ?? '', a?.track ?? ''].where((e) => e.isNotEmpty).join(' · '),
    };
  }

  void _openPdf(String url) => context.push('/annales/pdf', extra: _extra(url));
  void _openVideo(String url) => context.push('/annales/video', extra: _extra(url));

  @override
  Widget build(BuildContext context) {
    final a = widget.annale;
    if (a == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: AppBar(
          backgroundColor: OC.bg,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
          ),
        ),
        body: Center(child: Text('Document indisponible.', style: body(14, color: OC.muted))),
      );
    }

    void Function()? primary;
    String primaryLabel = 'Ouvrir';
    IconData primaryIcon = Icons.visibility_outlined;
    if (a.hasPdf) {
      primary = () => _openPdf(a.fileUrl);
      primaryLabel = 'Ouvrir le PDF';
    } else if (a.hasVideo) {
      primary = () => _openVideo(a.videoUrl);
      primaryLabel = 'Lire la vidéo';
      primaryIcon = Icons.play_arrow_rounded;
    } else if (a.hasCorrige) {
      primary = () => _openPdf(a.corrigeUrl);
      primaryLabel = 'Ouvrir le corrigé';
    }

    final tabs = <Widget>[
      if (a.hasPdf)
        Expanded(child: GestureDetector(
          onTap: () => _openPdf(a.fileUrl),
          child: const _ResourceTab(icon: Icons.picture_as_pdf_rounded, label: 'Sujet', sub: 'PDF', iconC: Color(0xFFC0392B), iconBg: Color(0xFFFAE7E4)),
        )),
      if (a.hasCorrige)
        Expanded(child: GestureDetector(
          onTap: () => _openPdf(a.corrigeUrl),
          child: _ResourceTab(icon: Icons.check_circle_outline_rounded, label: 'Corrigé', sub: 'PDF', iconC: OC.good, iconBg: OC.goodBg),
        )),
      if (a.hasVideo)
        Expanded(child: GestureDetector(
          onTap: () => _openVideo(a.videoUrl),
          child: const _ResourceTab(icon: Icons.play_circle_outline_rounded, label: 'Vidéo', sub: 'Corrigé', iconC: Color(0xFF7A5AE0), iconBg: Color(0xFFEEE9FA)),
        )),
    ];
    final tabsRow = <Widget>[];
    for (var i = 0; i < tabs.length; i++) {
      tabsRow.add(tabs[i]);
      if (i < tabs.length - 1) tabsRow.add(const SizedBox(width: 9));
    }

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.subject.isEmpty ? a.title : a.subject, style: display(17, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (_subtitle.isNotEmpty) Text(_subtitle, style: body(12, color: OC.muted, weight: FontWeight.w500)),
        ]),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
        ),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 20),
            color: _fav ? OC.o600 : OC.ink2,
            tooltip: _fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: _toggleFav,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 150,
            decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
            child: Stack(children: [
              Center(child: Icon(a.hasVideo && !a.hasPdf ? Icons.play_circle_outline_rounded : Icons.description_outlined, size: 60, color: OC.faint)),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8)),
                  child: Text(a.category, style: body(11, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              if (a.premium)
                Positioned(top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFFBF0DD), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFA6701A)),
                      const SizedBox(width: 4),
                      Text('PREMIUM', style: body(10, weight: FontWeight.w800, color: const Color(0xFFA6701A))),
                    ]),
                  ),
                ),
              if (primary != null)
                Positioned(right: 12, bottom: 12,
                  child: GestureDetector(
                    onTap: primary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 10)]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(primaryIcon, size: 17, color: OC.ink),
                        const SizedBox(width: 7),
                        Text(primaryLabel, style: body(12.5, weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(a.title, style: body(14.5, weight: FontWeight.w700).copyWith(height: 1.3)),
          const SizedBox(height: 15),

          if (tabsRow.isNotEmpty) ...[
            Row(children: tabsRow),
            const SizedBox(height: 15),
          ],

          GestureDetector(
            onTap: () => context.go('/tutor'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5)),
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
                  Text('Corrige-le pas-à-pas avec le Tuteur IA', style: body(12, color: OC.o700, weight: FontWeight.w500)),
                ])),
                Icon(Icons.chevron_right_rounded, size: 20, color: OC.o600),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ResourceTab extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color iconC, iconBg;
  const _ResourceTab({required this.icon, required this.label, required this.sub, required this.iconC, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(15), border: Border.all(color: OC.line, width: 1.5)),
      child: Column(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: iconC, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: body(12.5, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sub, style: body(10, color: OC.muted, weight: FontWeight.w600)),
      ]),
    );
  }
}
