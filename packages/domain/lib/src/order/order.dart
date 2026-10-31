import 'package:domain/src/order/quantity.dart';
import 'package:equatable/equatable.dart';

import '../identifiers.dart';
import '../product/price.dart';
import 'delivery_address.dart';
import 'order_status.dart';

final class OrderLine extends Equatable{
  const OrderLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
});
  final ProductId productId;
  final String productName;
  final Price unitPrice;
  final Quantity quantity;

  int get total => unitPrice.dinars*quantity.value;

  @override
  // TODO: implement props
  List<Object?> get props => [productId,productName,unitPrice,quantity];

}

enum DeliveryMethod {pickup,delivery}

final class Order extends Equatable{
  Order({
    required this.id,
    required this.buyerId,
    required this.producerId,
    required List<OrderLine>lines,
    required this.status,
    required this.createdAt,
    required this.method,
    this.address,
}): lines=List.unmodifiable(lines);

  final OrderId id;
  final UserId buyerId;
  final UserId producerId;
  final List<OrderLine> lines;
  final OrderStatus status;
  final DateTime createdAt;
  final DeliveryMethod method;
  final DeliveryAddress? address;

  int get total => lines.fold(0, (sum, line) => sum + line.total);

  Order withStatus(OrderStatus newStatus)=>Order(
    id:id,
    buyerId: buyerId,
    producerId: producerId,
    lines: lines,
    status: newStatus,
    createdAt: createdAt,
    method: method,
    address: address,
  );

  @override
  // TODO: implement props
  List<Object?> get props => [
    id,
    buyerId,
    producerId,
    lines,
    status,
    createdAt,
    method,
    address,
  ];
}