import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        if (state is ShopLoading) return const Center(child: CircularProgressIndicator());
        if (state is ShopError) return Center(child: Text(state.message));
        if (state is! ShopLoaded) return const Center(child: Text('Nema proizvoda.'));
        final products = state.products;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Proizvodi', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('${products.length} proizvoda u ponudi'),
          const SizedBox(height: 24),
          Expanded(child: Card(clipBehavior: Clip.antiAlias, child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [DataColumn(label: Text('Proizvod')), DataColumn(label: Text('Proizvođač')), DataColumn(label: Text('Kategorija')), DataColumn(label: Text('Cena')), DataColumn(label: Text('Zaliha'))],
              rows: [for (final product in products) DataRow(cells: [
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  if (product.imageUrl.isNotEmpty) ...[
                    ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(product.imageUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(width: 44, height: 44, child: Icon(Icons.image_not_supported_outlined)))),
                    const SizedBox(width: 12),
                  ],
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(product.name.value, style: const TextStyle(fontWeight: FontWeight.w600)), Text(product.description, style: Theme.of(context).textTheme.bodySmall)]),
                ])),
                DataCell(Text(state.producerName(product.producerId))),
                DataCell(Text(_categoryName(product.category))),
                DataCell(Text('${product.price.dinars} RSD / ${_unitName(product.unit)}')),
                DataCell(Text('${product.stock.units} ${_unitName(product.unit)}${product.stock.units == 0 ? ' · Nema na stanju' : ''}')),
              ])],
            ),
          ))),
        ]);
      },
    ),
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
}
