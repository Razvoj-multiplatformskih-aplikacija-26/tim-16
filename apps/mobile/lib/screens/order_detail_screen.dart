import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/labels.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/error_view.dart';


class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final OrderId orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Porudžbina')),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) => switch (state) {
          ShopLoading() => const Center(child: CircularProgressIndicator()),
          ShopError(:final message) => ErrorView(message: message),
          ShopEmpty() => const _NotFound(),
          final ShopLoaded loaded => _content(context, loaded),
        },
      ),
    );
  }

  Widget _content(BuildContext context, ShopLoaded state) {
    final order = state.orders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) return const _NotFound();

    String unitOf(OrderLine line) =>
        state.products
            .where((p) => p.id == line.productId)
            .firstOrNull
            ?.unit
            .label ??
            '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(order.status.detail, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Napravljena ${formatDateTime(order.createdAt)}'),
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.storefront_outlined,
          text: state.producerName(order.producerId),
        ),
        _InfoRow(
          icon: order.method == DeliveryMethod.delivery
              ? Icons.local_shipping_outlined
              : Icons.store_outlined,
          text: order.address == null
              ? order.method.label
              : '${order.method.label}: ${order.address!.value}',
        ),
        const SizedBox(height: 16),
        Text('Stavke', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final line in order.lines)
                ListTile(
                  title: Text(line.productName),
                  subtitle: Text(
                    '${line.quantity.value} ${unitOf(line)} × '
                        '${formatDinars(line.unitPrice.dinars)}',
                  ),
                  trailing: Text(formatDinars(line.total)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Ukupno: ${formatDinars(order.total)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (canCancel(order.status)) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => confirmCancelOrder(context, order),
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text(
              'Otkaži porudžbinu',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Porudžbina nije pronađena.'));
}