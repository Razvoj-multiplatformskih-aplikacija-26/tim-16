
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'mock_data.dart' show makeProduct;

class SecondFakeShopRepository implements ShopRepository{

  SecondFakeShopRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  static const _srem = User(
    id: UserId('pr-101'),
    fullName: 'Poljoprivredno dobro Srem',
    role: UserRole.producer,
  );
  static const _grocka = User(
    id: UserId('pr-102'),
    fullName: 'Voćar Grocka',
    role: UserRole.producer,
  );
  static const _jovanovic = User(
    id: UserId('pr-103'),
    fullName: 'Gazdinstvo Jovanović',
    role: UserRole.producer,
  );

  final List<Product> _products = [
    makeProduct(
      id: 'p101',
      producer: _srem,
      name: 'Lubenica',
      description: 'Slatka domaća lubenica.',
      category: ProductCategory.fruit,
      unit: ProductUnit.kilogram,
      priceDinars: 80,
      stockUnits: 15,
      imageUrl:
      'https://commons.wikimedia.org/wiki/Special:FilePath/Watermelon.jpg?width=500',
    ),
    makeProduct(
      id: 'p102',
      producer: _grocka,
      name: 'Breskve',
      description: 'Sveže breskve.',
      category: ProductCategory.fruit,
      unit: ProductUnit.kilogram,
      priceDinars: 200,
      stockUnits: 20,
      imageUrl:
      'https://commons.wikimedia.org/wiki/Special:FilePath/Peaches.jpg?width=500',
    ),
    makeProduct(
      id: 'p103',
      producer: _jovanovic,
      name: 'Domaći paradajz',
      description: 'Jabučar paradajz.',
      category: ProductCategory.vegetables,
      unit: ProductUnit.kilogram,
      priceDinars: 180,
      stockUnits: 25,
      imageUrl:
      'https://commons.wikimedia.org/wiki/Special:FilePath/Tomatoes.jpg?width=500',
    ),
  ];

  final List<Order> _orders = [];

  @override
  Future<List<User>> loadProducers() async {
    await Future<void>.delayed(latency ~/ 4);
    return const [_srem, _grocka, _jovanovic];
  }

  @override
  Future<List<Product>> loadProducts() async {
    await Future<void>.delayed(latency);
    return List.of(_products);
  }

  @override
  Future<List<Order>> loadOrders() async {
    await Future<void>.delayed(latency ~/ 2);
    return List.of(_orders);
  }

  @override
  Future<void> saveOrder(Order order) async {
    await Future<void>.delayed(latency ~/ 2);
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index == -1) {
      _orders.insert(0, order);
    } else {
      _orders[index] = order;
    }
  }
}