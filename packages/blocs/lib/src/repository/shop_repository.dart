import 'package:domain/domain.dart';

// Repozitorijum je abstract interface class u zajedničkom paketu
abstract interface class ShopRepository {
  Future<List<User>> loadProducers();
  Future<List<Product>> loadProducts();
  Future<List<Order>> loadOrders();

  /// Čuva novu porudžbinu ili izmenjenu postojeću (isti id).
  Future<Order> saveOrder(Order order);
}

/// Optional repository capability used by backoffice clients.
abstract interface class ProductManagementRepository {
  Future<void> deleteProduct(ProductId productId);

  Future<Product> addProduct(Product product);
}

/// Repozitorijum baca kada server odbije akciju domenskim pravilom.
///
/// Klijent je pravilo već proverio nad svojim podacima, pa odbijanje znači
/// da su ti podaci zastareli: npr. drugi kupac je u međuvremenu uzeo poslednji
/// komad. Za razliku od mrežne greške, ovde postoji razlog za korisnika.
final class ActionRejected implements Exception {
  const ActionRejected(this.error);

  final DomainError error;

  @override
  String toString() => 'ActionRejected($error)';
}

final class ActionRefused implements Exception {
  const ActionRefused(this.code, {this.params = const {}});

  final String code;
  final Map<String, Object?> params;

  @override
  String toString() => 'ActionRefused($code, $params)';
}

final class RepositoryUnavailable implements Exception {
  const RepositoryUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'RepositoryUnavailable($reason)';
}


final class SessionEnded implements Exception {
  const SessionEnded();

  @override
  String toString() => 'SessionEnded';
}
