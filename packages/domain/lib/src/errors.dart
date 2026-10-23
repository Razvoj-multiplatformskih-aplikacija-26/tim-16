import 'identifiers.dart';
import 'order/order_status.dart';

sealed class DomainError {
  const DomainError();
}

//Kolicina , cena i zaliha

final class QuantityNotPositive extends DomainError{
  const QuantityNotPositive(this.requested);
  final int requested;
}

final class QuantityExceedsStock extends DomainError {
  const QuantityExceedsStock({required this.requested, required this.available});
  final int requested;
  final int available;
}

final class PriceOutOfRange extends DomainError{
  const PriceOutOfRange({required this.value,required this.min,required this.max});
  final int value;
  final int min;
  final int max;
}

final class StockOutOfRange extends DomainError{
  const StockOutOfRange({required this.units, required this.max});
  final int units;
  final int max;
}


// tekstualna polja

enum TextKind { productName, deliveryAddress }

final class TextLengthInvalid extends DomainError {
  const TextLengthInvalid({
    required this.kind,
    required this.length,
    required this.min,
    required this.max,
  });
  final TextKind kind;
  final int length;
  final int min;
  final int max;
}

//stanje porudzbina

///nije dozvoljeno prelazak stanja npr deliverd u pendning
final class TransitionNotAllowed extends DomainError {
  const TransitionNotAllowed({required this.from, required this.to});
  final OrderStatus from;
  final OrderStatus to;
}

final class CancellationNotAllowed extends DomainError {
  const CancellationNotAllowed(this.status);
  final OrderStatus status;
}

final class NotAuthorized extends DomainError {
  const NotAuthorized(this.userId);
  final UserId userId;
}

// Pravljenje porudzbine

final class EmptyOrder extends DomainError {
  const EmptyOrder();
}

final class ProductNotFound extends DomainError {
  const ProductNotFound(this.productId);
  final ProductId productId;
}

final class AddressRequired extends DomainError {
  const AddressRequired();
}

final class InsufficientStock extends DomainError {
  const InsufficientStock({
    required this.productId,
    required this.requested,
    required this.available,
  });
  final ProductId productId;
  final int requested;
  final int available;
}

