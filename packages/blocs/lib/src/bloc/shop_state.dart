import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

/// Jednokratna poruka za ekran posle akcije (ekran je pokaže i zaboravi).
sealed class ShopFeedback extends Equatable {
  const ShopFeedback();
}

final class OrderPlaced extends ShopFeedback {
  const OrderPlaced(this.order);
  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrderCancelled extends ShopFeedback {
  const OrderCancelled(this.order);
  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrderStatusChanged extends ShopFeedback {
  const OrderStatusChanged(this.order);
  final Order order;

  @override
  List<Object?> get props => [order];
}

final class ProductDeleted extends ShopFeedback {
  const ProductDeleted(this.productId);
  final ProductId productId;

  @override
  List<Object?> get props => [productId];
}

final class ProductAdded extends ShopFeedback {
  const ProductAdded(this.product);
  final Product product;

  @override
  List<Object?> get props => [product];
}

/// Domensko pravilo je odbilo akciju. Tekst poruke bira aplikacija.
final class RuleViolated extends ShopFeedback {
  const RuleViolated(this.error);
  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// Pravila su prošla, ali repozitorijum nije uspeo da sačuva (mreža...).
final class ActionFailed extends ShopFeedback {
  const ActionFailed();

  @override
  List<Object?> get props => [];
}

sealed class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

final class ShopLoading extends ShopState {
  const ShopLoading();
}

final class ShopEmpty extends ShopState {
  const ShopEmpty();
}

final class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class ShopLoaded extends ShopState {
  const ShopLoaded({
    required this.products,
    required this.orders,
    required this.producers,
    this.feedback,
  });

  final List<Product> products;
  final List<Order> orders;
  final Map<UserId, User> producers;
  final ShopFeedback? feedback;

  String producerName(UserId id) =>
      producers[id]?.fullName ?? 'Nepoznat proizvođač';

  /// Pažnja: ako se `feedback` ne prosledi, on se BRIŠE (namerno).
  ShopLoaded copyWith({List<Product>? products, List<Order>? orders, ShopFeedback? feedback}) =>
      ShopLoaded(
        products: products ?? this.products,
        orders: orders ?? this.orders,
        producers: producers,
        feedback: feedback,
      );

  @override
  List<Object?> get props => [products, orders, producers, feedback];
}
