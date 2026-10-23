import '../errors.dart';
import '../result.dart';

final class Quantity {
  const Quantity._(this.value);

  final int value;

  static Result<Quantity> parse(int value, {required int available}) {
    if (value < 1) {
      return Failure<Quantity>(QuantityNotPositive(value));
    }

    if (value > available) {
      return Failure<Quantity>(
        QuantityExceedsStock(
          requested: value,
          available: available,
        ),
      );
    }

    return Success<Quantity>(Quantity._(value));
  }

  @override
  bool operator ==(Object other) =>
      other is Quantity && other.value == value;

  @override
  int get hashCode => value.hashCode;
}