import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'http.dart';
import 'shop_store.dart';

/// Rukovaoci zahteva. Ovde se za sada samo čita; upisi i provera pravila
/// dolaze u sledećim koracima KT2.
final class ShopHandlers {
  const ShopHandlers({required this.store});

  final ShopStore store;

  Future<Response> producers(Request request) async =>
      json(200, [for (final user in await store.producers()) userJson(user)]);

  Future<Response> products(Request request) async => json(200, [
    for (final product in await store.publishedProducts()) productJson(product),
  ]);

  Future<Response> product(Request request) async {
    final found = await store.product(ProductId(request.rawPathParameters[#id]!));
    if (found == null || !found.published) {
      return problem(status: 404, code: 'product_not_found', title: 'Proizvod nije pronađen');
    }
    return json(200, productJson(found));
  }
}

// Privremeni JSON oblik modela. U stavci 2 KT2 prelazi u zajednički paket ugovora.

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
