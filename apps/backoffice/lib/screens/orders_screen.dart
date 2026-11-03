import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/shortcut.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        if (state is ShopLoading) return const Center(child: CircularProgressIndicator());
        if (state is ShopError) return Center(child: Text(state.message));
        if (state is! ShopLoaded) return const Center(child: Text('Nema porudžbina.'));
        final orders = state.orders;
        final pending = orders.where((order) => order.status is Pending).length;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Porudžbine', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('${orders.length} ukupno · $pending na čekanju'),
          const Text('Tastatura: ↑/↓ kretanje · Home/End prvi ili poslednji zapis · Enter promena statusa'),
          const SizedBox(height: 24),
          Expanded(child: RecordShortcuts(itemCount: orders.length, onActivate: (index) => _changeStatus(context, orders[index]), builder: (context, focusedIndex) => Card(clipBehavior: Clip.antiAlias, child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [DataColumn(label: Text('Broj')), DataColumn(label: Text('Datum')), DataColumn(label: Text('Kupac')), DataColumn(label: Text('Proizvod')), DataColumn(label: Text('Iznos')), DataColumn(label: Text('Isporuka')), DataColumn(label: Text('Status'))],
              rows: [for (var i = 0; i < orders.length; i++) DataRow(selected: focusedIndex == i, onSelectChanged: (_) => _changeStatus(context, orders[i]), cells: [
                DataCell(Text(orders[i].id.value)),
                DataCell(Text(_date(orders[i].createdAt))),
                DataCell(Text(orders[i].buyerId.value)),
                DataCell(Text(orders[i].lines.map((line) => '${line.productName} × ${line.quantity.value}').join(', '))),
                DataCell(Text('${orders[i].total} RSD')),
                DataCell(Text(orders[i].method == DeliveryMethod.delivery ? orders[i].address?.value ?? 'Kurir' : 'Preuzimanje')),
                DataCell(Chip(label: Text(_statusName(orders[i].status)))),
              ])],
            ),
          )))),
        ]);
      },
    ),
  );

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _statusName(OrderStatus status) => switch (status) {
    Pending() => 'Na čekanju', Accepted() => 'Prihvaćena', Preparing() => 'U pripremi',
    Shipped() => 'Poslata', Delivered() => 'Isporučena', Cancelled(:final reason) => reason == CancelReason.byBuyer ? 'Otkazao kupac' : 'Otkazao proizvođač',
  };

  Future<void> _changeStatus(BuildContext context, Order order) async {
    final choices = <OrderStatus>[
      Accepted(acceptedAt: DateTime.now()), const Preparing(),
      Shipped(shippedAt: DateTime.now()), const Delivered(),
      const Cancelled(CancelReason.byProducer),
    ].where((status) => canTransition(order.status, status)).toList();
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Za ovu porudžbinu nema dozvoljene promene statusa.')));
      return;
    }
    final selected = await showDialog<OrderStatus>(context: context, builder: (context) => AlertDialog(
      title: Text('Promeni status · ${order.id.value}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final status in choices) ListTile(title: Text(_statusName(status)), onTap: () => Navigator.pop(context, status)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani'))],
    ));
    if (selected != null && context.mounted) {
      context.read<ShopBloc>().add(ChangeOrderStatusEvent(orderId: order.id, status: selected));
    }
  }
}


