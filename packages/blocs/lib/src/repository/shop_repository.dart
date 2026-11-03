import 'package:domain/domain.dart';

// Repozitorijum je abstract interface class u zajedničkom paketu
abstract interface class ShopRepository {
  Future<List<User>> loadProducers();
  Future<List<Product>> loadProducts();
  Future<List<Order>> loadOrders();

  /// Čuva novu porudžbinu ili izmenjenu postojeću (isti id).
  Future<void> saveOrder(Order order);
}

/// Optional repository capability used by backoffice clients.
abstract interface class ProductManagementRepository {
  Future<void> deleteProduct(ProductId productId);
  Future<void> addProduct(Product product);
}

