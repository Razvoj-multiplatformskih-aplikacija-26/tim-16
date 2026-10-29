import 'package:go_router/go_router.dart';
import 'package:svezko_app/repository/mock_data.dart';

import 'screens/home_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/filter_screen.dart'; // DODAT IMPORT ZA FILTER SCREEN
import 'widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // 1. POČETNI EKRAN (HOME GRANA)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'item-detail', // puna adresa: /item-detail
                  name: 'itemDetail',
                  builder: (context, state) => ItemDetailScreen(
                    product: state.extra as Product,
                  ),
                ),
                // DODATA RUTA ZA FILTERE
                GoRoute(
                  path: 'filters', // puna adresa: /filters
                  name: 'filters',
                  builder: (context, state) => FilterScreen(
                    // Hvatamo prosleđene filtere da bi klizač znao gde da stane
                    initialFilters: state.extra as FilterOptions?,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. PORUDŽBINE GRANA
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              name: 'orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),

        // 3. PROFIL GRANA
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