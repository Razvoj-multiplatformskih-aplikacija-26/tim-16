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
      margin: const EdgeInsets.only(bottom: 16),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Dodata blaga ivica kako bi kartica bila definisanija
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 160, // Povećana ukupna visina kartice
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LIJEVI DIO: Povećana slika
              SizedBox(
                width: 160,
                height: 160,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _imagePlaceholder(colorScheme);
                  },
                )
                    : _imagePlaceholder(colorScheme),
              ),

              // DESNI DIO: Podaci
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gornji red: Naslov i istaknuta cijena
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${price.toStringAsFixed(0)} RSD',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Srednji red: Proizvođač
                      Text(
                        producer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const Spacer(),

                      // Donji red: Jedinica mjere i gumb za dodavanje
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              'po $unit',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (onAddToCart != null)
                            SizedBox(
                              height: 36,
                              width: 90,
                              child: ElevatedButton(
                                onPressed: isAvailable ? onAddToCart : null,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('U korpu', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}