import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/ob_widgets.dart';
import '../services/push_service.dart';

class MainShell extends StatefulWidget {
  final String location;
  final Widget child;
  const MainShell({super.key, required this.location, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _routes = ['/home', '/concours', '/tutor', '/annales', '/cours'];

  @override
  void initState() {
    super.initState();
    // L'utilisateur est connecté (on est dans la coque principale) : on
    // (ré)enregistre sa cible push. Idempotent et best-effort.
    PushService.instance.registerForCurrentUser();
  }

  int get _index {
    for (int i = 0; i < _routes.length; i++) {
      if (widget.location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: OBNavBar(
        currentIndex: _index,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}
