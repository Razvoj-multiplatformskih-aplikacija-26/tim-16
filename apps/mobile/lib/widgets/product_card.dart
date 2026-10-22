
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String producer;
  final double price;
  final String unit;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool isAvailable;

  const ProductCard({
    super.key,
    required this.name,
    required this.producer,
    required this.price,
    this.unit = 'kg',
    this.imageUrl,
    this.onTap,
    this.onAddToCart,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _imagePlaceholder(colorScheme);
                },
              )
                  : _imagePlaceholder(colorScheme),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    producer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${price.toStringAsFixed(0)} RSD',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'po $unit',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      if (onAddToCart != null)
                        IconButton.filled(
                          onPressed: isAvailable ? onAddToCart : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          tooltip: 'Dodaj u korpu',
                        ),
                    ],
                  ),

                  if (!isAvailable) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Trenutno nedostupno',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.eco_outlined,
        size: 52,
        color: colorScheme.primary,
      ),
    );
  }
}
