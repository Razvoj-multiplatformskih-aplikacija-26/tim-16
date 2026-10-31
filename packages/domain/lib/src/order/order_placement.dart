import 'package:domain/src/errors.dart';
import 'package:domain/src/order/quantity.dart';
import 'package:domain/src/order/transitions.dart';
import 'package:domain/src/result.dart';

import '../identifiers.dart';
import '../product/product.dart';
import '../user.dart';
import 'delivery_address.dart';
import 'order.dart';
import 'order_status.dart';

const int maxActiveOrders =5;

final class OrderRequestLine{
  const OrderRequestLine({required this.productId,required this.quantity});
  final ProductId productId;
  final int quantity;
}

///Pravljenje porudzbine, proveravamo sve
Result<Order>placeOrder({
  required OrderId id,
  required User buyer,
required List<OrderRequestLine> request,
required List<Product> catalog,
required List<Order> existingOrders,
required DeliveryMethod method,
DeliveryAddress? address,
required DateTime now,
}){
  if(buyer.role != UserRole.buyer)
    {
      return Failure<Order>(NotAuthorized(buyer.id));
    }
  if (request.isEmpty) {
    return const Failure<Order>(EmptyOrder());
  }
  if (method == DeliveryMethod.delivery && address == null) {
    return const Failure<Order>(AddressRequired());
  }

  final activeCount = existingOrders
      .where((o) => o.buyerId == buyer.id && isActive(o.status))
      .length;
  if (activeCount >= maxActiveOrders) {
    return const Failure<Order>(TooManyActiveOrders(maxActiveOrders));
  }

  final byId = {for (final p in catalog) p.id: p};
  final seen = <ProductId>{};
  final lines = <OrderLine>[];
  UserId? producerId;

  for (final item in request) {
    if (!seen.add(item.productId)) {
      return Failure<Order>(DuplicateProductInOrder(item.productId));
    }
    final product = byId[item.productId];
    if (product == null || !product.published) {
      return Failure<Order>(ProductNotFound(item.productId));
    }
    if (producerId != null && producerId != product.producerId) {
      return const Failure<Order>(MixedProducers());
    }
    producerId = product.producerId;

    final parsed = Quantity.parse(
      item.quantity,
      available: product.stock.units,
    );
    final error = parsed.errorOrNull;
    if (error != null) return Failure<Order>(error);

    lines.add(
      OrderLine(
        productId: product.id,
        productName: product.name.value,
        unitPrice: product.price,
        quantity: parsed.valueOrNull!,
      ),
    );
  }

  return Success<Order>(
    Order(
      id: id,
      buyerId: buyer.id,
      producerId: producerId!,
      lines: lines,
      status: const Pending(),
      createdAt: now,
      method: method,
      address: address,
    ),
  );
}