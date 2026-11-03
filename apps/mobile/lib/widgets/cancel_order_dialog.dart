import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../text/labels.dart';


Future<void> confirmCancelOrder(BuildContext context, Order order) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Otkaži porudžbinu?'),
      content: Text(
        'Da li ste sigurni da želite da otkažete porudžbinu „${order.title}“? '
            'Ova akcija je nepovratna.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Zadrži'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Otkaži', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<ShopBloc>().add(CancelOrderEvent(order.id));
  }
}