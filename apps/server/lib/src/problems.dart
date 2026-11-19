import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'http.dart';
import 'shop_store.dart';

/// Jedno mesto gde se domenska greška pretvara u HTTP odgovor.
///
/// Server ne piše poruku za korisnika: šalje stabilan `code` i podatke
/// pravila (granicu, dostupnu količinu…), a klijent od njih pravi istu poruku
/// kao kada pravilo proveri sam. `switch` je iscrpan nad zapečaćenom klasom
/// `DomainError`, pa nova greška u domenu ne može da se zaboravi ovde.
Response domainProblem(DomainError error) {
  final (status, code, details) = describe(error);
  return problem(status: status, code: code, title: code, details: details);
}

(int, String, Map<String, Object?>) describe(DomainError error) => switch (error) {
  QuantityNotPositive(:final requested) => (422, 'quantity_not_positive', {'requested': requested}),
  QuantityExceedsStock(:final requested, :final available) => (
    409,
    'quantity_exceeds_stock',
    {'requested': requested, 'available': available},
  ),
  PriceOutOfRange(:final value, :final min, :final max) => (
    422,
    'price_out_of_range',
    {'value': value, 'min': min, 'max': max},
  ),
  StockOutOfRange(:final units, :final max) => (422, 'stock_out_of_range', {'units': units, 'max': max}),
  TextLengthInvalid(:final kind, :final length, :final min, :final max) => (
    422,
    'text_length_invalid',
    {'kind': kind.name, 'length': length, 'min': min, 'max': max},
  ),
  TransitionNotAllowed(:final from, :final to) => (
    409,
    'transition_not_allowed',
    {'from': statusName(from), 'to': statusName(to)},
  ),
  CancellationNotAllowed(:final status) => (409, 'cancellation_not_allowed', {'status': statusName(status)}),
  NotAuthorized() => (403, 'not_authorized', const {}),
  TooManyActiveOrders(:final limit) => (409, 'too_many_active_orders', {'limit': limit}),
  MixedProducers() => (422, 'mixed_producers', const {}),
  DuplicateProductInOrder(:final productId) => (
    422,
    'duplicate_product_in_order',
    {'productId': productId.value},
  ),
  EmptyOrder() => (422, 'empty_order', const {}),
  ProductNotFound(:final productId) => (404, 'product_not_found', {'productId': productId.value}),
  OrderNotFound(:final orderId) => (404, 'order_not_found', {'orderId': orderId.value}),
  AddressRequired() => (422, 'address_required', const {}),
  InsufficientStock(:final productId, :final requested, :final available) => (
    409,
    'insufficient_stock',
    {'productId': productId.value, 'requested': requested, 'available': available},
  ),
};

String statusName(OrderStatus status) => orderStatusColumns(status).status;
