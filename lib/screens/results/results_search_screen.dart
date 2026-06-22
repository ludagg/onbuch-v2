import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../../models/result_source.dart';

// Repli si l'admin n'a configuré aucune source (l'app reste utilisable).
// Chaque entrée devient une source `manual` adossée à `exam_results`.
const _fallbackSources = <ResultSource>[
  ResultSource(id: '_bac', label: 'Baccalauréat', subtitle: 'Séries A–E · 2026', type: ResultSourceType.manual, examType: 'Baccalauréat', searchLabel: 'Numéro de table', searchHint: 'ex. 10428'),
  ResultSource(id: '_prob', label: 'Probatoire', subtitle: 'Séries A–E · 2026', type: ResultSourceType.manual, examType: 'Probatoire', searchLabel: 'Numéro de table', searchHint: 'ex. 20415'),
  ResultSource(id: '_bepc', label: 'BEPC', subtitle: 'Session 2026', type: ResultSourceType.manual, examType: 'BEPC', searchLabel: 'Numéro de table', searchHint: 'ex. 30912'),
  ResultSource(id: '_gceo', label: 'GCE O Level', subtitle: 'June 2026', type: ResultSourceType.manual, examType: 'GCE O Level', searchLabel: 'Candidate number', searchHint: 'ex. CMR-44012'),
  ResultSource(id: '_gcea', label: 'GCE A Level', subtitle: 'June 2026', type: ResultSourceType.manual, examType: 'GCE A Level', searchLabel: 'Candidate number', searchHint: 'ex. CMR-51008'),
];

class ResultsSearchScreen extends StatefulWidget {
  const ResultsSearchScreen({super.key});

  @override
  State<ResultsSearchScreen> createState() => _ResultsSearchScreenState();
}

class _ResultsSearchScreenState extends State<ResultsSearchScreen> {
  final _db = DatabaseService();
  final _queryCtrl = TextEditingController();

  List<ResultSource> _sources = const [];
  int _idx = 0;
  bool _loadingSources = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    setState(() => _loadingSources = true);
    final list = await _db.getResultSources();
    if (!mounted) return;
    setState(() {
      _sources = list.isEmpty ? _fallbackSources : list;
      _idx = _idx.clamp(0, _sources.length - 1);
      _loadingSources = false;
    });
  }

  ResultSource get _source => _sources[_idx];

  Future<void> _search() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) {
      _toast('Saisis ${_source.isNumberSearch ? 'ton numéro' : 'ton nom'} pour rechercher.', bad: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final lookup = await _db.searchResultSource(source: _source, query: query);
    AnalyticsService.logEvent('result_search', {
      'source': _source.label,
      'type': _source.type.name,
      'found': lookup.found,
    });
    if (!mounted) return;
    setState(() => _searching = false);

    if (lookup.error) {
      _toast(lookup.message, bad: true);
      return;
    }
    if (!lookup.found || lookup.result == null) {
      _toast(
        lookup.message.isNotEmpty
            ? lookup.message
            : (_source.notFoundMessage.isNotEmpty
                ? _source.notFoundMessage
                : 'Aucun résultat trouvé. Vérifie l\'examen et ${_source.isNumberSearch ? 'le numéro' : 'l\'orthographe du nom'}.'),
        bad: true,
      );
      return;
    }
    final r = lookup.result!;
    context.go(r.admitted ? '/results/success' : '/results/fail', extra: r);
  }

  void _toast(String msg, {bool bad = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: bad ? OC.bad : OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Résultats', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            color: OC.ink2,
            onPressed: () => _toast('Choisis l\'examen, saisis ${_source.isNumberSearch ? 'le numéro de ta convocation' : 'ton nom'}, puis « Voir mon résultat ».'),
          ),
        ],
      ),
      body: _loadingSources
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.6, color: OC.o500))
          : _sources.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'Aucun examen disponible',
                  message: 'Les résultats seront configurés très bientôt.',
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _source;
    return RefreshIndicator(
      color: OC.o500,
      onRefresh: () => _loadSources(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'EXAMEN OU CONCOURS',
            style: body(11, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 0.1 * 11),
          ),
          const SizedBox(height: 7),
          GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OC.line2, width: 1.5),
                boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.03), blurRadius: 2)],
              ),
              child: Row(children: [
                _SourceBadge(icon: s.icon),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.label, style: display(16, weight: FontWeight.w600)),
                  if (s.displaySubtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(s.displaySubtitle, style: body(12, weight: FontWeight.w600, color: OC.muted)),
                  ],
                ])),
                if (_sources.length > 1)
                  Row(children: [
                    Text('Changer', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: OC.o600, size: 17),
                  ]),
              ]),
            ),
          ),
          const SizedBox(height: 13),

          // Carte de recherche
          OBCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.searchLabel, style: body(12, weight: FontWeight.w700, color: OC.ink2)),
              const SizedBox(height: 6),
              _QueryField(
                key: ValueKey(s.id),
                controller: _queryCtrl,
                hint: s.searchHint,
                isNumber: s.isNumberSearch,
                onSubmit: (_) => _search(),
              ),
              const SizedBox(height: 6),
              Text(
                s.isNumberSearch
                    ? 'Le numéro figure sur ta convocation d\'examen.'
                    : 'Saisis ton nom tel qu\'il figure sur la liste officielle.',
                style: body(11.5, color: OC.muted, weight: FontWeight.w500),
              ),
              const SizedBox(height: 13),
              GestureDetector(
                onTap: _searching ? null : _search,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _searching
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Voir mon résultat', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                          ]),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 13),

          // Suivi des publications (à venir)
          Text('Résultats suivis', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 8),
          OBCard(
            child: Row(children: [
              _SourceBadge(icon: s.icon, soft: true),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.label, style: body(14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: OC.warn, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Tu seras alerté·e dès la publication', style: body(12, color: OC.ink2, weight: FontWeight.w500)),
                ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.o100, width: 1.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_outlined, size: 14, color: OC.o600),
                  const SizedBox(width: 5),
                  Text('Alerte', style: body(11.5, weight: FontWeight.w700, color: OC.o700)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 14),
              Text('Choisis ton examen', style: display(19, weight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sources.length,
                  itemBuilder: (_, i) {
                    final e = _sources[i];
                    final sel = i == _idx;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _idx = i;
                          _queryCtrl.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: OC.paper,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: sel ? OC.o500 : OC.line, width: sel ? 2 : 1.5),
                          boxShadow: sel ? [BoxShadow(color: OC.o50, blurRadius: 0, spreadRadius: 3)] : null,
                        ),
                        child: Row(children: [
                          _SourceBadge(icon: e.icon, selected: sel),
                          const SizedBox(width: 13),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.label, style: body(14.5, weight: FontWeight.w700)),
                            if (e.displaySubtitle.isNotEmpty)
                              Text(e.displaySubtitle, style: body(12, color: OC.muted, weight: FontWeight.w500)),
                          ])),
                          if (sel)
                            Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                            )
                          else
                            Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: OC.line2, width: 2))),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// Pastille (emoji configurable) façon OnBuch.
class _SourceBadge extends StatelessWidget {
  final String icon;
  final bool selected;
  final bool soft;
  const _SourceBadge({required this.icon, this.selected = false, this.soft = false});

  @override
  Widget build(BuildContext context) {
    final useGrad = selected || (!soft);
    return Container(
      width: soft ? 42 : 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: useGrad && !soft ? OC.grad : null,
        color: soft ? OC.o50 : (selected ? null : OC.panel),
        borderRadius: BorderRadius.circular(13),
        border: soft ? Border.all(color: OC.o100, width: 1.5) : null,
        boxShadow: useGrad && !soft
            ? [BoxShadow(color: OC.o500.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))]
            : null,
      ),
      child: Center(
        child: Text(
          icon.isEmpty ? '🎓' : icon,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// Champ de saisie (numéro ou nom), style OnBuch.
class _QueryField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isNumber;
  final ValueChanged<String> onSubmit;
  const _QueryField({super.key, required this.controller, required this.hint, required this.isNumber, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.o500, width: 2),
        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Icon(isNumber ? Icons.tag_rounded : Icons.person_outline_rounded, size: 18, color: OC.o500),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: false,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: onSubmit,
            inputFormatters: [LengthLimitingTextInputFormatter(isNumber ? 24 : 80)],
            style: body(14.5, weight: FontWeight.w600, color: OC.ink),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: body(14.5, color: OC.muted),
            ),
          ),
        ),
      ]),
    );
  }
}
