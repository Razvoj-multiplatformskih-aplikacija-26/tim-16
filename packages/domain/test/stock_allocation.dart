import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('reserveStock', () {
    test('skida poručenu količinu sa zalihe', () {
      final products = [makeProduct(stock: 10)];
      final order = makeOrder(lines: [makeLine(quantity: 3)]);
      final updated = reserveStock(order, products).valueOrNull!;
      expect(updated.single.stock.units, 7);
    });

    test('ne dira proizvode koji nisu u porudžbini', () {
      final products = [makeProduct(id: 'p1'), makeProduct(id: 'p2', stock: 4)];
      final order = makeOrder(lines: [makeLine(productId: 'p1', quantity: 3)]);
      final updated = reserveStock(order, products).valueOrNull!;
      expect(updated.last.stock.units, 4);
    });

    test('greška kad nema dovoljno', () {
      final order = makeOrder(lines: [makeLine(quantity: 3)]);
      final r = reserveStock(order, [makeProduct(stock: 2)]);
      final error = r.errorOrNull! as InsufficientStock;
      expect(error.requested, 3);
      expect(error.available, 2);
    });

    test('dve stavke istog proizvoda se sabiraju', () {
      final order = makeOrder(
        lines: [makeLine(quantity: 3), makeLine(quantity: 3)],
      );
      final r = reserveStock(order, [makeProduct(stock: 5)]);
      expect((r.errorOrNull! as InsufficientStock).requested, 6);
    });

    test('nepoznat proizvod', () {
      final order = makeOrder(lines: [makeLine(productId: 'nema')]);
      expect(
        reserveStock(order, [makeProduct()]).errorOrNull,
        isA<ProductNotFound>(),
      );
    });
  });

  group('allocateStock', () {
    test('ostao je jedan komad, dva kupca: prvi dobija', () {
      final products = [makeProduct(stock: 1)];
      final early = makeOrder(
        id: 'o1',
        lines: [makeLine(quantity: 1)],
        createdAt: t0,
      );
      final late = makeOrder(
        id: 'o2',
        by: otherBuyer,
        lines: [makeLine(quantity: 1)],
        createdAt: t0.add(const Duration(minutes: 1)),
      );

      // Namerno obrnut redosled u listi: odlučuje vreme, ne pozicija.
      final decisions = allocateStock(
        products: products,
        orders: [late, early],
      );

      expect(decisions[const OrderId('o1')], isA<CanFulfil>());
      final lost = decisions[const OrderId('o2')]! as CannotFulfil;
      expect(lost.available, 0);
    });

    test('obe prolaze kad ima dovoljno', () {
      final decisions = allocateStock(
        products: [makeProduct(stock: 5)],
        orders: [
          makeOrder(id: 'o1', lines: [makeLine(quantity: 2)]),
          makeOrder(
            id: 'o2',
            lines: [makeLine(quantity: 3)],
            createdAt: t0.add(const Duration(minutes: 1)),
          ),
        ],
      );
      expect(decisions.values.every((d) => d is CanFulfil), isTrue);
    });

    test('porudžbina koja ne staje ne troši zalihu', () {
      final decisions = allocateStock(
        products: [makeProduct(stock: 5)],
        orders: [
          makeOrder(id: 'o1', lines: [makeLine(quantity: 9)]),
          makeOrder(
            id: 'o2',
            lines: [makeLine(quantity: 5)],
            createdAt: t0.add(const Duration(minutes: 1)),
          ),
        ],
      );
      expect(decisions[const OrderId('o1')], isA<CannotFulfil>());
      expect(decisions[const OrderId('o2')], isA<CanFulfil>());
    });

    test('razmatraju se samo porudžbine na čekanju', () {
      final decisions = allocateStock(
        products: [makeProduct()],
        orders: [makeOrder(id: 'o1', status: const Preparing())],
      );
      expect(decisions, isEmpty);
    });
  });
}
