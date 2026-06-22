import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/exam_taxonomy.dart';

/// Sélecteur **en cascade** de la filière, piloté par la taxonomie statique
/// ([examTaxonomy]). À partir de l'examen choisi ([exam]), il déroule
/// dynamiquement les niveaux : subdivision(s) éventuelle(s) puis série /
/// spécialité. Ex. : Baccalauréat → « Enseignement général » → « Série D ».
/// Certains examens n'ont qu'un niveau (BTS → spécialité) et d'autres aucun
/// (BEPC, composé par matières). La valeur retenue ([value]) est le **libellé
/// de la feuille** choisie (série/spécialité) ; `null` tant qu'on n'a pas atteint
/// une feuille.
class ExamPathPicker extends StatefulWidget {
  final String exam;
  final String? value;
  final ValueChanged<String?> onChanged;

  const ExamPathPicker({
    super.key,
    required this.exam,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ExamPathPicker> createState() => _ExamPathPickerState();
}

class _ExamPathPickerState extends State<ExamPathPicker> {
  final List<ExamNode> _groups = []; // subdivisions choisies (chemin de drill)
  ExamNode? _leaf; // série / spécialité finale choisie

  ExamNode? get _root => examTaxonomy[widget.exam];

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ExamPathPicker old) {
    super.didUpdateWidget(old);
    // Reset si l'examen change, ou si la valeur externe ne correspond plus.
    if (old.exam != widget.exam || (old.value != widget.value && widget.value != _leaf?.label)) {
      _groups.clear();
      _leaf = null;
      _resolve();
    }
  }

  /// Reconstruit le chemin (groupes + feuille) depuis la valeur stockée — utile
  /// à l'édition du profil pour ré-afficher la sélection précédente.
  void _resolve() {
    final root = _root;
    final target = widget.value;
    if (root == null || target == null || target.isEmpty) return;
    List<ExamNode>? dfs(ExamNode node, List<ExamNode> trail) {
      for (final c in node.children) {
        if (c.isLeaf) {
          if (c.label == target) return [...trail, c];
        } else {
          final r = dfs(c, [...trail, c]);
          if (r != null) return r;
        }
      }
      return null;
    }

    final path = dfs(root, const []);
    if (path != null && path.isNotEmpty) {
      _leaf = path.removeLast();
      _groups
        ..clear()
        ..addAll(path);
    }
  }

  void _selectAt(int depth, ExamNode child) {
    setState(() {
      if (_groups.length > depth) _groups.removeRange(depth, _groups.length);
      _leaf = null;
      if (child.isLeaf) {
        _leaf = child;
      } else {
        _groups.add(child);
      }
    });
    widget.onChanged(_leaf?.label);
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    if (root == null || root.children.isEmpty) {
      // Examen sans subdivision ni série (ex. BEPC : composé par matières).
      return Row(children: [
        Icon(Icons.info_outline_rounded, size: 17, color: OC.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Le ${widget.exam} se compose par matières — pas de série à choisir.',
              style: body(12.5, color: OC.muted, weight: FontWeight.w600)),
        ),
      ]);
    }

    final levels = <Widget>[];
    ExamNode current = root;
    int depth = 0;
    while (current.children.isNotEmpty) {
      final children = current.children;
      final resolved = depth < _groups.length;
      final chosen = resolved ? _groups[depth] : (children.contains(_leaf) ? _leaf : null);
      levels.add(_levelBlock(children, depth, chosen));
      if (resolved) {
        current = _groups[depth];
        depth++;
      } else {
        break; // niveau courant non résolu = dernier affiché
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: levels);
  }

  Widget _levelBlock(List<ExamNode> children, int depth, ExamNode? chosen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_levelLabel(children), style: body(13, weight: FontWeight.w700, color: OC.ink2)),
        const SizedBox(height: 10),
        Wrap(spacing: 9, runSpacing: 9, children: [
          for (final c in children)
            _chip(c.label, chosen == c, () => _selectAt(depth, c)),
        ]),
      ]),
    );
  }

  String _levelLabel(List<ExamNode> children) {
    final leaves = children.every((c) => c.isLeaf);
    if (!leaves) return 'Type / catégorie';
    final hasCode = children.any((c) => c.code.isNotEmpty);
    if (hasCode) return 'Série';
    if (widget.exam == 'Concours') return 'École / concours';
    return 'Filière / spécialité';
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
