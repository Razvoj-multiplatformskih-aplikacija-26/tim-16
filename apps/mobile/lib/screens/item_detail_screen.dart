import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // DODATO
import '../theme/colors.dart';
import '../widgets/app_button.dart';
import '../widgets/quantity_selector.dart';

class ItemDetailScreen extends StatelessWidget {
  final Product product;

  const ItemDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                product.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 8.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              background: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.eco_outlined, size: 100, color: Colors.green),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 22, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          product.producer,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} RSD',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                          child: Text(
                            '/ ${product.unit}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dostupno: ${product.availableQuantity} ${product.unit}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Opis proizvoda',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Količina',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    _QuantityPriceRow(product: product),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityPriceRow extends StatefulWidget {
  final Product product;
  const _QuantityPriceRow({required this.product});

  @override
  State<_QuantityPriceRow> createState() => _QuantityPriceRowState();
}

class _QuantityPriceRowState extends State<_QuantityPriceRow> {
  int quantity = 1;
  String? errorMessage;

  void _validateAndSubmit() {
    if (quantity > widget.product.availableQuantity) {
      setState(() {
        errorMessage = 'Nedovoljna količina na stanju. Dostupno je ${widget.product.availableQuantity} ${widget.product.unit}.';
      });
      return;
    }

    setState(() => errorMessage = null);

    // ZAMENJENO: Šaljemo BLoC događaj za kreiranje porudžbine!
    context.read<ShopBloc>().add(CreateOrderEvent(widget.product, quantity));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity ${widget.product.unit} proizvoda uspješno poručeno!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            QuantitySelector(
              onChanged: (value) {
                setState(() { quantity = value; errorMessage = null; });
              },
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '${(widget.product.price * quantity).toStringAsFixed(0)} RSD',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        AppButton(
          text: 'Naruči',
          icon: Icons.shopping_cart_outlined,
          onPressed: _validateAndSubmit,
        ),
      ],
    );
  }
}