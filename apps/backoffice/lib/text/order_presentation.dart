import 'package:domain/domain.dart';



extension OrderStatusPresentation on OrderStatus {

  String get label => switch (this) {
    Pending() => 'Na čekanju',
    Accepted() => 'Prihvaćena',
    Preparing() => 'U pripremi',
    Shipped() => 'Poslata',
    Delivered() => 'Isporučena',
    Cancelled(:final reason) => reason == CancelReason.byBuyer
        ? 'Otkazao kupac'
        : 'Otkazao proizvođač',
  };

  String get actionLabel => switch (this) {
    Pending() => 'Vrati na čekanje',
    Accepted() => 'Prihvati porudžbinu',
    Preparing() => 'Započni pripremu',
    Shipped() => 'Označi kao poslatu',
    Delivered() => 'Označi kao isporučenu',
    Cancelled() => 'Otkaži porudžbinu',
  };
}


List<OrderStatus> nextStatuses(OrderStatus from, {DateTime? now}) {
  final at = now ?? DateTime.now();
  return <OrderStatus>[
    Accepted(acceptedAt: at),
    const Preparing(),
    Shipped(shippedAt: at),
    const Delivered(),
    const Cancelled(CancelReason.byProducer),
  ].where((status) => canTransition(from, status)).toList();
}

String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}. ${two(d.hour)}:${two(d.minute)}';
}

String deliveryLabel(Order order) => order.method == DeliveryMethod.delivery
    ? (order.address?.value ?? 'Kurir')
    : 'Preuzimanje';

String linesSummary(Order order) => order.lines
    .map((line) => '${line.productName} × ${line.quantity.value}')
    .join(', ');