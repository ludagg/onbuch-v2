import 'package:flutter/material.dart';

/// Annonce d'accueil **entièrement configurable par l'admin**, affichée en tête
/// du carrousel d'examens (collection `home_announcements`).
///
/// Souple : image **et/ou** couleur de fond, eyebrow, titre, texte, et un bouton
/// d'action optionnel pointant vers une route interne (`/...`) ou une URL externe
/// (`https://…`, `onbuch://…`, `tel:…`, `wa.me/…`). Fenêtre de programmation
/// (start/end) et tri optionnels.
class HomeAnnouncement {
  final String id;
  final String eyebrow; // petit label en capitales (ex. « NOUVEAU »)
  final String title;
  final String body;
  final String imageUrl;
  final String ctaLabel; // texte du bouton (vide = pas de bouton)
  final String ctaTarget; // route interne (/…) ou URL (http…, onbuch://, tel:…)
  final String bgColor; // hex (#RRGGBB) — fond quand pas d'image
  final String textColor; // 'light' (défaut) | 'dark'
  final DateTime? startAt;
  final DateTime? endAt;
  final bool active;
  final int order;

  const HomeAnnouncement({
    required this.id,
    this.eyebrow = '',
    this.title = '',
    this.body = '',
    this.imageUrl = '',
    this.ctaLabel = '',
    this.ctaTarget = '',
    this.bgColor = '',
    this.textColor = 'light',
    this.startAt,
    this.endAt,
    this.active = true,
    this.order = 0,
  });

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasCta => ctaLabel.trim().isNotEmpty && ctaTarget.trim().isNotEmpty;
  bool get isLightText => textColor.trim().toLowerCase() != 'dark';

  /// Doit-on l'afficher maintenant ? (active + dans la fenêtre start/end).
  bool get isLive {
    if (!active) return false;
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  /// Couleur de fond depuis le hex admin (`#RRGGBB` ou `RRGGBB`), ou null.
  Color? get bgColorValue {
    var h = bgColor.trim().replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();
  static DateTime? _d(dynamic v) {
    final s = _s(v);
    return s.isEmpty ? null : DateTime.tryParse(s);
  }

  factory HomeAnnouncement.fromMap(Map<String, dynamic> d, {required String id}) {
    final ord = d['order'];
    return HomeAnnouncement(
      id: id,
      eyebrow: _s(d['eyebrow']),
      title: _s(d['title']),
      body: _s(d['body']),
      imageUrl: _s(d['imageUrl']),
      ctaLabel: _s(d['ctaLabel']),
      ctaTarget: _s(d['ctaTarget']),
      bgColor: _s(d['bgColor']),
      textColor: _s(d['textColor']).isEmpty ? 'light' : _s(d['textColor']),
      startAt: _d(d['startAt']),
      endAt: _d(d['endAt']),
      active: d['active'] != false,
      order: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }
}
