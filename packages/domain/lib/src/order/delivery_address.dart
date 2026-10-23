
import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../result.dart';
import '../text_rules.dart';

final class DeliveryAddress extends Equatable {
  const DeliveryAddress._(this.value);

  final String value;

  static const int min = 5;
  static const int max = 120;

  static Result<DeliveryAddress> parse(String raw) {
    final result = parseBoundedText(
      raw,
      kind: TextKind.deliveryAddress,
      min: min,
      max: max,
    );
    final error = result.errorOrNull;
    if (error != null) return Failure<DeliveryAddress>(error);
    return Success<DeliveryAddress>(DeliveryAddress._(result.valueOrNull!));
  }

  @override
  List<Object?> get props => [value];
}
