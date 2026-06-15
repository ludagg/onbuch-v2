import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/ob_widgets.dart';

class MainShell extends StatelessWidget {
  final String location;
  final Widget child;
  const MainShell({super.key, required this.location, required this.child});

  static const _routes = ['/home', '/results', '/tutor', '/annales', '/cours'];

  int get _index {
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: OBNavBar(
        currentIndex: _index,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}
