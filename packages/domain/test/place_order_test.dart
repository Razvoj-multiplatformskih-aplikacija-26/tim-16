import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Result<Order> place({
  User who = buyer,
  List<OrderRequestLine>? request,
  List<Product>? catalog,
  List<Order> existing = const [],
  DeliveryMethod method = DeliveryMethod.pickup,
  DeliveryAddress? address,
}) =>
    placeOrder(
      id: const OrderId('new-1'),
      buyer: who,
      request: request ??
          [const OrderRequestLine(productId: ProductId('p1'), quantity: 2)],
      catalog: catalog ?? [makeProduct()],
      existingOrders: existing,
      method: method,
      address: address,
      now: t0,
    );

void main() {
  group('placeOrder', () {
    test('uspeh: stanje Pending, snimak cene, ukupno', () {
      final order = place().valueOrNull!;
      expect(order.status, const Pending());
      expect(order.producerId, producer.id);
      expect(order.lines.single.unitPrice.dinars, 200);
      expect(order.total, 400);
      expect(order.createdAt, t0);
    });

    test('proizvođač ne može da poruči', () {
      expect(place(who: producer).errorOrNull, isA<NotAuthorized>());
    });

    test('prazna korpa', () {
      expect(place(request: []).errorOrNull, isA<EmptyOrder>());
    });

    test('dostava traži adresu', () {
      expect(
        place(method: DeliveryMethod.delivery).errorOrNull,
        isA<AddressRequired>(),
      );
      final address =
          DeliveryAddress.parse('Knez Mihailova 5, Beograd').valueOrNull;
      expect(
        place(method: DeliveryMethod.delivery, address: address).isSuccess,
        isTrue,
      );
    });

    test('količina veća od zalihe', () {
      final r = place(
        request: [
          const OrderRequestLine(productId: ProductId('p1'), quantity: 11),
        ],
      );
      expect(r.errorOrNull, isA<QuantityExceedsStock>());
    });

    test('nepoznat ili neobjavljen proizvod', () {
      expect(
        place(
          request: [
            const OrderRequestLine(productId: ProductId('nema'), quantity: 1),
          ],
        ).errorOrNull,
        isA<ProductNotFound>(),
      );
      expect(
        place(catalog: [makeProduct(published: false)]).errorOrNull,
        isA<ProductNotFound>(),
      );
    });

    test('proizvodi različitih proizvođača u jednoj porudžbini', () {
      final r = place(
        catalog: [
          makeProduct(id: 'p1'),
          makeProduct(id: 'p2', owner: otherProducer),
        ],
        request: [
          const OrderRequestLine(productId: ProductId('p1'), quantity: 1),
          const OrderRequestLine(productId: ProductId('p2'), quantity: 1),
        ],
      );
      expect(r.errorOrNull, isA<MixedProducers>());
    });

    test('isti proizvod dva puta', () {
      final r = place(
        request: [
          const OrderRequestLine(productId: ProductId('p1'), quantity: 1),
          const OrderRequestLine(productId: ProductId('p1'), quantity: 1),
        ],
      );
      expect(r.errorOrNull, isA<DuplicateProductInOrder>());
    });

    test('limit aktivnih porudžbina; završene se ne računaju', () {
      final five = List.generate(maxActiveOrders, (i) => makeOrder(id: 'o$i'));
      expect(place(existing: five).errorOrNull, isA<TooManyActiveOrders>());

      final fourPlusDelivered = [
        ...List.generate(maxActiveOrders - 1, (i) => makeOrder(id: 'o$i')),
        makeOrder(id: 'done', status: const Delivered()),
      ];
      expect(place(existing: fourPlusDelivered).isSuccess, isTrue);
    });

    test('tuđe porudžbine se ne računaju u limit', () {
      final others = List.generate(
        maxActiveOrders,
            (i) => makeOrder(id: 'o$i', by: otherBuyer),
      );
      expect(place(existing: others).isSuccess, isTrue);
    });
  });
}
