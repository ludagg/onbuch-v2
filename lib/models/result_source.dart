/// Source de résultats configurée par l'admin (collection `result_sources`).
///
/// L'admin décrit, pour chaque examen/session, **comment** les résultats sont
/// publiés. Trois types :
///  - `manual` : résultats saisis ligne par ligne (collection `exam_results`).
///  - `pdf`    : un PDF chargé par l'admin, dans lequel on cherche le nom/numéro.
///  - `api`    : une API externe interrogée à la volée.
///
/// Tout l'affichage du module Résultats (libellés, exemples, message
/// « introuvable »…) est piloté par ces documents — l'app n'a plus rien en dur.
import 'exam_result.dart';

enum ResultSourceType { manual, pdf, api }

/// Issue d'une recherche dans une source de résultats.
///
/// - `found == true` → [result] est renseigné.
/// - `found == false` → introuvable (avec un [message] éventuel).
/// - `error == true`  → souci technique (réseau, source mal configurée).
class ResultLookup {
  final bool found;
  final bool error;
  final ExamResult? result;
  final String message;

  const ResultLookup({
    required this.found,
    this.error = false,
    this.result,
    this.message = '',
  });

  const ResultLookup.notFound() : this(found: false);
  const ResultLookup.error(String msg) : this(found: false, error: true, message: msg);
  ResultLookup.found(ExamResult r) : this(found: true, result: r);
}

class ResultSource {
  final String id;
  final String label; // ex. « Baccalauréat 2026 »
  final String subtitle; // ex. « Séries A–E · Session 2026 »
  final String icon; // emoji affiché (défaut 🎓)
  final ResultSourceType type;

  /// Clé backend pour le type `manual` (= `exam_results.examType`).
  final String examType;
  final String year;

  /// Libellé + exemple du champ de recherche (numéro de table, matricule…).
  final String searchLabel;
  final String searchHint;

  /// `number` ou `name` — ce que le candidat saisit (informe le clavier / la casse).
  final String searchMode;

  /// Message affiché quand rien n'est trouvé (vide = message par défaut).
  final String notFoundMessage;

  // Type `pdf` ──────────────────────────────────────────────────────────────
  final String pdfUrl; // URL de visualisation du PDF chargé
  final String pdfName; // nom de fichier d'origine (affichage admin)

  // Type `api` ──────────────────────────────────────────────────────────────
  final String apiUrl; // gabarit, ex. https://…/results?num={query}

  final int order;
  final bool active;

  const ResultSource({
    required this.id,
    required this.label,
    required this.type,
    this.subtitle = '',
    this.icon = '🎓',
    this.examType = '',
    this.year = '',
    this.searchLabel = 'Numéro de table',
    this.searchHint = 'ex. 10428',
    this.searchMode = 'number',
    this.notFoundMessage = '',
    this.pdfUrl = '',
    this.pdfName = '',
    this.apiUrl = '',
    this.order = 0,
    this.active = true,
  });

  bool get isNumberSearch => searchMode != 'name';

  /// Sous-titre prêt à afficher, avec repli sur l'année si vide.
  String get displaySubtitle {
    if (subtitle.trim().isNotEmpty) return subtitle.trim();
    return year.trim().isEmpty ? '' : 'Session $year';
  }

  static ResultSourceType _parseType(dynamic v) {
    switch (v?.toString().trim().toLowerCase()) {
      case 'pdf':
        return ResultSourceType.pdf;
      case 'api':
        return ResultSourceType.api;
      default:
        return ResultSourceType.manual;
    }
  }

  factory ResultSource.fromMap(Map<String, dynamic> data, {required String id}) {
    String s(String k, [String def = '']) {
      final v = data[k];
      if (v == null) return def;
      final t = v.toString().trim();
      return t.isEmpty ? def : t;
    }

    final ord = data['order'];
    return ResultSource(
      id: id,
      label: s('label', 'Examen'),
      subtitle: s('subtitle'),
      icon: s('icon', '🎓'),
      type: _parseType(data['sourceType']),
      examType: s('examType'),
      year: s('year'),
      searchLabel: s('searchLabel', 'Numéro de table'),
      searchHint: s('searchHint', 'ex. 10428'),
      searchMode: s('searchMode', 'number'),
      notFoundMessage: s('notFoundMessage'),
      pdfUrl: s('pdfUrl'),
      pdfName: s('pdfName'),
      apiUrl: s('apiUrl'),
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
      active: data['active'] == true ||
          data['active'].toString().toLowerCase() == 'true' ||
          data['active'].toString() == '1',
    );
  }
}
