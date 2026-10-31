import 'package:domain/domain.dart';
import 'package:test/test.dart';

final _t = DateTime.utc(2026, 10, 22);

final List<OrderStatus> _all = [
  const Pending(),
  Accepted(acceptedAt: _t),
  const Preparing(),
  Shipped(shippedAt: _t),
  const Delivered(),
  const Cancelled(CancelReason.byBuyer),
];

/// Jedini dozvoljeni prelazi (po imenu tipa). Sve ostalo mora biti false.
const _allowed = {
  'Pending->Accepted',
  'Pending->Cancelled',
  'Accepted->Preparing',
  'Accepted->Cancelled',
  'Preparing->Shipped',
  'Shipped->Delivered',
};

void main() {
  group('canTransition', () {
    test('tačno dozvoljeni prelazi su true, svi ostali false', () {
      for (final from in _all) {
        for (final to in _all) {
          final key = '${from.runtimeType}->${to.runtimeType}';
          expect(
            canTransition(from, to),
            _allowed.contains(key),
            reason: key,
          );
        }
      }
    });
  });

  group('transition', () {
    test('vraća novo stanje kad je prelaz dozvoljen', () {
      final r = transition(const Pending(), Accepted(acceptedAt: _t));
      expect((r as Success<OrderStatus>).value, isA<Accepted>());
    });

    test('vraća grešku kad prelaz nije dozvoljen', () {
      final r = transition(const Delivered(), const Pending());
      expect((r as Failure<OrderStatus>).error, isA<TransitionNotAllowed>());
    });
  });

  group('cancel', () {
    test('može iz Pending', () {
      final r = cancel(const Pending(), reason: CancelReason.byBuyer);
      final status = (r as Success<OrderStatus>).value;
      expect((status as Cancelled).reason, CancelReason.byBuyer);
    });

    test('može iz Accepted', () {
      expect(canCancel(Accepted(acceptedAt: _t)), isTrue);
    });

    test('ne može iz Preparing', () {
      final r = cancel(const Preparing(), reason: CancelReason.byBuyer);
      expect((r as Failure<OrderStatus>).error, isA<CancellationNotAllowed>());
    });

    test('ne može iz Delivered niti iz Cancelled', () {
      expect(canCancel(const Delivered()), isFalse);
      expect(canCancel(const Cancelled(CancelReason.byProducer)), isFalse);
    });
  });
}
