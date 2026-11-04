import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:blocs/blocs.dart';
import '../data/demo_shop_repository.dart';

class BackofficeShell extends StatelessWidget {
  const BackofficeShell({required this.child, super.key});
  final Widget child;

  static const _destinations = [
    (label: 'Pregled', path: '/', icon: Icons.dashboard_outlined),
    (label: 'Moji proizvodi', path: '/my-products', icon: Icons.inventory_2_outlined),
    (label: 'Svi proizvodi', path: '/products', icon: Icons.storefront_outlined),
    (label: 'Moje porudžbine', path: '/my-orders', icon: Icons.receipt_long_outlined),
    (label: 'Sve porudžbine', path: '/orders', icon: Icons.list_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _destinations.indexWhere((item) => item.path == location ||
        (item.path == '/my-products' && location.startsWith('/products/')));
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          extended: MediaQuery.sizeOf(context).width >= 900,
          selectedIndex: selected < 0 ? 0 : selected,
          onDestinationSelected: (index) => context.go(_destinations[index].path),
          leading: const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('SVEŽKO', style: TextStyle(fontWeight: FontWeight.bold))),
          trailing: PopupMenuButton<_DebugAction>(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            tooltip: 'Izazovi grešku (test)',
            onSelected: (action) {
              final repository = context.read<ShopRepository>();
              if (repository is DemoShopRepository) repository.forceError();
              if (action == _DebugAction.load) {
                context.read<ShopBloc>().add(const LoadShopDataEvent());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _DebugAction.load, child: Text('Greška pri učitavanju')),
              PopupMenuItem(value: _DebugAction.save, child: Text('Greška pri sledećem čuvanju')),
            ],
          ),
          destinations: [for (final item in _destinations) NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label))],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}

enum _DebugAction { load, save }
