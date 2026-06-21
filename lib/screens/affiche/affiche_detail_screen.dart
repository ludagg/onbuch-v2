import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../models/affiche.dart';
import '../../utils/launch.dart';

class AfficheDetailScreen extends StatelessWidget {
  final AfficheItem? item;
  const AfficheDetailScreen({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    final a = item;
    if (a == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'À l\'affiche'),
        body: const Center(child: Text('Élément introuvable.')),
      );
    }
    final hasImg = a.imageUrl != null && a.imageUrl!.isNotEmpty;
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, a.isSponsored ? 'Partenaire' : 'Événement'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Couverture
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasImg
                  ? Image.network(a.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _cover(),
                      loadingBuilder: (_, c, p) => p == null ? c : Container(color: OC.panel))
                  : _cover(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: a.badgeColor, borderRadius: BorderRadius.circular(999)),
            child: Text(a.badge, style: body(10, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.06 * 10)),
          ),
          const SizedBox(height: 12),
          Text(a.title, style: display(24, weight: FontWeight.w700).copyWith(height: 1.15)),
          const SizedBox(height: 10),

          if (a.date != null)
            _meta(Icons.event_rounded, DateFormat('EEEE d MMMM y', 'fr_FR').format(a.date!)),
          if (a.location != null) _meta(Icons.location_on_outlined, a.location!),
          if (a.subtitle != null && a.date == null && a.location == null) _meta(Icons.info_outline_rounded, a.subtitle!),

          if (a.description != null) ...[
            const SizedBox(height: 14),
            Text(a.description!, style: body(14.5, color: OC.ink2).copyWith(height: 1.55)),
          ],

          // Partenaire
          if (a.partnerName != null) ...[
            const SizedBox(height: 22),
            Text('Partenaire', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _partnerLogo(a),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.partnerName!, style: body(14.5, weight: FontWeight.w700)),
                  if (a.partnerDescription != null) ...[
                    const SizedBox(height: 3),
                    Text(a.partnerDescription!, style: body(12.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.4)),
                  ],
                ])),
              ]),
            ),
          ],

          // CTA
          if (a.link != null) ...[
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => openUrl(context, a.link),
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  gradient: OC.grad, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(a.isSponsored ? Icons.open_in_new_rounded : Icons.how_to_reg_rounded, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(a.isSponsored ? 'Découvrir l\'offre' : 'S\'inscrire / en savoir plus',
                      style: body(14, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _partnerLogo(AfficheItem a) {
    final has = a.partnerLogo != null && a.partnerLogo!.isNotEmpty;
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(13)),
      clipBehavior: Clip.antiAlias,
      child: has
          ? Image.network(a.partnerLogo!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.handshake_outlined, color: OC.o600, size: 24))
          : Icon(Icons.handshake_outlined, color: OC.o600, size: 24),
    );
  }

  Widget _meta(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: OC.muted),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: body(13, weight: FontWeight.w600, color: OC.ink2))),
        ]),
      );

  Widget _cover() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
        ),
        child: Center(child: Icon(Icons.image_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48)),
      );
}
