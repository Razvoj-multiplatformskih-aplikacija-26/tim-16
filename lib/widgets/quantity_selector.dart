
import 'package:flutter/material.dart';

class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int minQuantity;
  final ValueChanged<int>? onChanged;

  const QuantitySelector({
    super.key,
    this.initialQuantity = 1,
    this.minQuantity = 1,
    this.onChanged,
  });

  @override
  State<QuantitySelector> createState() =>
      _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
  }

  void decreaseQuantity() {
    if (quantity > widget.minQuantity) {
      setState(() {
        quantity--;
      });

      widget.onChanged?.call(quantity);
    }
  }

  void increaseQuantity() {
    setState(() {
      quantity++;
    });

    widget.onChanged?.call(quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity > widget.minQuantity
              ? decreaseQuantity
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: increaseQuantity,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
