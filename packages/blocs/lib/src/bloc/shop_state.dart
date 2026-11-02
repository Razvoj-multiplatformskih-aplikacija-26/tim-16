import 'package:equatable/equatable.dart';
import '../models/models.dart';

sealed class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

final class ShopLoading extends ShopState {}

final class ShopEmpty extends ShopState {}

final class ShopError extends ShopState {
  final String message;

  const ShopError(this.message);

  @override
  List<Object?> get props => [message];
}

final class ShopLoaded extends ShopState {
  final List<Product> products;
  final List<Order> orders;

  const ShopLoaded({
    required this.products,
    required this.orders,
  });

  @override
  List<Object?> get props => [products, orders];
}