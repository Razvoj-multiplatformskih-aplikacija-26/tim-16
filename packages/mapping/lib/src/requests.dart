import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

import 'codes.dart';
import 'products.dart';

PlaceOrderRequest placeOrderRequestOf(Order order) => PlaceOrderRequest(
  lines: [
    for (final line in order.lines)
      OrderLineRequest(productId: line.productId.value, quantity: line.quantity.value),
  ],
  method: methodCode(order.method),
  address: order.address?.value,
);

List<OrderRequestLine> orderRequestLinesOf(PlaceOrderRequest request) => [
  for (final line in request.lines)
    OrderRequestLine(productId: ProductId(line.productId), quantity: line.quantity),
];

ChangeStatusRequest changeStatusRequestOf(OrderStatus target) =>
    ChangeStatusRequest(statusToDto(target).code);

OrderStatus targetStatusOf(ChangeStatusRequest request, {required DateTime now}) =>
    switch (request.status) {
      OrderStatusDto.accepted => Accepted(acceptedAt: now),
      OrderStatusDto.preparing => const Preparing(),
      OrderStatusDto.shipped => Shipped(shippedAt: now),
      OrderStatusDto.delivered => const Delivered(),
      final other => throw WireFormatException(
        'Stanje "$other" ne postoji ili se ne menja ovom rutom '
        '(otkazivanje: /orders/:id/cancellation)',
      ),
    };

CreateProductRequest createProductRequestOf(Product product) => CreateProductRequest(
  name: product.name.value,
  description: product.description,
  category: categoryCode(product.category),
  unit: unitCode(product.unit),
  price: moneyOf(product.price.dinars),
  stockUnits: product.stock.units,
);
