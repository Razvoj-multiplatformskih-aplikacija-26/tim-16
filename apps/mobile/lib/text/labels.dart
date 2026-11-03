import 'package:domain/domain.dart';

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    Pending() => 'Na čekanju',
    Accepted() => 'Prihvaćena',
    Preparing() => 'U pripremi',
    Shipped() => 'Poslata',
    Delivered() => 'Isporučena',
    Cancelled() => 'Otkazana',
  };

  String get detail => switch (this) {
    Accepted(:final acceptedAt) => 'Prihvaćena ${formatDateTime(acceptedAt)}',
    Shipped(:final shippedAt) => 'Poslata ${formatDateTime(shippedAt)}',
    Cancelled(:final reason) =>
    reason == CancelReason.byBuyer
        ? 'Otkazana (kupac)'
        : 'Otkazana (proizvođač)',
    _ => label,
  };
}

extension ProductUnitLabel on ProductUnit {
  String get label => switch (this) {
    ProductUnit.kilogram => 'kg',
    ProductUnit.piece => 'kom',
    ProductUnit.liter => 'l',
    ProductUnit.jar => 'tegla',
  };
}

extension DeliveryMethodLabel on DeliveryMethod {
  String get label => switch (this) {
    DeliveryMethod.pickup => 'Preuzimanje',
    DeliveryMethod.delivery => 'Dostava',
  };
}

extension OrderText on Order {
  String get title => lines.length == 1
      ? lines.first.productName
      : '${lines.first.productName} i još ${lines.length - 1}';
}

String formatDinars(int dinars) => '$dinars RSD';

String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}. ${two(d.hour)}:${two(d.minute)}';
}