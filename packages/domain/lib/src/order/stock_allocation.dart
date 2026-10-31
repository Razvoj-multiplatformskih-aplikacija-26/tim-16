import 'package:domain/src/result.dart';

import '../errors.dart';
import '../identifiers.dart';
import '../product/product.dart';
import '../product/stock.dart';
import 'order.dart';
import 'order_status.dart';

Map<ProductId,int>_quantitiesByProduct(Order order)
{
  final needed=<ProductId,int>{};
  for(final line in order.lines)
    {
      needed.update(
        line.productId,
          (sum)=>sum+line.quantity.value,
        ifAbsent: ()=>line.quantity.value,
      );
    }
  return needed;
}

Result<List<Product>> reserveStock(Order order,List<Product>products)
{
  final byId={for(final p in products) p.id:p};
  final updated=<ProductId,Product>{};

  for(final entry in _quantitiesByProduct(order).entries){
    final product = byId[entry.key];
    if (product == null) {
      return Failure<List<Product>>(ProductNotFound(entry.key));
    }
    final available = product.stock.units;
    if (entry.value > available) {
      return Failure<List<Product>>(
        InsufficientStock(
          productId: entry.key,
          requested: entry.value,
          available: available,
        ),
      );
    }
    final newStock = Stock.parse(available - entry.value).valueOrNull!;
    updated[entry.key] = product.copyWith(stock: newStock);
  }

  return Success<List<Product>>([for (final p in products) updated[p.id] ?? p]);
}

sealed class StockDecision {
  const StockDecision();
}

final class CanFulfil extends StockDecision {
  const CanFulfil();
}

final class CannotFulfil extends StockDecision {
  const CannotFulfil({
    required this.productId,
    required this.requested,
    required this.available,
  });
  final ProductId productId;
  final int requested;
  final int available;
}

///bitna metoda
Map<OrderId, StockDecision> allocateStock({
  required List<Product> products,
  required List<Order> orders,
}) {
  final remaining = {for (final p in products) p.id: p.stock.units};

  final pending = orders.where((o) => o.status is Pending).toList()
    ..sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.value.compareTo(b.id.value);
    });

  final decisions = <OrderId, StockDecision>{};
  for (final order in pending) {
    final needed = _quantitiesByProduct(order);

    StockDecision decision = const CanFulfil();
    for (final entry in needed.entries) {
      final available = remaining[entry.key] ?? 0;
      if (entry.value > available) {
        decision = CannotFulfil(
          productId: entry.key,
          requested: entry.value,
          available: available,
        );
        break;
      }
    }

    if (decision is CanFulfil) {
      for (final entry in needed.entries) {
        remaining[entry.key] = remaining[entry.key]! - entry.value;
      }
    }
    decisions[order.id] = decision;
  }
  return decisions;
}