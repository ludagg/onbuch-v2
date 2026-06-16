import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course.dart';

/// Bibliothèque des cours & fiches : une carte par matière disposant de
/// contenu, avec le décompte « N cours · M fiches » filtré selon la classe /
/// série de l'élève.
class CoursLibraryScreen extends StatefulWidget {
  const CoursLibraryScreen({super.key});

  @override
  State<CoursLibraryScreen> createState() => _CoursLibraryScreenState();
}

class _CoursLibraryScreenState extends State<CoursLibraryScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();

  List<Course>? _all; // null = chargement
  String _scope = ''; // libellé classe/série de l'élève

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _auth.getCurrentUser();
    final profile = user == null ? null : await _db.getUserProfile(user.$id);
    final classe = (profile?['classe'] ?? '').toString().trim();
    final serie = (profile?['serie'] ?? '').toString().trim();
    final list = await _db.getAllCourses(classe: classe, serie: serie);
    if (!mounted) return;
    setState(() {
      _all = list;
      _scope = [classe, if (serie.isNotEmpty) 'Série $serie']
          .where((s) => s.isNotEmpty)
          .join(' · ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Cours', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        actions: obTopActions(context),
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : RefreshIndicator(
              color: OC.o500,
              onRefresh: _load,
              child: _body(context, all),
            ),
    );
  }

  Widget _body(BuildContext context, List<Course> all) {
    // Matières ayant du contenu, dans l'ordre de l'enum.
    final subjects = CourseSubject.values
        .where((s) => all.any((c) => c.subject == s))
        .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Bandeau contexte (classe/série de l'élève)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            gradient: OC.gradSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OC.o100, width: 1.5),
          ),
          child: Row(children: [
            const Icon(Icons.play_lesson_rounded, size: 20, color: OC.o600),
            const SizedBox(width: 11),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tes cours & fiches', style: body(13.5, weight: FontWeight.w800, color: OC.ink)),
                const SizedBox(height: 2),
                Text(_scope.isEmpty ? 'Adaptés à ton programme' : 'Adaptés à $_scope',
                    style: body(11.5, weight: FontWeight.w600, color: OC.o700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),

        if (subjects.isEmpty)
          const _EmptyLibrary()
        else ...[
          Text('Par matière', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 11),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: subjects.map((s) {
              final list = all.where((c) => c.subject == s).toList();
              final cours = list.where((c) => !c.isFiche).length;
              final fiches = list.where((c) => c.isFiche).length;
              return _SubjectCard(
                subject: s,
                cours: cours,
                fiches: fiches,
                onTap: () => context.go('/cours/subject/${s.key}', extra: list),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final CourseSubject subject;
  final int cours, fiches;
  final VoidCallback onTap;
  const _SubjectCard({
    required this.subject,
    required this.cours,
    required this.fiches,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (cours > 0) '$cours cours',
      if (fiches > 0) '$fiches fiche${fiches > 1 ? 's' : ''}',
    ];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 12, 11),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          SubjTile(subject.tileKey, size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(subject.label,
                    style: body(13, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(parts.isEmpty ? 'Bientôt' : parts.join(' · '),
                    style: body(10.5, color: OC.muted, weight: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              color: OC.o50,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: OC.o100, width: 1.5),
            ),
            child: const Icon(Icons.play_lesson_rounded, size: 40, color: OC.o600),
          ),
          const SizedBox(height: 18),
          Text('Cours & fiches', style: display(20, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tes cours et fiches de révision arrivent bientôt. Reviens vite !',
              textAlign: TextAlign.center,
              style: body(14, color: OC.ink2).copyWith(height: 1.5),
            ),
          ),
        ]),
      ),
    );
  }
}
