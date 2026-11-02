import '../models/models.dart';

// Repozitorijum je abstract interface class u zajedničkom paketu
abstract interface class ShopRepository {
  Future<List<Product>> loadProducts();
  Future<List<Order>> loadOrders();
  Future<Order> createOrder(Product product, int quantity);
}