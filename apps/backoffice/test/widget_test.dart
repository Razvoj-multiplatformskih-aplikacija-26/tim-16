import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svezko_backoffice/data/demo_shop_repository.dart';

// Zamenjuje podrazumevani test brojača iz `flutter create`, koji nije
// odgovarao aplikaciji. Proverava da se demo repozitorijum ponaša kao server.

Order orderOf(Product product, int quantity) => Order(
  id: const OrderId('o-test'),
  buyerId: const UserId('u-buyer-1'),
  producerId: product.producerId,
  lines: [
    OrderLine(
      productId: product.id,
      productName: product.name.value,
      unitPrice: product.price,
      quantity: Quantity.parse(quantity, available: quantity).valueOrNull!,
    ),
  ],
  status: const Pending(),
  createdAt: DateTime.utc(2026, 11, 20),
  method: DeliveryMethod.pickup,
);

Future<Product> cheese(DemoShopRepository repo) async =>
    (await repo.loadProducts()).firstWhere((p) => p.id == const ProductId('p3'));

void main() {
  test('porudžbina veća od zalihe se odbija pravilom, kao na serveru', () async {
    final repo = DemoShopRepository();
    final product = await cheese(repo);

    await expectLater(
      repo.saveOrder(orderOf(product, product.stock.units + 1)),
      throwsA(isA<ActionRejected>()),
    );
  });

  test('porudžbina rezerviše zalihu, a otkazivanje je vraća', () async {
    final repo = DemoShopRepository();
    final product = await cheese(repo);
    final before = product.stock.units;
    final order = orderOf(product, 1);

    await repo.saveOrder(order);
    expect((await cheese(repo)).stock.units, before - 1);

    await repo.saveOrder(order.withStatus(const Cancelled(CancelReason.byBuyer)));
    expect((await cheese(repo)).stock.units, before);
  });
}
