import 'package:domain/domain.dart';

import 'labels.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    QuantityNotPositive() => 'Količina mora biti bar 1.',
    QuantityExceedsStock(:final available) =>
    'Nedovoljna količina na stanju. Dostupno je $available.',
    PriceOutOfRange(:final min, :final max) =>
    'Cena mora biti između $min i $max RSD.',
    StockOutOfRange(:final max) => 'Zaliha mora biti između 0 i $max.',
    TextLengthInvalid(:final kind, :final length, :final min, :final max) =>
        _textLengthMessage(kind, length, min, max),
    TransitionNotAllowed(:final from, :final to) =>
    'Promena stanja iz „${from.label}“ u „${to.label}“ nije dozvoljena.',
    CancellationNotAllowed(:final status) =>
    'Porudžbina u stanju „${status.label}“ ne može da se otkaže.',
    NotAuthorized() => 'Nemate pravo na ovu radnju.',
    TooManyActiveOrders(:final limit) =>
    'Možete imati najviše $limit aktivnih porudžbina.',
    MixedProducers() =>
    'Porudžbina može da sadrži proizvode samo jednog proizvođača.',
    DuplicateProductInOrder() => 'Proizvod je već u porudžbini.',
    EmptyOrder() => 'Porudžbina je prazna.',
    ProductNotFound() => 'Proizvod nije pronađen ili nije dostupan.',
    OrderNotFound() => 'Porudžbina nije pronađena.',
    AddressRequired() => 'Za isporuku je potrebna adresa.',
    InsufficientStock(:final available) =>
    'Nema dovoljno proizvoda na stanju. Dostupno je $available.',
  };
}

String _textLengthMessage(TextKind kind, int length, int min, int max) {
  final field = switch (kind) {
    TextKind.productName => 'Naziv proizvoda',
    TextKind.deliveryAddress => 'Adresa isporuke',
  };
  if (length < min) return '$field mora imati bar $min znakova.';
  return '$field može imati najviše $max znakova.';
}