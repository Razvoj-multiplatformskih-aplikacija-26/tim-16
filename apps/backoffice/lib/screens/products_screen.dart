import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/shortcut.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: BlocBuilder<ShopBloc, ShopState>(builder: (context, state) {
      if (state is ShopLoading) return const Center(child: CircularProgressIndicator());
      if (state is ShopError) return Center(child: Text(state.message));
      if (state is! ShopLoaded) return const Center(child: Text('Nema proizvoda.'));
      final products = state.products;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Proizvodi', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('${products.length} proizvoda u ponudi')),
          FilledButton.icon(
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj proizvod'),
          ),
        ]),
        const Text('Tastatura: ↑/↓ kretanje · Home/End prvi ili poslednji zapis'),
        const SizedBox(height: 24),
        Expanded(child: RecordShortcuts(itemCount: products.length, builder: (context, focusedIndex) => Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            columns: const [
              DataColumn(label: Text('Proizvod')), DataColumn(label: Text('Proizvođač')),
              DataColumn(label: Text('Kategorija')), DataColumn(label: Text('Cena')),
              DataColumn(label: Text('Zaliha')), DataColumn(label: Text('Akcija')),
            ],
            rows: [for (var i = 0; i < products.length; i++)
              DataRow(selected: focusedIndex == i, onSelectChanged: (_) {}, cells: [
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  if (products[i].imageUrl.isNotEmpty) ...[
                    ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(
                      products[i].imageUrl, width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(width: 44, height: 44, child: Icon(Icons.image_not_supported_outlined)),
                    )),
                    const SizedBox(width: 12),
                  ],
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(products[i].name.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(products[i].description, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ])),
                DataCell(Text(state.producerName(products[i].producerId))),
                DataCell(Text(_categoryName(products[i].category))),
                DataCell(Text('${products[i].price.dinars} RSD / ${_unitName(products[i].unit)}')),
                DataCell(Text('${products[i].stock.units} ${_unitName(products[i].unit)}')),
                DataCell(IconButton(tooltip: 'Obriši proizvod', icon: const Icon(Icons.delete_outline), onPressed: () => _deleteProduct(context, products[i]))),
              ])],
          )),
        ))),
      ]);
    }),
  );

  String _categoryName(ProductCategory value) => switch (value) {
    ProductCategory.fruit => 'Voće', ProductCategory.vegetables => 'Povrće',
    ProductCategory.dairy => 'Mlečni proizvodi', ProductCategory.honey => 'Med',
    ProductCategory.preserves => 'Prerađevine',
  };

  String _unitName(ProductUnit value) => switch (value) {
    ProductUnit.kilogram => 'kg', ProductUnit.piece => 'kom',
    ProductUnit.liter => 'l', ProductUnit.jar => 'tegla',
  };

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Obriši proizvod?'),
      content: Text('„${product.name.value}“ biće uklonjen iz ponude.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Obriši')),
      ],
    ));
    if (confirmed == true && context.mounted) context.read<ShopBloc>().add(DeleteProductEvent(product.id));
  }
}

