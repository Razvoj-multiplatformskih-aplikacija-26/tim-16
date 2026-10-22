
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/quantity_selector.dart';
import 'profile_screen.dart';
class ItemDetailScreen extends StatelessWidget {
  ItemDetailScreen({super.key});

  final String productName = 'Domaće jabuke';
  final String producer = 'Gazdinstvo Petrović';
  final double price = 150;
  final String unit = 'kg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Detalji proizvoda'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slika proizvoda
            Container(
              width: double.infinity,
              height: 240,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: const Icon(
                Icons.eco_outlined,
                size: 100,
                color: Colors.green,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Naziv proizvoda
                  Text(
                    productName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Proizvođač
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(producer),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Cena po jedinici
                  Text(
                    '${price.toStringAsFixed(0)} RSD / $unit',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Opis proizvoda
                  Text(
                    'Opis proizvoda',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sveže domaće jabuke iz lokalnog '
                        'gazdinstva. Uzgajane sa pažnjom, '
                        'idealne za svakodnevnu ishranu.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Izbor količine i ukupna cena
                  Text(
                    'Količina ($unit)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _QuantityPriceRow(
                    price: price,
                    unit: unit,
                    onAddToCart: (quantity) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            '$quantity $unit proizvoda '
                                'dodato je u korpu!',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: (index) {

        },
      ),
    );
  }
}

class _QuantityPriceRow extends StatefulWidget {
  final double price;
  final String unit;
  final ValueChanged<int> onAddToCart;

  const _QuantityPriceRow({
    required this.price,
    required this.unit,
    required this.onAddToCart,
  });

  @override
  State<_QuantityPriceRow> createState() =>
      _QuantityPriceRowState();
}

class _QuantityPriceRowState
    extends State<_QuantityPriceRow> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            QuantitySelector(
              onChanged: (value) {
                setState(() {
                  quantity = value;
                });
              },
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '${(widget.price * quantity).toStringAsFixed(0)} RSD',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        AppButton(
          text: 'Dodaj u korpu',
          icon: Icons.shopping_cart_outlined,
          onPressed: () {
            widget.onAddToCart(quantity);
          },
        ),
      ],
    );
  }
}
