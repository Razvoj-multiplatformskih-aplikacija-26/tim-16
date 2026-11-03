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