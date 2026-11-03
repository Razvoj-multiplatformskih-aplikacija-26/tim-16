import 'package:go_router/go_router.dart';

import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
import 'screens/add_product_screen.dart';
import 'widgets/backoffice_shell.dart';

final backofficeRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => BackofficeShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
        builder: (_, _) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/products',
          name: 'products',
        builder: (_, _) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/products/new',
          name: 'add-product',
          builder: (_, _) => const AddProductScreen(),
        ),
        GoRoute(
          path: '/orders',
          name: 'orders',
        builder: (_, _) => const OrdersScreen(),
        ),
      ],
    ),
  ],
);
