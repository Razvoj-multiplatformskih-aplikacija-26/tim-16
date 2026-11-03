import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackofficeShell extends StatelessWidget {
  const BackofficeShell({required this.child, super.key});

  final Widget child;

  static const _destinations = [
    (label: 'Pregled', path: '/', icon: Icons.dashboard_outlined),
    (label: 'Proizvodi', path: '/products', icon: Icons.inventory_2_outlined),
    (label: 'Porudžbine', path: '/orders', icon: Icons.receipt_long_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _destinations.indexWhere((item) =>
        item.path == location || (item.path == '/products' && location.startsWith('/products/')));
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 900,
            selectedIndex: selected < 0 ? 0 : selected,
            onDestinationSelected: (index) =>
                context.go(_destinations[index].path),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'SVEŽKO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            destinations: [
              for (final item in _destinations)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
