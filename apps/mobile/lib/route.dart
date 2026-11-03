import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/filter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // 1. Početni ekran
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'products/:id', // /products/p1
                  name: 'productDetail',
                  builder: (context, state) => ItemDetailScreen(
                    productId: ProductId(state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: 'filters', // /filters
                  name: 'filters',
                  builder: (context, state) => FilterScreen(
                    initialFilters: state.extra as FilterOptions?,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Porudžbine
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              name: 'orders',
              builder: (context, state) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':id', // /orders/o-1001
                  name: 'orderDetail',
                  builder: (context, state) => OrderDetailScreen(
                    orderId: OrderId(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 3. Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);