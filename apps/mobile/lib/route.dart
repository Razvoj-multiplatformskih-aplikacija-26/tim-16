
import 'package:go_router/go_router.dart';
import 'package:svezko_app/screens/orders_screen.dart';

import 'screens/home_screen.dart';
import 'screens/item_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/item-detail',
      name: 'itemDetail',
      builder: (context, state) => ItemDetailScreen(),
    ),
    GoRoute(
        path:'/orders',
    name:'orders',
    builder: (context,state)=>const OrdersScreen(),),
  ],
);
