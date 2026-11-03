import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

sealed class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

final class LoadShopDataEvent extends ShopEvent {
  const LoadShopDataEvent();
}

final class CreateOrderEvent extends ShopEvent {
  const CreateOrderEvent(
  {
    required this.productId,
    required this.quantity,
    this.method = DeliveryMethod.pickup,
    this.address,
  });

  final ProductId productId;
  final int quantity;
  final DeliveryMethod method;
  final DeliveryAddress? address;



  @override
  List<Object?> get props => [productId, quantity, method, address];
}
final class CancelOrderEvent extends ShopEvent {
  const CancelOrderEvent(this.orderId);

  final OrderId orderId;

  @override
  List<Object?> get props => [orderId];
}

final class ChangeOrderStatusEvent extends ShopEvent {
  const ChangeOrderStatusEvent({required this.orderId, required this.status});
  final OrderId orderId;
  final OrderStatus status;

  @override
  List<Object?> get props => [orderId, status];
}

final class DeleteProductEvent extends ShopEvent {
  const DeleteProductEvent(this.productId);
  final ProductId productId;

  @override
  List<Object?> get props => [productId];
}

final class AddProductEvent extends ShopEvent {
  const AddProductEvent({
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.priceDinars,
    required this.stockUnits,
  });

  final String name;
  final String description;
  final ProductCategory category;
  final ProductUnit unit;
  final int priceDinars;
  final int stockUnits;

  @override
  List<Object?> get props => [name, description, category, unit, priceDinars, stockUnits];
}
