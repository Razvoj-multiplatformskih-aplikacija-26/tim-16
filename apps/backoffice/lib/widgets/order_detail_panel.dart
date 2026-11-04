import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/order_presentation.dart';

/// Detalj jedne porudžbine. Na širokom ekranu stoji u bočnom panelu,
/// na uskom se prikazuje ispod izabrane kartice.
class OrderDetailPanel extends StatelessWidget {
  const OrderDetailPanel({
    required this.order,
    required this.onChangeStatus,
    required this.onClose,
    this.canEdit = true,
    super.key,
  });

  final Order order;
  final VoidCallback onChangeStatus;
  final VoidCallback onClose;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canChange = canEdit && nextStatuses(order.status).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Porudžbina ${order.id.value}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Zatvori detalj (Esc)',
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Chip(label: Text(order.status.label)),
        const SizedBox(height: 16),
        _InfoRow(label: 'Datum', value: formatDateTime(order.createdAt)),
        _InfoRow(label: 'Kupac', value: order.buyerId.value),
        _InfoRow(label: 'Isporuka', value: deliveryLabel(order)),
        const Divider(height: 32),
        Text('Stavke', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final line in order.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('${line.productName} × ${line.quantity.value}'),
                ),
                Text('${line.total} RSD'),
              ],
            ),
          ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(child: Text('Ukupno', style: theme.textTheme.titleMedium)),
            Text(
              '${order.total} RSD',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: canChange ? onChangeStatus : null,
          icon: const Icon(Icons.swap_horiz),
          label: Text(
            canChange ? 'Promeni status (Enter)' : 'Nema dozvoljene promene',
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
