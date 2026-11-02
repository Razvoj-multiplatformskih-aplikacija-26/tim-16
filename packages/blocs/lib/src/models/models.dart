import 'package:equatable/equatable.dart';

enum OrderState { pending, accepted, preparing, shipped, delivered, cancelled }

extension OrderStateExtension on OrderState {
  String get nameSr {
    switch (this) {
      case OrderState.pending: return 'Na čekanju';
      case OrderState.accepted: return 'Prihvaćena';
      case OrderState.preparing: return 'U pripremi';
      case OrderState.shipped: return 'Poslata';
      case OrderState.delivered: return 'Isporučena';
      case OrderState.cancelled: return 'Otkazana';
    }
  }
}

class Product extends Equatable {
  final String id;
  final String name;
  final String producer;
  final double price;
  final String unit;
  final int availableQuantity;
  final String description;
  final String imageUrl;

  const Product(this.id, this.name, this.producer, this.price, this.unit, this.availableQuantity, this.description, this.imageUrl);

  @override
  List<Object?> get props => [id, name, producer, price, unit, availableQuantity, description, imageUrl];
}

class Order extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final OrderState state;

  const Order(this.id, this.product, this.quantity, this.state);

  @override
  List<Object?> get props => [id, product, quantity, state];
}