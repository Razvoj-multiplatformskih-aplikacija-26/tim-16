import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

import 'codes.dart';

ProblemDto problemOf(DomainError error) {
  final (int status, String code, JsonMap params) = switch (error) {
    QuantityNotPositive(:final requested) => (
      422,
      ErrorCodes.quantityNotPositive,
      {'requested': requested},
    ),
    QuantityExceedsStock(:final requested, :final available) => (
      409,
      ErrorCodes.quantityExceedsStock,
      {'requested': requested, 'available': available},
    ),
    PriceOutOfRange(:final value, :final min, :final max) => (
      422,
      ErrorCodes.priceOutOfRange,
      {'value': moneyJson(value), 'min': moneyJson(min), 'max': moneyJson(max)},
    ),
    StockOutOfRange(:final units, :final max) => (
      422,
      ErrorCodes.stockOutOfRange,
      {'units': units, 'max': max},
    ),
    TextLengthInvalid(:final kind, :final length, :final min, :final max) => (
      422,
      ErrorCodes.textLengthInvalid,
      {'field': textKindCode(kind), 'length': length, 'min': min, 'max': max},
    ),
    TransitionNotAllowed(:final from, :final to) => (
      409,
      ErrorCodes.transitionNotAllowed,
      {'from': statusToDto(from).toJson(), 'to': statusToDto(to).toJson()},
    ),
    CancellationNotAllowed(:final status) => (
      409,
      ErrorCodes.cancellationNotAllowed,
      {'status': statusToDto(status).toJson()},
    ),
    NotAuthorized() => (403, ErrorCodes.notAuthorized, const <String, Object?>{}),
    TooManyActiveOrders(:final limit) => (
      409,
      ErrorCodes.tooManyActiveOrders,
      {'limit': limit},
    ),
    MixedProducers() => (422, ErrorCodes.mixedProducers, const <String, Object?>{}),
    DuplicateProductInOrder(:final productId) => (
      422,
      ErrorCodes.duplicateProductInOrder,
      {'productId': productId.value},
    ),
    EmptyOrder() => (422, ErrorCodes.emptyOrder, const <String, Object?>{}),
    ProductNotFound(:final productId) => (
      404,
      ErrorCodes.productNotFound,
      {'productId': productId.value},
    ),
    OrderNotFound(:final orderId) => (
      404,
      ErrorCodes.orderNotFound,
      {'orderId': orderId.value},
    ),
    AddressRequired() => (422, ErrorCodes.addressRequired, const <String, Object?>{}),
    InsufficientStock(:final productId, :final requested, :final available) => (
      409,
      ErrorCodes.insufficientStock,
      {'productId': productId.value, 'requested': requested, 'available': available},
    ),
  };
  return ProblemDto(status: status, code: code, params: params, title: code);
}

DomainError? domainErrorOf(ProblemDto problem) {
  try {
    return _domainError(problem.code, problem.params);
  } on FormatException {
    return null;
  }
}

DomainError? _domainError(String code, JsonMap p) => switch (code) {
  ErrorCodes.quantityNotPositive => QuantityNotPositive(p.read<int>('requested')),
  ErrorCodes.quantityExceedsStock => QuantityExceedsStock(
    requested: p.read<int>('requested'),
    available: p.read<int>('available'),
  ),
  ErrorCodes.priceOutOfRange => PriceOutOfRange(
    value: _dinars(p, 'value'),
    min: _dinars(p, 'min'),
    max: _dinars(p, 'max'),
  ),
  ErrorCodes.stockOutOfRange => StockOutOfRange(units: p.read<int>('units'), max: p.read<int>('max')),
  ErrorCodes.textLengthInvalid => TextLengthInvalid(
    kind: textKindFromCode(p.read<String>('field')),
    length: p.read<int>('length'),
    min: p.read<int>('min'),
    max: p.read<int>('max'),
  ),
  ErrorCodes.transitionNotAllowed => TransitionNotAllowed(
    from: statusFromDto(OrderStatusDto.fromJson(p.readObject('from'))),
    to: statusFromDto(OrderStatusDto.fromJson(p.readObject('to'))),
  ),
  ErrorCodes.cancellationNotAllowed => CancellationNotAllowed(
    statusFromDto(OrderStatusDto.fromJson(p.readObject('status'))),
  ),
  ErrorCodes.notAuthorized => const NotAuthorized(UserId('')),
  ErrorCodes.tooManyActiveOrders => TooManyActiveOrders(p.read<int>('limit')),
  ErrorCodes.mixedProducers => const MixedProducers(),
  ErrorCodes.duplicateProductInOrder => DuplicateProductInOrder(ProductId(p.read<String>('productId'))),
  ErrorCodes.emptyOrder => const EmptyOrder(),
  ErrorCodes.productNotFound => ProductNotFound(ProductId(p.read<String>('productId'))),
  ErrorCodes.orderNotFound => OrderNotFound(OrderId(p.read<String>('orderId'))),
  ErrorCodes.addressRequired => const AddressRequired(),
  ErrorCodes.insufficientStock => InsufficientStock(
    productId: ProductId(p.read<String>('productId')),
    requested: p.read<int>('requested'),
    available: p.read<int>('available'),
  ),
  _ => null,
};

JsonMap moneyJson(int dinars) => MoneyDto(dinars).toJson();

int _dinars(JsonMap params, String key) {
  final money = MoneyDto.fromJson(params.readObject(key));
  if (money.currency != MoneyDto.rsd) {
    throw WireFormatException('Nepodržana valuta "${money.currency}"');
  }
  return money.amount;
}
