import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Lien vers un réseau social OnBuch, configuré par l'admin (collection
/// `social_links`) et lu par l'app (écran Communauté + accueil).
class SocialLink {
  final String platform; // whatsapp/telegram/tiktok/facebook/youtube/instagram/other
  final String label;
  final String? description;
  final String url;
  final int order;
  final bool active;

  const SocialLink({
    required this.platform,
    required this.label,
    required this.url,
    this.description,
    this.order = 0,
    this.active = true,
  });

  factory SocialLink.fromMap(Map<String, dynamic> m) {
    final order = m['order'];
    return SocialLink(
      platform: (m['platform'] ?? 'other').toString().trim().toLowerCase(),
      label: (m['label'] ?? '').toString(),
      description: _s(m['description']),
      url: (m['url'] ?? '').toString().trim(),
      order: order is int ? order : int.tryParse('$order') ?? 0,
      active: m['active'] != false,
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Icône de marque (Font Awesome) selon la plateforme.
  FaIconData get faIcon {
    switch (platform) {
      case 'whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      case 'facebook':
        return FontAwesomeIcons.facebookF;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      default:
        return FontAwesomeIcons.link;
    }
  }

  /// Couleur de marque selon la plateforme.
  Color get color {
    switch (platform) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'telegram':
        return const Color(0xFF2AABEE);
      case 'tiktok':
        return const Color(0xFF111111);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE1306C);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
