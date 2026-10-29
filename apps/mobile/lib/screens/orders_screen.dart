import 'package:flutter/material.dart';
import 'package:svezko_app/repository/mock_data.dart'; // PAZI: Ovaj import mora biti identičan u home_screen i item_detail_screen

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  void _cancelOrder(Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otkaži porudžbinu?'),
        content: Text('Da li ste sigurni da želite da otkažete porudžbinu za ${order.product.name}? Ova akcija je nepovratna.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zadrži'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                order.state = OrderState.cancelled;
              });
              // PROMENA 3: Obaveštavamo UI da se status jedne stavke promenio
              FakeDatabase.ordersNotifier.value = List.from(FakeDatabase.ordersNotifier.value);

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Porudžbina je otkazana.')),
              );
            },
            child: const Text('Otkaži', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje porudžbine')),

      // PROMENA 4: Ekran sada osluškuje ordersNotifier
      body: ValueListenableBuilder<List<Order>>(
        valueListenable: FakeDatabase.ordersNotifier,
        builder: (context, orders, child) {
          return orders.isEmpty
              ? const Center(
            child: Text(
              'Trenutno nemate nijednu porudžbinu.',
              style: TextStyle(fontSize: 16),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(order.product.name),
                  subtitle: Text('Količina: ${order.quantity} ${order.product.unit}\nStatus: ${order.state.nameSr}'),
                  isThreeLine: true,
                  trailing: order.state == OrderState.pending
                      ? IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () => _cancelOrder(order),
                    tooltip: 'Otkaži porudžbinu',
                  )
                      : const SizedBox.shrink(),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Otvorena porudžbina: ${order.product.name}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}