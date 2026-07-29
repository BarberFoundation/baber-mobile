import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'stripe_bar.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StripeBar(height: 3),
          NavigationBar(
            // Follows the ambient theme's navigationBarTheme (AppTheme.dark/
            // light both set backgroundColor: palette.surface) instead of a
            // hardcoded dark surface — this bar used to stay dark even in
            // light mode.
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
              NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Consultas'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ],
      ),
    );
  }
}
