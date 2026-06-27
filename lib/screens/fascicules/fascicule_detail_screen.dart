import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../widgets/cached_image.dart';
import '../../models/fascicule.dart';
import '../../models/social_link.dart';
import '../../services/database_service.dart';
import '../../utils/launch.dart';

/// Fiche d'un fascicule (page de vente) : couverture, description, avantages,
/// prix, et **précommande via WhatsApp**. Remplace l'ouverture directe du PDF
/// (les fascicules ne sont plus lisibles en clair dans l'app).
class FasciculeDetailScreen extends StatefulWidget {
  final Fascicule? fascicule;
  const FasciculeDetailScreen({super.key, this.fascicule});

  @override
  State<FasciculeDetailScreen> createState() => _FasciculeDetailScreenState();
}

class _FasciculeDetailScreenState extends State<FasciculeDetailScreen> {
  final _db = DatabaseService();
  String? _orderNumber; // numéro dédié précommandes (order_settings)
  List<SocialLink> _links = const [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final num = await _db.getOrderWhatsApp();
      final links = await _db.getSocialLinks();
      if (mounted) setState(() { _orderNumber = num; _links = links; });
    } catch (_) {}
  }

  /// Lien WhatsApp de précommande. Priorité au **numéro dédié** (réglages
  /// commandes) ; repli sur le WhatsApp des réseaux sociaux, puis sur le
  /// sélecteur de contact.
  String _orderUrl(Fascicule f) {
    final msg = 'Bonjour 👋 Je souhaite précommander le fascicule « ${f.title} »'
        '${f.shelfSubtitle.isNotEmpty ? ' (${f.shelfSubtitle})' : ''}'
        '${f.priceLabel != null ? ' — ${f.priceLabel}' : ''}. Est-il disponible ?';
    final enc = Uri.encodeComponent(msg);

    String? raw = _orderNumber?.trim();
    if (raw == null || raw.isEmpty) {
      final wa = _links.where((l) => l.platform == 'whatsapp' && l.url.trim().isNotEmpty).toList();
      if (wa.isNotEmpty) raw = wa.first.url.trim();
    }
    if (raw == null || raw.isEmpty) return 'https://wa.me/?text=$enc';

    final m = RegExp(r'wa\.me/(\+?\d{6,})').firstMatch(raw);
    if (m != null) return 'https://wa.me/${m.group(1)!.replaceAll('+', '')}?text=$enc';
    if (RegExp(r'^\+?\d{6,}$').hasMatch(raw)) {
      return 'https://wa.me/${raw.replaceAll(RegExp(r'[^0-9]'), '')}?text=$enc';
    }
    return raw; // lien de groupe / autre → ouvert tel quel
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fascicule;
    if (f == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: obBackAppBar(context, 'Fascicule'),
        body: const EmptyState(
          icon: Icons.menu_book_rounded,
          title: 'Fascicule introuvable',
          message: 'Reviens à la bibliothèque et réessaie.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Fascicule'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // En-tête : couverture + titre + méta
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _cover(f),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.title, style: display(19, weight: FontWeight.w800).copyWith(height: 1.15)),
              const SizedBox(height: 6),
              if (f.shelfSubtitle.isNotEmpty)
                Text(f.shelfSubtitle, style: body(13, color: OC.o600, weight: FontWeight.w700)),
              if (f.author.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('par ${f.author}', style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 7, runSpacing: 7, children: [
                if (f.pages > 0) _chip(Icons.menu_book_rounded, '${f.pages} pages'),
                if (f.subject.isNotEmpty) _chip(Icons.school_rounded, f.subject),
              ]),
            ])),
          ]),
          const SizedBox(height: 20),

          // Prix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: OC.gradSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OC.o100, width: 1.5),
            ),
            child: Row(children: [
              Icon(Icons.local_offer_rounded, size: 20, color: OC.o600),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.priceLabel ?? 'Prix sur demande',
                    style: display(20, weight: FontWeight.w800, color: OC.o700)),
                Text('Disponible en précommande', style: body(11.5, color: OC.ink2, weight: FontWeight.w600)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Description
          if (f.description.trim().isNotEmpty) ...[
            Text('Présentation', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(height: 8),
            Text(f.description, style: body(13.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.5)),
            const SizedBox(height: 20),
          ],

          // Avantages
          Text('Ce que contient ce fascicule', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          for (final b in f.benefitList)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  width: 22, height: 22, alignment: Alignment.center,
                  decoration: BoxDecoration(color: OC.goodBg, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 14, color: OC.good),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(b,
                    style: body(13.5, color: OC.ink, weight: FontWeight.w600).copyWith(height: 1.4))),
              ]),
            ),
          const SizedBox(height: 12),

          // Note aperçu / précommande
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OC.panel, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: OC.muted),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Aperçu réservé. Le fascicule complet est remis après précommande, '
                'directement via WhatsApp.',
                style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.4),
              )),
            ]),
          ),
        ],
      ),
      bottomSheet: _orderBar(f),
    );
  }

  Widget _cover(Fascicule f) {
    return Container(
      width: 116, height: 158,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OC.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line),
        boxShadow: [BoxShadow(color: OC.ink.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: f.hasCover
          ? CachedImage(f.coverUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(f))
          : _coverFallback(f),
    );
  }

  Widget _coverFallback(Fascicule f) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.ink, OC.ink2])),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Text(f.level.isEmpty ? (f.subject.isEmpty ? 'Fascicule' : f.subject) : f.level,
            maxLines: 3, overflow: TextOverflow.ellipsis,
            style: display(14, weight: FontWeight.w800).copyWith(color: Colors.white, height: 1.15)),
      );

  Widget _chip(IconData ic, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 13, color: OC.muted),
          const SizedBox(width: 6),
          Text(t, style: body(11.5, color: OC.ink2, weight: FontWeight.w700)),
        ]),
      );

  Widget _orderBar(Fascicule f) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: OC.bg, border: Border(top: BorderSide(color: OC.line, width: 1.5))),
      child: GestureDetector(
        onTap: () => openUrl(context, _orderUrl(f)),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366), // WhatsApp
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Précommander sur WhatsApp',
                style: body(15, weight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}
