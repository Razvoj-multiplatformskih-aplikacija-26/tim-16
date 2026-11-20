import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:test/test.dart';

JsonMap overWire(JsonMap json) => asObject(jsonDecode(jsonEncode(json)));

void main() {
  group('novac', () {
    test('iznos je ceo broj, valuta je uvek navedena', () {
      expect(const MoneyDto(150).toJson(), {'amount': 150, 'currency': 'RSD'});
      expect(MoneyDto.fromJson(overWire(const MoneyDto(150).toJson())), const MoneyDto(150));
    });

    test('decimalni iznos se odbija', () {
      expect(() => MoneyDto.fromJson({'amount': 150.5, 'currency': 'RSD'}), throwsA(isA<WireFormatException>()));
    });
  });

  group('vreme', () {
    test('šalje se u UTC sa Z', () {
      expect(encodeTime(DateTime.utc(2026, 11, 2, 12)), '2026-11-02T12:00:00.000Z');
    });

    test('zona se poštuje, a vreme bez zone odbija', () {
      expect(decodeTime('2026-11-02T13:00:00+01:00'), DateTime.utc(2026, 11, 2, 12));
      expect(() => decodeTime('2026-11-02T13:00:00'), throwsA(isA<WireFormatException>()));
    });
  });

  group('porudžbina', () {
    final order = OrderDto(
      id: 'o-1',
      buyerId: 'u-1',
      producerId: 'pr-1',
      status: OrderStatusDto(OrderStatusDto.accepted, at: DateTime.utc(2026, 11, 2, 12)),
      method: 'delivery',
      address: 'Knez Mihailova 12',
      createdAt: DateTime.utc(2026, 11, 2, 11),
      lines: const [
        OrderLineDto(productId: 'p1', productName: 'Med', unitPrice: MoneyDto(800), quantity: 2),
      ],
      total: const MoneyDto(1600),
    );

    test('prolazi kroz mrežu bez gubitka', () {
      final back = OrderDto.fromJson(overWire(order.toJson()));
      expect(back.toJson(), order.toJson());
    });

    test('nepoznato stanje i nepoznata polja se čitaju bez greške', () {
      final json = overWire(order.toJson())
        ..['status'] = {'code': 'ready_for_pickup', 'shelf': 'B3'}
        ..['loyaltyPoints'] = 12;
      final back = OrderDto.fromJson(json);
      expect(back.status.code, 'ready_for_pickup');
    });
  });

  group('proizvod', () {
    test('javni prikaz nema polje published, prikaz za vlasnika ga ima', () {
      const public = ProductDto(
        id: 'p1',
        producerId: 'pr-1',
        name: 'Med',
        description: '',
        category: 'honey',
        unit: 'jar',
        price: MoneyDto(800),
        availableUnits: 5,
        imageUrl: '',
      );
      expect(public.toJson().containsKey('published'), isFalse);

      const own = ProductDto(
        id: 'p1',
        producerId: 'pr-1',
        name: 'Med',
        description: '',
        category: 'honey',
        unit: 'jar',
        price: MoneyDto(800),
        availableUnits: 5,
        imageUrl: '',
        published: false,
      );
      expect(ProductDto.fromJson(overWire(own.toJson())).published, isFalse);
    });
  });

  group('greška', () {
    test('nosi kôd i podatke pravila', () {
      const problem = ProblemDto(
        status: 409,
        code: ErrorCodes.quantityExceedsStock,
        params: {'requested': 3, 'available': 1},
        title: 'quantity_exceeds_stock',
      );
      final back = ProblemDto.fromJson(overWire(problem.toJson()));
      expect(back.code, ErrorCodes.quantityExceedsStock);
      expect(back.params, {'requested': 3, 'available': 1});
    });

    test('greška bez podataka pravila ima prazne params', () {
      expect(ProblemDto.fromJson({'status': 403, 'code': 'not_authorized'}).params, isEmpty);
    });
  });

  group('straničenje', () {
    test('podrazumevana i najveća veličina strane', () {
      expect(PageRequest.fromQuery(const {}).limit, PageRequest.defaultLimit);
      expect(() => PageRequest.fromQuery(const {'limit': '0'}), throwsA(isA<WireFormatException>()));
      expect(() => PageRequest.fromQuery(const {'limit': '1000'}), throwsA(isA<WireFormatException>()));
      expect(() => PageRequest.fromQuery(const {'limit': 'pet'}), throwsA(isA<WireFormatException>()));
    });

    test('strana nosi kursor do sledeće, poslednja nema kursor', () {
      const page = PageDto(items: [ProducerDto(id: 'pr-1', fullName: 'Bojan')], nextCursor: 'abc');
      final back = PageDto.fromJson(overWire(page.toJson((item) => item.toJson())), ProducerDto.fromJson);
      expect(back.items.single.fullName, 'Bojan');
      expect(back.nextCursor, 'abc');
      expect(PageDto.fromJson({'items': <Object?>[], 'nextCursor': null}, ProducerDto.fromJson).isLast, isTrue);
    });
  });
}
