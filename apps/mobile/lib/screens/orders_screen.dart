import 'package:flutter/material.dart';

class _DemoOrder {
  const _DemoOrder(this.product, this.status, this.quantity);
  final String product;
  final String status;
  final int quantity;
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _orders = [
    _DemoOrder('Domaće maline', 'Na čekanju', 2),
    _DemoOrder('Med od livade', 'Prihvaćena', 1),
    _DemoOrder('Sir kozji', 'Isporučena', 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje porudžbine')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(order.product),
              subtitle: Text('Količina: ${order.quantity}'),
              trailing: Text(order.status),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Otvoreno: ${order.product}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}