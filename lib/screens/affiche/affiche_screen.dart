import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../models/affiche.dart';
import '../../services/database_service.dart';

/// Page listant tous les éléments « À l'affiche » (événements & partenaires).
class AfficheScreen extends StatefulWidget {
  const AfficheScreen({super.key});

  @override
  State<AfficheScreen> createState() => _AfficheScreenState();
}

class _AfficheScreenState extends State<AfficheScreen> {
  late final Future<List<AfficheItem>> _future = DatabaseService().getAffiche(limit: 50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'À l\'affiche'),
      body: FutureBuilder<List<AfficheItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: List.generate(4, (_) => const SkeletonCard()),
            );
          }
          final items = snap.data ?? const <AfficheItem>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.campaign_outlined, size: 46, color: OC.faint),
                  const SizedBox(height: 12),
                  Text('Rien à l\'affiche pour le moment', style: display(18, weight: FontWeight.w700)),
                ]),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: items.length,
            itemBuilder: (_, i) => _card(context, items[i]),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, AfficheItem a) {
    final hasImg = a.imageUrl != null && a.imageUrl!.isNotEmpty;
    final sub = a.subtitle ??
        (a.date != null ? DateFormat('d MMM y', 'fr_FR').format(a.date!) : (a.location ?? ''));
    return GestureDetector(
      onTap: () => context.push('/affiche-detail', extra: a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: OC.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OC.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Stack(fit: StackFit.expand, children: [
              if (hasImg)
                Image.network(a.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: OC.panel),
                    loadingBuilder: (_, c, p) => p == null ? c : Container(color: OC.panel))
              else
                Container(color: OC.panel, child: Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 40))),
              Positioned(top: 12, left: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: a.badgeColor, borderRadius: BorderRadius.circular(999)),
                child: Text(a.badge, style: body(9.5, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.06 * 9.5)),
              )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(16.5, weight: FontWeight.w700).copyWith(height: 1.15)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sub, style: body(12.5, color: OC.muted, weight: FontWeight.w500)),
              ],
              if (a.partnerName != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.handshake_outlined, size: 14, color: OC.o600),
                  const SizedBox(width: 5),
                  Text(a.partnerName!, style: body(12, weight: FontWeight.w700, color: OC.o700)),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
