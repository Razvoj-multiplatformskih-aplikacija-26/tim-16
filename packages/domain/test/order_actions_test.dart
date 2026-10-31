import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
void main() {
  group('canViewOrder', () {
    test('vide je samo kupac i proizvođač te porudžbine', () {
      final order = makeOrder();
      expect(canViewOrder(buyer, order), isTrue);
      expect(canViewOrder(producer, order), isTrue);
      expect(canViewOrder(otherBuyer, order), isFalse);
      expect(canViewOrder(otherProducer, order), isFalse);
    });
  });

  group('cancelOrder', () {
    test('kupac otkazuje svoju porudžbinu na čekanju', () {
      final order = cancelOrder(makeOrder(), actor: buyer).valueOrNull!;
      expect(order.status, const Cancelled(CancelReason.byBuyer));
    });

    test('proizvođač otkazuje sa razlogom byProducer', () {
      final order = cancelOrder(makeOrder(), actor: producer).valueOrNull!;
      expect(order.status, const Cancelled(CancelReason.byProducer));
    });

    test('ne može u pripremi', () {
      final r = cancelOrder(makeOrder(status: const Preparing()), actor: buyer);
      expect(r.errorOrNull, isA<CancellationNotAllowed>());
    });

    test('tuđu porudžbinu ne može niko da otkaže', () {
      expect(
        cancelOrder(makeOrder(), actor: otherBuyer).errorOrNull,
        isA<NotAuthorized>(),
      );
      expect(
        cancelOrder(makeOrder(), actor: otherProducer).errorOrNull,
        isA<NotAuthorized>(),
      );
    });
  });

  group('changeOrderStatus', () {
    test('proizvođač prihvata, priprema, šalje i isporučuje', () {
      var order = makeOrder();
      for (final next in <OrderStatus>[
        Accepted(acceptedAt: t0),
        const Preparing(),
        Shipped(shippedAt: t0),
        const Delivered(),
      ]) {
        order = changeOrderStatus(order, next, actor: producer).valueOrNull!;
        expect(order.status, next);
      }
    });

    test('kupac ne može da prihvati svoju porudžbinu', () {
      final r = changeOrderStatus(
        makeOrder(),
        Accepted(acceptedAt: t0),
        actor: buyer,
      );
      expect(r.errorOrNull, isA<NotAuthorized>());
    });

    test('proizvođač ne može da otkaže u ime kupca', () {
      final r = changeOrderStatus(
        makeOrder(),
        const Cancelled(CancelReason.byBuyer),
        actor: producer,
      );
      expect(r.errorOrNull, isA<NotAuthorized>());
    });

    test('proizvođač ne menja porudžbine drugog proizvođača', () {
      final r = changeOrderStatus(
        makeOrder(),
        Accepted(acceptedAt: t0),
        actor: otherProducer,
      );
      expect(r.errorOrNull, isA<NotAuthorized>());
    });

    test('nedozvoljen prelaz: Pending -> Shipped', () {
      final r = changeOrderStatus(
        makeOrder(),
        Shipped(shippedAt: t0),
        actor: producer,
      );
      expect(r.errorOrNull, isA<TransitionNotAllowed>());
    });

    test('završena porudžbina se ne menja', () {
      final r = changeOrderStatus(
        makeOrder(status: const Delivered()),
        const Preparing(),
        actor: producer,
      );
      expect(r.errorOrNull, isA<TransitionNotAllowed>());
    });
  });

  group('isActive / isFinal', () {
    test('Delivered i Cancelled su završena stanja', () {
      expect(isFinal(const Delivered()), isTrue);
      expect(isFinal(const Cancelled(CancelReason.byBuyer)), isTrue);
      expect(isActive(const Pending()), isTrue);
      expect(isActive(const Preparing()), isTrue);
    });
  });
}
