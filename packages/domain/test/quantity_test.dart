import 'package:domain/domain.dart';
import 'package:test/test.dart';
void main() {
  group('Quantity.parse', () {
    test('prihvata količinu između 1 i zalihe', () {
      final r = Quantity.parse(3, available: 5);
      expect(r, isA<Success<Quantity>>());
      expect((r as Success<Quantity>).value.value, 3);
    });

    test('prihvata tačno celu zalihu', () {
      expect(Quantity.parse(5, available: 5), isA<Success<Quantity>>());
    });

    test('odbija nulu', () {
      final r = Quantity.parse(0, available: 5);
      expect((r as Failure<Quantity>).error, isA<QuantityNotPositive>());
    });

    test('odbija negativnu količinu', () {
      final r = Quantity.parse(-2, available: 5);
      expect((r as Failure<Quantity>).error, isA<QuantityNotPositive>());
    });

    test('odbija više nego što ima na zalihi', () {
      final r = Quantity.parse(6, available: 5);
      final error = (r as Failure<Quantity>).error;
      expect(error, isA<QuantityExceedsStock>());
      expect((error as QuantityExceedsStock).available, 5);
    });
  });
}