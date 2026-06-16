import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Élément « À l'affiche » : événement ou partenaire sponsorisé.
class AfficheItem {
  final String id;
  final String type; // event | sponsored | info
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final DateTime? date;
  final String? location;
  final String? description;
  final String? partnerName;
  final String? partnerLogo;
  final String? partnerDescription;
  final String? link;
  final int order;

  const AfficheItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.date,
    this.location,
    this.description,
    this.partnerName,
    this.partnerLogo,
    this.partnerDescription,
    this.link,
    this.order = 0,
  });

  bool get isSponsored => type == 'sponsored';

  String get badge {
    switch (type) {
      case 'sponsored': return 'SPONSORISÉ';
      case 'info': return 'À LA UNE';
      default: return 'ÉVÉNEMENT';
    }
  }

  Color get badgeColor {
    switch (type) {
      case 'sponsored': return const Color(0xFF3A3346);
      case 'info': return OC.blue;
      default: return OC.o500;
    }
  }

  factory AfficheItem.fromMap(Map<String, dynamic> d, {required String id}) {
    String? s(dynamic v) {
      if (v == null) return null;
      final x = v.toString().trim();
      return x.isEmpty ? null : x;
    }

    return AfficheItem(
      id: id,
      type: (d['type'] ?? 'event').toString(),
      title: (d['title'] ?? '').toString(),
      subtitle: s(d['subtitle']),
      imageUrl: s(d['imageUrl']),
      date: d['date'] == null ? null : DateTime.tryParse(d['date'].toString())?.toLocal(),
      location: s(d['location']),
      description: s(d['description']),
      partnerName: s(d['partnerName']),
      partnerLogo: s(d['partnerLogo']),
      partnerDescription: s(d['partnerDescription']),
      link: s(d['link']),
      order: d['order'] is int ? d['order'] as int : int.tryParse('${d['order']}') ?? 0,
    );
  }
}
