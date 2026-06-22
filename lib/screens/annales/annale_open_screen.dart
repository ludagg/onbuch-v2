import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/annale.dart';
import '../../services/database_service.dart';
import 'annale_detail_screen.dart';

/// Ouvre un document à partir de son id (lien de partage / deep link
/// `onbuch://annale/{id}` ou `…/a/{id}`). Charge l'[Annale] puis affiche sa fiche.
class AnnaleOpenScreen extends StatefulWidget {
  final String id;
  const AnnaleOpenScreen({super.key, required this.id});

  @override
  State<AnnaleOpenScreen> createState() => _AnnaleOpenScreenState();
}

class _AnnaleOpenScreenState extends State<AnnaleOpenScreen> {
  Annale? _a;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await DatabaseService().getAnnaleById(widget.id);
    if (mounted) setState(() { _a = a; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: OC.bg, body: const Center(child: CircularProgressIndicator(color: OC.o500)));
    }
    if (_a == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        appBar: AppBar(
          backgroundColor: OC.bg, surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.canPop() ? context.pop() : context.go('/annales')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.link_off_rounded, size: 46, color: OC.faint),
              const SizedBox(height: 12),
              Text('Document introuvable', style: display(18, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Ce lien n\'est plus valide ou le document a été retiré.',
                  textAlign: TextAlign.center, style: body(13.5, color: OC.muted)),
            ]),
          ),
        ),
      );
    }
    return AnnaleDetailScreen(annale: _a);
  }
}
