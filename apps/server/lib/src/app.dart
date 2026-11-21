import 'package:contract/contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'handlers.dart';
import 'http.dart';
import 'sessions.dart';

/// Sve rute servera na jednom mestu. Ruta obmotana sa `signedIn` traži
/// prijavu koju je izdao server; ostale su javne.
Handler buildHandler(ShopHandlers handlers, SessionHandlers sessions, {required List<String> corsOrigins}) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
  // Prijava.
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut))
  // Javno, bez prijave.
    ..get('/producers', handlers.producers)
    ..get('/products', handlers.products)
    ..get('/products/:id', handlers.product)
  // Kupac i proizvođač.
    ..get('/orders', signedIn(handlers.orders))
    ..post('/orders', signedIn(handlers.placeOrder))
    ..post('/orders/:id/status', signedIn(handlers.changeStatus))
    ..post('/orders/:id/cancellation', signedIn(handlers.cancel))
  // Proizvođač (ulogu proverava domen u handleru).
    ..get('/my/products', signedIn(handlers.myProducts))
    ..post('/products', signedIn(handlers.createProduct))
    ..post('/products/:id/price', signedIn(handlers.changePrice))
    ..post('/products/:id/stock', signedIn(handlers.changeStock))
    ..delete('/products/:id', signedIn(handlers.deleteProduct))
    ..fallback = respondWith(
          (request) => problem(status: 404, code: ErrorCodes.routeNotFound, title: 'Nepostojeća ruta'),
    );
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}