import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/concours_application.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Suivi des candidatures de l'utilisateur (section C · écran 14).
class MesCandidaturesScreen extends StatefulWidget {
  const MesCandidaturesScreen({super.key});

  @override
  State<MesCandidaturesScreen> createState() => _MesCandidaturesScreenState();
}

class _MesCandidaturesScreenState extends State<MesCandidaturesScreen> {
  late Future<List<ConcoursApplication>> _future = _load();

  Future<List<ConcoursApplication>> _load() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return const [];
    return DatabaseService().getMyApplications(user.$id);
  }

  static const _steps = ['Soumis', 'Validé', 'Écrits', 'Résultat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Mes candidatures'),
      body: RefreshIndicator(
        color: OC.o500,
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<ConcoursApplication>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: OC.o500));
            }
            final apps = snap.data ?? const <ConcoursApplication>[];
            if (apps.isEmpty) return _empty(context);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _card(apps[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return ListView(children: [
      const SizedBox(height: 110),
      Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: OC.o50, shape: BoxShape.circle),
          child: const Icon(Icons.track_changes_rounded, size: 34, color: OC.o500),
        ),
        const SizedBox(height: 16),
        Text('Aucune candidature', style: display(18, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Text('Inscris-toi à un concours pour suivre ton dossier ici.',
              textAlign: TextAlign.center, style: body(13.5, color: OC.muted, weight: FontWeight.w500)),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => context.go('/concours'),
          child: Container(
            height: 46, padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Explorer les concours', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    ]);
  }

  Widget _card(ConcoursApplication a) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/resultat-admission', extra: a),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.concoursName, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(_subtitle(a), style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: a.stepIndex >= 2 ? OC.o50 : OC.panel,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(a.statusLabel,
                style: body(11, weight: FontWeight.w800, color: a.stepIndex >= 2 ? OC.o700 : OC.ink2)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: List.generate(_steps.length, (j) {
          final done = j <= a.stepIndex;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: j < _steps.length - 1 ? 4 : 0),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: done ? OC.o500 : OC.line2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ));
        })),
        const SizedBox(height: 7),
        Row(children: List.generate(_steps.length, (j) {
          return Expanded(child: Text(_steps[j],
              textAlign: j == 0 ? TextAlign.left : (j == _steps.length - 1 ? TextAlign.right : TextAlign.center),
              style: body(9.5, weight: FontWeight.w700,
                  color: j <= a.stepIndex ? OC.o700 : OC.muted)));
        })),
      ]),
      ),
    );
  }

  String _subtitle(ConcoursApplication a) {
    final parts = <String>[];
    if (a.receiptNo != null) parts.add('N° ${a.receiptNo}');
    parts.add('Déposée le ${DateFormat('d MMM', 'fr_FR').format(a.createdAt)}');
    return parts.join(' · ');
  }
}
