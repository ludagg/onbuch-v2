import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exam_series.dart';
import '../services/database_service.dart';

/// Sélecteur de **série / filière** piloté par le backend (`exam_series`).
/// Les options dépendent du [exam] choisi (Bac → A/C/D/F2…, BTS → filières…).
/// Si aucune série n'est configurée pour ce cursus (ou hors-ligne), bascule
/// automatiquement sur une **saisie libre** pour ne jamais bloquer l'élève.
class SeriesPicker extends StatefulWidget {
  final String exam;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  const SeriesPicker({
    super.key,
    required this.exam,
    required this.value,
    required this.onChanged,
    this.label = 'Série / filière',
  });

  @override
  State<SeriesPicker> createState() => _SeriesPickerState();
}

class _SeriesPickerState extends State<SeriesPicker> {
  List<ExamSeries>? _all;
  bool _failed = false;
  late final TextEditingController _free = TextEditingController(text: widget.value ?? '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _free.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await DatabaseService().getExamSeries();
      if (mounted) setState(() => _all = s);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = Text(widget.label, style: body(13, weight: FontWeight.w700, color: OC.ink2));

    // En cours de chargement.
    if (_all == null && !_failed) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        header,
        const SizedBox(height: 10),
        Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: OC.o500)),
          const SizedBox(width: 10),
          Text('Chargement des séries…', style: body(13, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ]);
    }

    final list = (_all ?? []).where((s) => s.exam == widget.exam).toList()
      ..sort((a, b) {
        final c = (a.category ?? '').compareTo(b.category ?? '');
        return c != 0 ? c : a.sortOrder.compareTo(b.sortOrder);
      });

    // Aucune série configurée pour ce cursus → saisie libre.
    if (list.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        header,
        const SizedBox(height: 8),
        TextField(
          controller: _free,
          textCapitalization: TextCapitalization.characters,
          style: body(15, color: OC.ink),
          onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
          decoration: InputDecoration(
            hintText: 'Ex. D — Sciences & Mathématiques',
            hintStyle: body(14, color: OC.muted),
            prefixIcon: Icon(Icons.workspace_premium_outlined, color: OC.muted, size: 20),
            filled: true,
            fillColor: OC.paper,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.line2, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: OC.line2, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OC.o500, width: 2)),
          ),
        ),
      ]);
    }

    // Regroupement par catégorie (en conservant l'ordre trié).
    final groups = <String, List<ExamSeries>>{};
    for (final s in list) {
      groups.putIfAbsent(s.category ?? '', () => []).add(s);
    }
    final known = list.map((s) => s.name).toSet();
    final hasCustom = widget.value != null && widget.value!.isNotEmpty && !known.contains(widget.value);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      header,
      const SizedBox(height: 10),
      for (final entry in groups.entries) ...[
        if (entry.key.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 9),
            child: Text(entry.key, style: body(12, weight: FontWeight.w800, color: OC.muted)),
          ),
        Wrap(spacing: 9, runSpacing: 9, children: [
          for (final s in entry.value)
            _chip(s.name, widget.value == s.name, () => widget.onChanged(widget.value == s.name ? null : s.name)),
        ]),
        const SizedBox(height: 13),
      ],
      // Valeur historique non listée : on l'affiche pour ne pas la perdre.
      if (hasCustom)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Wrap(spacing: 9, runSpacing: 9, children: [
            _chip(widget.value!, true, () => widget.onChanged(null)),
          ]),
        ),
    ]);
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: on ? OC.o50 : OC.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
          ),
          child: Text(label, style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
        ),
      );
}
