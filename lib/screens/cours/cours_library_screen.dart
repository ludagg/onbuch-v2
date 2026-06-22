import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/cours_packs_service.dart';

/// Ma bibliothèque (« Mes cours ») — données réelles (packs possédés).
class CoursLibraryScreen extends StatefulWidget {
  const CoursLibraryScreen({super.key});

  @override
  State<CoursLibraryScreen> createState() => _CoursLibraryScreenState();
}

class _CoursLibraryScreenState extends State<CoursLibraryScreen> {
  final _store = CoursPacks.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  void _toCatalogue() => context.canPop() ? context.pop() : context.go('/cours');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: ListenableBuilder(
          listenable: _store,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes cours', style: display(18, weight: FontWeight.w700)),
            Text(_store.classLabel.isEmpty ? 'Programme' : _store.classLabel, style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ]),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _toCatalogue,
              child: Container(
                height: 36, padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(11), border: Border.all(color: OC.line, width: 1.5)),
                child: Row(children: [
                  Icon(Icons.add_rounded, size: 16, color: OC.o600),
                  const SizedBox(width: 4),
                  Text('Packs', style: body(12.5, weight: FontWeight.w700, color: OC.ink)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final packs = _store.library;
          if (packs.isEmpty) return _empty();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _resumeCard(packs.first),
              const SizedBox(height: 22),
              Text('Packs ajoutés', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
              const SizedBox(height: 11),
              for (final p in packs) _packRow(p),
              const SizedBox(height: 6),
              _addMoreRow(),
            ],
          );
        },
      ),
    );
  }

  Widget _resumeCard(Pack p) {
    final pct = _store.progress(p.id);
    final lesson = p.firstLesson ?? 'Première leçon';
    return GestureDetector(
      onTap: () => context.push('/cours/lecon'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.o50, OC.paper]),
          borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.o100, width: 1.5),
        ),
        child: Row(children: [
          SizedBox(width: 48, height: 48, child: OBRing(pct: pct, size: 48, color: OC.o500,
              center: Text('${(pct * 100).round()}%', style: body(11, weight: FontWeight.w800, color: OC.o700)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reprendre : $lesson', maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14.5, weight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(p.name, style: body(12, weight: FontWeight.w600, color: OC.muted)),
          ])),
          const SizedBox(width: 10),
          Container(width: 42, height: 42, decoration: const BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24)),
        ]),
      ),
    );
  }

  Widget _packRow(Pack p) {
    final pct = _store.progress(p.id);
    return GestureDetector(
      onTap: () => context.push('/cours/test'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          Row(children: [
            _avatar(p.code),
            const SizedBox(width: 12),
            Expanded(child: Text(p.level.isEmpty ? p.name : '${p.name} · ${p.level}', style: body(13.5, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (p.premium)
              Text('Premium ✓', style: body(10.5, weight: FontWeight.w700, color: const Color(0xFFA6701A)))
            else
              Text('${p.lessons} leçons', style: body(11, color: OC.muted, weight: FontWeight.w600)),
            const SizedBox(width: 6),
            GestureDetector(onTap: () => context.push('/cours/hors-ligne'), child: Icon(Icons.download_rounded, size: 18, color: OC.muted)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: OC.faint),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: OC.line, valueColor: const AlwaysStoppedAnimation(OC.o500))),
        ]),
      ),
    );
  }

  Widget _addMoreRow() => GestureDetector(
        onTap: _toCatalogue,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.o100, width: 1.5)),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(11)),
                child: Icon(Icons.add_rounded, color: OC.o600, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text('Ajouter d\'autres matières', style: body(13, weight: FontWeight.w700, color: OC.ink))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(8)),
                child: Text('CATALOGUE', style: body(9.5, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.3))),
          ]),
        ),
      );

  Widget _avatar(String code) => Container(
        width: 40, height: 40, decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center, child: Text(code, style: display(13, weight: FontWeight.w800, color: OC.o600)),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_stories_rounded, size: 44, color: OC.o500),
            const SizedBox(height: 14),
            Text('Ta bibliothèque est vide', style: display(18, weight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Ajoute des packs depuis le catalogue.', textAlign: TextAlign.center, style: body(13, color: OC.muted)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _toCatalogue,
              child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13)), alignment: Alignment.center,
                  child: Text('Voir le catalogue', style: body(13.5, weight: FontWeight.w700, color: Colors.white))),
            ),
          ]),
        ),
      );
}
