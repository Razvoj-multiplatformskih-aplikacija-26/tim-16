import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

import 'codes.dart';
import 'products.dart';

OrderDto orderToDto(Order order) => OrderDto(
  id: order.id.value,
  buyerId: order.buyerId.value,
  producerId: order.producerId.value,
  status: statusToDto(order.status),
  method: methodCode(order.method),
  address: order.address?.value,
  createdAt: order.createdAt,
  lines: [
    for (final line in order.lines)
      OrderLineDto(
        productId: line.productId.value,
        productName: line.productName,
        unitPrice: moneyOf(line.unitPrice.dinars),
        quantity: line.quantity.value,
      ),
  ],
  total: moneyOf(order.total),
);

Order orderFromDto(OrderDto dto) => Order(
  id: OrderId(dto.id),
  buyerId: UserId(dto.buyerId),
  producerId: UserId(dto.producerId),
  status: statusFromDto(dto.status),
  method: methodFromCode(dto.method),
  address: switch (dto.address) {
    null => null,
    final text => switch (DeliveryAddress.parse(text)) {
      Success(:final value) => value,
      Failure() => throw const WireFormatException('Adresa isporuke krši pravilo'),
    },
  },
  createdAt: dto.createdAt,
  lines: [
    for (final line in dto.lines)
      OrderLine(
        productId: ProductId(line.productId),
        productName: line.productName,
        unitPrice: switch (Price.parse(dinarsOf(line.unitPrice))) {
          Success(:final value) => value,
          Failure() => throw const WireFormatException('Cena stavke krši pravilo'),
        },
        quantity: switch (Quantity.parse(line.quantity, available: line.quantity)) {
          Success(:final value) => value,
          Failure() => throw const WireFormatException('Količina stavke mora biti bar 1'),
        },
      ),
  ],
);
