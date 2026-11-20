import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

String categoryCode(ProductCategory category) => switch (category) {
  ProductCategory.fruit => 'fruit',
  ProductCategory.vegetables => 'vegetables',
  ProductCategory.dairy => 'dairy',
  ProductCategory.honey => 'honey',
  ProductCategory.preserves => 'preserves',
};

ProductCategory categoryFromCode(String code) => switch (code) {
  'fruit' => ProductCategory.fruit,
  'vegetables' => ProductCategory.vegetables,
  'dairy' => ProductCategory.dairy,
  'honey' => ProductCategory.honey,
  'preserves' => ProductCategory.preserves,
  _ => throw WireFormatException('Nepoznata kategorija "$code"'),
};

String unitCode(ProductUnit unit) => switch (unit) {
  ProductUnit.kilogram => 'kilogram',
  ProductUnit.piece => 'piece',
  ProductUnit.liter => 'liter',
  ProductUnit.jar => 'jar',
};

ProductUnit unitFromCode(String code) => switch (code) {
  'kilogram' => ProductUnit.kilogram,
  'piece' => ProductUnit.piece,
  'liter' => ProductUnit.liter,
  'jar' => ProductUnit.jar,
  _ => throw WireFormatException('Nepoznata jedinica "$code"'),
};

String methodCode(DeliveryMethod method) => switch (method) {
  DeliveryMethod.pickup => 'pickup',
  DeliveryMethod.delivery => 'delivery',
};

DeliveryMethod methodFromCode(String code) => switch (code) {
  'pickup' => DeliveryMethod.pickup,
  'delivery' => DeliveryMethod.delivery,
  _ => throw WireFormatException('Nepoznat način preuzimanja "$code"'),
};

String textKindCode(TextKind kind) => switch (kind) {
  TextKind.productName => 'product_name',
  TextKind.deliveryAddress => 'delivery_address',
};

TextKind textKindFromCode(String code) => switch (code) {
  'product_name' => TextKind.productName,
  'delivery_address' => TextKind.deliveryAddress,
  _ => throw WireFormatException('Nepoznato tekstualno polje "$code"'),
};

OrderStatusDto statusToDto(OrderStatus status) => switch (status) {
  Pending() => const OrderStatusDto(OrderStatusDto.pending),
  Accepted(:final acceptedAt) => OrderStatusDto(OrderStatusDto.accepted, at: acceptedAt),
  Preparing() => const OrderStatusDto(OrderStatusDto.preparing),
  Shipped(:final shippedAt) => OrderStatusDto(OrderStatusDto.shipped, at: shippedAt),
  Delivered() => const OrderStatusDto(OrderStatusDto.delivered),
  Cancelled(:final reason) => OrderStatusDto(
    OrderStatusDto.cancelled,
    cancelledBy: switch (reason) {
      CancelReason.byBuyer => OrderStatusDto.byBuyer,
      CancelReason.byProducer => OrderStatusDto.byProducer,
    },
  ),
};

OrderStatus statusFromDto(OrderStatusDto dto) => switch (dto.code) {
  OrderStatusDto.pending => const Pending(),
  OrderStatusDto.accepted => Accepted(acceptedAt: _requireTime(dto)),
  OrderStatusDto.preparing => const Preparing(),
  OrderStatusDto.shipped => Shipped(shippedAt: _requireTime(dto)),
  OrderStatusDto.delivered => const Delivered(),
  OrderStatusDto.cancelled => Cancelled(switch (dto.cancelledBy) {
    OrderStatusDto.byBuyer => CancelReason.byBuyer,
    OrderStatusDto.byProducer => CancelReason.byProducer,
    final other => throw WireFormatException('Nepoznato ko je otkazao: "$other"'),
  }),
  final other => throw WireFormatException('Nepoznato stanje porudžbine "$other"'),
};

DateTime _requireTime(OrderStatusDto dto) =>
    dto.at ?? (throw WireFormatException('Stanje "${dto.code}" mora imati vreme'));
