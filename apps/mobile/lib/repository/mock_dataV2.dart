import 'package:blocs/blocs.dart';

class SecondFakeShopRepository implements ShopRepository {
  final List<Product> _alternativeProducts = const [
    Product('p101', 'Lubenica', 'Poljoprivredno dobro Srem', 80, 'kg', 15, 'Slatka domaća lubenica.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Watermelon.jpg?width=500'),
    Product('p102', 'Breskve', 'Voćar Grocka', 200, 'kg', 20, 'Sveže breskve.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Peaches.jpg?width=500'),
    Product('p103', 'Domaći paradajz', 'Gazdinstvo Jovanović', 180, 'kg', 25, 'Jabučar paradajz.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Tomatoes.jpg?width=500'),
  ];

  final List<Order> _mockOrders = [];

  @override
  Future<List<Product>> loadProducts() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _alternativeProducts;
  }

  @override
  Future<List<Order>> loadOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockOrders;
  }

  @override
  Future<Order> createOrder(Product product, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newOrder = Order(
      'o_alt_${DateTime.now().millisecondsSinceEpoch}',
      product,
      quantity,
      OrderState.pending,
    );
    _mockOrders.insert(0, newOrder);
    return newOrder;
  }
}