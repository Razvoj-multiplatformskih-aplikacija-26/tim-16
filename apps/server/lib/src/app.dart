import 'package:relic/relic.dart';

import 'handlers.dart';
import 'http.dart';

/// Sve rute servera na jednom mestu.
Handler buildHandler(ShopHandlers handlers) {
  final router = RelicRouter()
    ..get('/health', (request) => Response.ok(body: Body.fromString('ok')))
    ..get('/producers', handlers.producers)
    ..get('/products', handlers.products)
    ..get('/products/:id', handlers.product)
    ..fallback = respondWith(
      (request) => problem(status: 404, code: 'not_found', title: 'Nepostojeća ruta'),
    );
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}
