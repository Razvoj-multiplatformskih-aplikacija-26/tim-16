import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          const SizedBox(height: 24),
          Expanded(child: Card(clipBehavior: Clip.antiAlias, child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [DataColumn(label: Text('Broj')), DataColumn(label: Text('Datum')), DataColumn(label: Text('Kupac')), DataColumn(label: Text('Proizvod')), DataColumn(label: Text('Iznos')), DataColumn(label: Text('Isporuka')), DataColumn(label: Text('Status'))],
              rows: [for (final order in orders) DataRow(cells: [
                DataCell(Text(order.id.value)),
                DataCell(Text(_date(order.createdAt))),
                DataCell(Text(order.buyerId.value)),
                DataCell(Text(order.lines.map((line) => '${line.productName} × ${line.quantity.value}').join(', '))),
                DataCell(Text('${order.total} RSD')),
                DataCell(Text(order.method == DeliveryMethod.delivery ? order.address?.value ?? 'Kurir' : 'Preuzimanje')),
                DataCell(Chip(label: Text(_statusName(order.status)))),
              ])],
            ),
          ))),
        ]);
      },
    ),
  );

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _statusName(OrderStatus status) => switch (status) {
    Pending() => 'Na čekanju', Accepted() => 'Prihvaćena', Preparing() => 'U pripremi',
    Shipped() => 'Poslata', Delivered() => 'Isporučena', Cancelled(:final reason) => reason == CancelReason.byBuyer ? 'Otkazao kupac' : 'Otkazao proizvođač',
  };
}
