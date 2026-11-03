import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../text/labels.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/error_view.dart';


class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje porudžbine')),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) => switch (state) {
          ShopLoading() => const Center(child: CircularProgressIndicator()),
          ShopError(:final message) => ErrorView(message: message),
          ShopEmpty() => const _EmptyOrders(),
          final ShopLoaded loaded => loaded.orders.isEmpty
              ? const _EmptyOrders()
              : _OrdersList(orders: loaded.orders),
        },
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Trenutno nemate nijednu porudžbinu.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(order.title),
            subtitle: Text(
              '${order.status.detail}\n'
                  '${formatDinars(order.total)} · ${formatDateTime(order.createdAt)}',
            ),
            isThreeLine: true,
            trailing: canCancel(order.status)
                ? IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: 'Otkaži porudžbinu',
              onPressed: () => confirmCancelOrder(context, order),
            )
                : null,
            onTap: () => context.push('/orders/${order.id.value}'),
          ),
        );
      },
    );
  }
}