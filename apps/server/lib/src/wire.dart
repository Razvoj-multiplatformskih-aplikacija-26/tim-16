import 'package:domain/domain.dart';

import 'shop_store.dart';

// Privremeni JSON oblik zahteva i odgovora. U stavci 2 KT2 prelazi u
// zajednički paket ugovora koji koriste i klijenti.

Map<String, Object?> userJson(User user) => {
  'id': user.id.value,
  'fullName': user.fullName,
  'role': user.role.name,
};

Map<String, Object?> productJson(Product product) => {
  'id': product.id.value,
  'producerId': product.producerId.value,
  'name': product.name.value,
  'description': product.description,
  'category': product.category.name,
  'unit': product.unit.name,
  'priceDinars': product.price.dinars,
  'stockUnits': product.stock.units,
  'published': product.published,
  'imageUrl': product.imageUrl,
};

Map<String, Object?> orderJson(Order order) {
  final columns = orderStatusColumns(order.status);
  return {
    'id': order.id.value,
    'buyerId': order.buyerId.value,
    'producerId': order.producerId.value,
    'status': columns.status,
    if (columns.at != null) 'statusAt': columns.at!.toUtc().toIso8601String(),
    if (columns.cancelReason != null) 'cancelReason': columns.cancelReason,
    'method': order.method.name,
    if (order.address != null) 'address': order.address!.value,
    'createdAt': order.createdAt.toUtc().toIso8601String(),
    'total': order.total,
    'lines': [
      for (final line in order.lines)
        {
          'productId': line.productId.value,
          'productName': line.productName,
          'unitPriceDinars': line.unitPrice.dinars,
          'quantity': line.quantity.value,
        },
    ],
  };
}

// Čitanje polja iz tela zahteva. Pogrešan oblik je 400 (FormatException),
// a ne kršenje pravila: pravila proverava domen tek nad ispravnim podacima.

T field<T>(Map<String, Object?> body, String name) => switch (body[name]) {
  final T value => value,
  _ => throw FormatException('Polje "$name" nedostaje ili ima pogrešan tip'),
};

T? optionalField<T>(Map<String, Object?> body, String name) => switch (body[name]) {
  null => null,
  final T value => value,
  _ => throw FormatException('Polje "$name" ima pogrešan tip'),
};

E enumField<E extends Enum>(Map<String, Object?> body, String name, List<E> values) {
  final raw = field<String>(body, name);
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Polje "$name" ne može da ima vrednost "$raw"');
}
