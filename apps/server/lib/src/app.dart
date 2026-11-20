import 'package:contract/contract.dart';
import 'package:relic/relic.dart';

import 'handlers.dart';
import 'http.dart';

/// Sve rute servera na jednom mestu.
Handler buildHandler(ShopHandlers handlers) {
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    // Javno, bez prijave.
    ..get('/producers', handlers.producers)
    ..get('/products', handlers.products)
    ..get('/products/:id', handlers.product)
    // Kupac i proizvođač (zaglavlje X-User-Id do uvođenja prijave).
    ..get('/orders', handlers.orders)
    ..post('/orders', handlers.placeOrder)
    ..post('/orders/:id/status', handlers.changeStatus)
    ..post('/orders/:id/cancellation', handlers.cancel)
    // Proizvođač.
    ..get('/my/products', handlers.myProducts)
    ..post('/products', handlers.createProduct)
    ..post('/products/:id/price', handlers.changePrice)
    ..post('/products/:id/stock', handlers.changeStock)
    ..delete('/products/:id', handlers.deleteProduct)
    ..fallback = respondWith(
      (request) => problem(status: 404, code: ErrorCodes.routeNotFound, title: 'Nepostojeća ruta'),
    );
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}
