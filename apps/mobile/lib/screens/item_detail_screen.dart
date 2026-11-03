import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/domain_errors.dart';
import '../text/labels.dart';
import '../theme/colors.dart';
import '../widgets/app_button.dart';
import '../widgets/error_view.dart';
import '../widgets/quantity_selector.dart';


class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.productId});

  final ProductId productId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) => switch (state) {
        ShopLoading() => const _Shell(
          child: Center(child: CircularProgressIndicator()),
        ),
        ShopError(:final message) => _Shell(child: ErrorView(message: message)),
        ShopEmpty() => const _Shell(child: _NotFound()),
        final ShopLoaded loaded => _loaded(loaded),
      },
    );
  }

  Widget _loaded(ShopLoaded state) {
    final product = state.products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return const _Shell(child: _NotFound());
    return _ProductView(
      product: product,
      producerName: state.producerName(product.producerId),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(), body: child);
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Proizvod nije pronađen.'));
}

class _ProductView extends StatelessWidget {
  const _ProductView({required this.product, required this.producerName});

  final Product product;
  final String producerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = product.unit.label;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                product.name.value,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 8.0,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              background: product.imageUrl.isEmpty
                  ? const _ImagePlaceholder()
                  : Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                const _ImagePlaceholder(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 22,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          producerName,
                          style: theme.textTheme.titleMedium?.copyWith(
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
                          formatDinars(product.price.dinars),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                          child: Text(
                            '/ $unit',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dostupno: ${product.stock.units} $unit',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Opis proizvoda',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Količina',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OrderForm(product: product),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.eco_outlined, size: 100, color: Colors.green),
    );
  }
}


class _OrderForm extends StatefulWidget {
  const _OrderForm({required this.product});

  final Product product;

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final TextEditingController _addressController = TextEditingController();
  int _quantity = 1;
  DeliveryMethod _method = DeliveryMethod.pickup;
  String? _quantityError;
  String? _addressError;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    final quantityResult = Quantity.parse(
      _quantity,
      available: widget.product.stock.units,
    );

    DeliveryAddress? address;
    String? addressError;
    if (_method == DeliveryMethod.delivery) {
      final addressResult = DeliveryAddress.parse(_addressController.text);
      address = addressResult.valueOrNull;
      addressError = addressResult.errorOrNull?.message;
    }

    setState(() {
      _quantityError = quantityResult.errorOrNull?.message;
      _addressError = addressError;
    });
    if (!quantityResult.isSuccess || addressError != null) return;

    context.read<ShopBloc>().add(
      CreateOrderEvent(
        productId: widget.product.id,
        quantity: _quantity,
        method: _method,
        address: address,
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
              onChanged: (value) => setState(() {
                _quantity = value;
                _quantityError = null;
              }),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                formatDinars(widget.product.price.dinars * _quantity),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (_quantityError != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _quantityError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        SegmentedButton<DeliveryMethod>(
          segments: [
            ButtonSegment(
              value: DeliveryMethod.pickup,
              label: Text(DeliveryMethod.pickup.label),
              icon: const Icon(Icons.store_outlined),
            ),
            ButtonSegment(
              value: DeliveryMethod.delivery,
              label: Text(DeliveryMethod.delivery.label),
              icon: const Icon(Icons.local_shipping_outlined),
            ),
          ],
          selected: {_method},
          onSelectionChanged: (selection) => setState(() {
            _method = selection.first;
            _addressError = null;
          }),
        ),
        if (_method == DeliveryMethod.delivery) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Adresa isporuke',
              errorText: _addressError,
            ),
            onChanged: (_) {
              if (_addressError != null) setState(() => _addressError = null);
            },
          ),
        ],
        const SizedBox(height: 32),
        AppButton(
          text: 'Naruči',
          icon: Icons.shopping_cart_outlined,
          onPressed: _submit,
        ),
      ],
    );
  }
}