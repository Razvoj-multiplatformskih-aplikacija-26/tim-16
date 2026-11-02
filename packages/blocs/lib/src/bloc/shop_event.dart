import 'package:equatable/equatable.dart';
import '../models/models.dart';

sealed class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

final class LoadShopDataEvent extends ShopEvent {}

final class CreateOrderEvent extends ShopEvent {
  final Product product;
  final int quantity;

  const CreateOrderEvent(this.product, this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}
final class CancelOrderEvent extends ShopEvent {
  final Order order;
  const CancelOrderEvent(this.order);
  @override
  List<Object?> get props => [order];
}