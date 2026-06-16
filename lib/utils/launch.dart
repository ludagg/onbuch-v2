import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Ouvre un lien externe (http, tel, mailto…) ou affiche un message si échec.
Future<void> openUrl(BuildContext context, String? url) async {
  final raw = (url ?? '').trim();
  final uri = Uri.tryParse(raw);
  if (raw.isEmpty || uri == null) {
    _toast(context, 'Lien indisponible.');
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, 'Impossible d\'ouvrir le lien.');
  } catch (_) {
    if (context.mounted) _toast(context, 'Impossible d\'ouvrir le lien.');
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
    backgroundColor: OC.ink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
  ));
}
