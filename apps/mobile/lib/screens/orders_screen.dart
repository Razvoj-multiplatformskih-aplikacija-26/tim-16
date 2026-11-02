import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // DODATO

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  void _cancelOrder(BuildContext context, Order order) {
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
              // ZAMENJENO: Šaljemo BLoC događaj za otkazivanje porudžbine!
              context.read<ShopBloc>().add(CancelOrderEvent(order));

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

      // ZAMENJENO: ValueListenableBuilder je postao BlocBuilder
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShopError) {
            return Center(child: Text(state.message));
          }

          if (state is ShopLoaded) {
            final orders = state.orders;

            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  'Trenutno nemate nijednu porudžbinu.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
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
                      onPressed: () => _cancelOrder(context, order),
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
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}