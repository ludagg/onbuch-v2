import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';

/// Type de collection d'annales (accès rapides de la bibliothèque).
enum AnnaleCollection { offline, recent, favorites }

/// Page générique « Hors-ligne / Récents / Favoris » des annales.
/// Contenu d'exemple pour l'instant (le module Annales n'a pas encore de
/// backend) — à brancher sur les vraies données quand la collection existera.
class AnnalesCollectionScreen extends StatelessWidget {
  final AnnaleCollection kind;
  const AnnalesCollectionScreen({super.key, required this.kind});

  // Données d'exemple (matière, examen, année).
  static const _sample = [
    ('Mathématiques', 'Bac D', '2024'),
    ('Physique-Chimie', 'Bac D', '2024'),
    ('SVT', 'Bac D', '2023'),
    ('Philosophie', 'Bac A', '2023'),
    ('Histoire-Géo', 'Probatoire A', '2024'),
    ('Anglais', 'BEPC', '2022'),
  ];

  String get _title => switch (kind) {
        AnnaleCollection.offline => 'Hors-ligne',
        AnnaleCollection.recent => 'Récents',
        AnnaleCollection.favorites => 'Favoris',
      };

  ({IconData icon, Color color, String empty, String emptyMsg}) get _cfg => switch (kind) {
        AnnaleCollection.offline => (
            icon: Icons.download_done_rounded,
            color: OC.waInk,
            empty: 'Rien hors-ligne',
            emptyMsg: 'Télécharge une annale pour la consulter sans connexion.',
          ),
        AnnaleCollection.recent => (
            icon: Icons.access_time_rounded,
            color: OC.blue,
            empty: 'Aucun récent',
            emptyMsg: 'Les annales que tu ouvres apparaîtront ici.',
          ),
        AnnaleCollection.favorites => (
            icon: Icons.bookmark_rounded,
            color: const Color(0xFFA6701A),
            empty: 'Aucun favori',
            emptyMsg: 'Mets une annale en favori pour la retrouver vite.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    // En attendant le backend : on affiche les exemples. (Mettre [] pour voir
    // l'état vide réel.)
    final items = _sample;

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, _title),
      body: items.isEmpty
          ? EmptyState(icon: cfg.icon, title: cfg.empty, message: cfg.emptyMsg,
              actionLabel: 'Parcourir les annales', onAction: () => context.go('/annales'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final (subject, exam, year) = items[i];
                return _AnnaleTile(
                  subject: subject, exam: exam, year: year,
                  trailingIcon: cfg.icon, trailingColor: cfg.color,
                  onTap: () => context.push('/annales/detail'),
                );
              },
            ),
    );
  }
}

class _AnnaleTile extends StatelessWidget {
  final String subject, exam, year;
  final IconData trailingIcon;
  final Color trailingColor;
  final VoidCallback onTap;
  const _AnnaleTile({
    required this.subject, required this.exam, required this.year,
    required this.trailingIcon, required this.trailingColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.picture_as_pdf_rounded, size: 21, color: OC.o600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$subject — $exam', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(14, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Épreuve + corrigé · $year', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Container(
            width: 30, height: 30, alignment: Alignment.center,
            decoration: BoxDecoration(color: trailingColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(trailingIcon, size: 16, color: trailingColor),
          ),
        ]),
      ),
    );
  }
}
