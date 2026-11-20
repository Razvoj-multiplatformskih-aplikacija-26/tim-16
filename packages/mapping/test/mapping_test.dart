import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';
import 'package:test/test.dart';

JsonMap overWire(JsonMap json) => asObject(jsonDecode(jsonEncode(json)));

final everyError = <DomainError>[
  const QuantityNotPositive(0),
  const QuantityExceedsStock(requested: 3, available: 1),
  const PriceOutOfRange(value: 0, min: 1, max: 100000),
  const StockOutOfRange(units: -5, max: 100000),
  const TextLengthInvalid(kind: TextKind.deliveryAddress, length: 2, min: 5, max: 120),
  TransitionNotAllowed(from: const Delivered(), to: Accepted(acceptedAt: DateTime.utc(2026, 11, 2))),
  const CancellationNotAllowed(Cancelled(CancelReason.byProducer)),
  const NotAuthorized(UserId('')),
  const TooManyActiveOrders(5),
  const MixedProducers(),
  const DuplicateProductInOrder(ProductId('p1')),
  const EmptyOrder(),
  const ProductNotFound(ProductId('p1')),
  const OrderNotFound(OrderId('o-1')),
  const AddressRequired(),
  const InsufficientStock(productId: ProductId('p10'), requested: 1, available: 0),
];

Product honey({bool published = true}) => createProduct(
  id: const ProductId('p2'),
  actor: const User(id: UserId('pr-2'), fullName: 'Gazdinstvo', role: UserRole.producer),
  name: 'Med',
  description: 'Livadski',
  category: ProductCategory.honey,
  unit: ProductUnit.jar,
  priceDinars: 800,
  stockUnits: 5,
).valueOrNull!.copyWith(published: published);

void main() {
  group('greške', () {
    test('svaka domenska greška prolazi kroz mrežu i vraća se ista', () {
      for (final error in everyError) {
        final sent = problemOf(error);
        final received = domainErrorOf(ProblemDto.fromJson(overWire(sent.toJson())));
        expect(received, isNotNull, reason: sent.code);
        expect(problemOf(received!).toJson(), sent.toJson(), reason: sent.code);
      }
    });

    test('greška nosi kôd i podatke pravila, a ne poruku', () {
      final problem = problemOf(const QuantityExceedsStock(requested: 3, available: 1));
      expect(problem.status, 409);
      expect(problem.code, 'quantity_exceeds_stock');
      expect(problem.params, {'requested': 3, 'available': 1});
    });

    test('granica dolazi sa servera: poruka koristi serversku vrednost', () {
      final received = domainErrorOf(ProblemDto.fromJson(overWire(problemOf(const TooManyActiveOrders(3)).toJson())));
      expect(received, isA<TooManyActiveOrders>().having((e) => e.limit, 'limit', 3));
    });

    test('nepoznat kôd (novo pravilo na serveru) daje null, ne izuzetak', () {
      const problem = ProblemDto(status: 422, code: 'quantity_above_line_limit', params: {'limit': 10});
      expect(domainErrorOf(problem), isNull);
    });

    test('poznat kôd sa podacima u drugom obliku daje null, ne izuzetak', () {
      const problem = ProblemDto(status: 409, code: 'quantity_exceeds_stock', params: {'available': 'malo'});
      expect(domainErrorOf(problem), isNull);
    });

    test('tehničke greške nisu pravila', () {
      for (final code in [ErrorCodes.badRequest, ErrorCodes.serverError, ErrorCodes.signInRequired]) {
        expect(domainErrorOf(ProblemDto(status: 400, code: code)), isNull);
      }
    });
  });

  group('proizvod', () {
    test('javni prikaz prolazi kroz mrežu bez polja published', () {
      final dto = productToDto(honey());
      expect(dto.toJson().containsKey('published'), isFalse);
      expect(productFromDto(ProductDto.fromJson(overWire(dto.toJson()))), honey());
    });

    test('prikaz za vlasnika čuva neobjavljen proizvod', () {
      final dto = productToDto(honey(published: false), ownerView: true);
      expect(productFromDto(ProductDto.fromJson(overWire(dto.toJson()))).published, isFalse);
    });

    test('nepoznata kategorija ili cena van pravila ne postaje domenski model', () {
      final json = overWire(productToDto(honey()).toJson())..['category'] = 'mushrooms';
      expect(() => productFromDto(ProductDto.fromJson(json)), throwsA(isA<WireFormatException>()));

      final expensive = overWire(productToDto(honey()).toJson())..['price'] = {'amount': 0, 'currency': 'RSD'};
      expect(() => productFromDto(ProductDto.fromJson(expensive)), throwsA(isA<WireFormatException>()));

      final euro = overWire(productToDto(honey()).toJson())..['price'] = {'amount': 7, 'currency': 'EUR'};
      expect(() => productFromDto(ProductDto.fromJson(euro)), throwsA(isA<WireFormatException>()));
    });
  });

  group('porudžbina', () {
    final order = Order(
      id: const OrderId('o-1'),
      buyerId: const UserId('u-buyer-1'),
      producerId: const UserId('pr-2'),
      lines: [
        OrderLine(
          productId: const ProductId('p2'),
          productName: 'Med',
          unitPrice: Price.parse(800).valueOrNull!,
          quantity: Quantity.parse(2, available: 2).valueOrNull!,
        ),
      ],
      status: Shipped(shippedAt: DateTime.utc(2026, 11, 2, 9)),
      createdAt: DateTime.utc(2026, 11, 1, 8),
      method: DeliveryMethod.delivery,
      address: DeliveryAddress.parse('Knez Mihailova 12').valueOrNull,
    );

    test('prolazi kroz mrežu bez gubitka, sa ukupnim iznosom', () {
      final dto = orderToDto(order);
      expect(dto.total, const MoneyDto(1600));
      expect(orderFromDto(OrderDto.fromJson(overWire(dto.toJson()))), order);
    });

    test('sva stanja prolaze kroz mrežu', () {
      for (final status in <OrderStatus>[
        const Pending(),
        Accepted(acceptedAt: DateTime.utc(2026, 11, 2)),
        const Preparing(),
        Shipped(shippedAt: DateTime.utc(2026, 11, 3)),
        const Delivered(),
        const Cancelled(CancelReason.byBuyer),
        const Cancelled(CancelReason.byProducer),
      ]) {
        expect(statusFromDto(OrderStatusDto.fromJson(overWire(statusToDto(status).toJson()))), status);
      }
    });

    test('nepoznato stanje ne postaje domenski model', () {
      expect(() => statusFromDto(const OrderStatusDto('ready_for_pickup')), throwsA(isA<WireFormatException>()));
    });
  });

  group('zahtevi', () {
    test('vreme prihvatanja postavlja server', () {
      final now = DateTime.utc(2026, 11, 20, 14);
      expect(targetStatusOf(const ChangeStatusRequest('accepted'), now: now), Accepted(acceptedAt: now));
      expect(() => targetStatusOf(const ChangeStatusRequest('cancelled'), now: now), throwsA(isA<FormatException>()));
    });

    test('klijent ne šalje cenu porudžbine, samo šta i koliko', () {
      final request = PlaceOrderRequest(
        lines: const [OrderLineRequest(productId: 'p2', quantity: 2)],
        method: 'pickup',
      );
      expect(request.toJson(), {
        'lines': [
          {'productId': 'p2', 'quantity': 2},
        ],
        'method': 'pickup',
      });
      expect(orderRequestLinesOf(request).single.quantity, 2);
    });
  });
}
