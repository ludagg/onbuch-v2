/// Candidature de l'utilisateur à un concours (collection privée
/// `concours_applications`).
class ConcoursApplication {
  final String id;
  final String concoursId;
  final String concoursName;
  final String status; // submitted · validated · exam · result
  final String? examLabel;
  final String? receiptNo;
  final DateTime createdAt;

  const ConcoursApplication({
    required this.id,
    required this.concoursId,
    required this.concoursName,
    required this.status,
    required this.createdAt,
    this.examLabel,
    this.receiptNo,
  });

  /// Index d'avancement pour la barre d'étapes (Soumis · Validé · Écrits · Résultat).
  int get stepIndex {
    switch (status) {
      case 'result':
        return 3;
      case 'exam':
        return 2;
      case 'validated':
        return 1;
      default:
        return 0;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'result':
        return 'Résultat';
      case 'exam':
        return 'Convoqué';
      case 'validated':
        return 'Validé';
      default:
        return 'Soumis';
    }
  }

  factory ConcoursApplication.fromMap(Map<String, dynamic> d,
      {required String id, required String createdAtFallback}) {
    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final created = (d['createdAt'] ?? createdAtFallback).toString();
    return ConcoursApplication(
      id: id,
      concoursId: (d['concoursId'] ?? '').toString(),
      concoursName: (d['concoursName'] ?? 'Concours').toString(),
      status: (d['status'] ?? 'submitted').toString().trim().toLowerCase(),
      examLabel: s(d['examLabel']),
      receiptNo: s(d['receiptNo']),
      createdAt: DateTime.tryParse(created) ?? DateTime.now(),
    );
  }
}
