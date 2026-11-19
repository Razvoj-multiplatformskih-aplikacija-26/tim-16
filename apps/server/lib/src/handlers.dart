import 'dart:math';

import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domain;
import 'package:relic/relic.dart' hide Result;

import 'actor.dart';
import 'http.dart';
import 'problems.dart';
import 'shop_store.dart';
import 'wire.dart';

/// Rukovaoci zahteva.
///
/// Kada dva klijenta istovremeno traže isto (poslednji komad, ista porudžbina),
/// konačno odlučuje server: u transakciji zaključa redove koje menja
/// (`SELECT … FOR UPDATE`), pa drugi zahtev čeka prvi i tek onda proverava
/// pravilo nad već izmenjenim podacima. `CHECK (stock_units >= 0)` u bazi je
/// poslednja zaštita ako bi neki budući upis zaobišao ovaj put.
///
/// Svaki upis ide istim redom: pročitaj sveže podatke iz baze, pozovi
/// **istu domensku funkciju** koju zove i klijent (`placeOrder`,
/// `changeOrderStatus`, `cancelOrder`, `createProduct`, `updatePrice`,
/// `updateStock`), pa upiši samo ako je pravilo dozvolilo. Klijent proverava
/// pravila da bi korisnik odmah video grešku, ali konačno odlučuje server,
/// pa i poziv mimo aplikacije (curl, skripta) prolazi kroz ista pravila.
final class ShopHandlers {
  ShopHandlers({required this.store, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ShopStore store;
  final DateTime Function() _clock;
  final _random = Random.secure();

  // Javno, bez prijave.

  Future<Response> producers(Request request) async =>
      json(200, [for (final user in await store.producers()) userJson(user)]);

  Future<Response> products(Request request) async => json(200, [
    for (final product in await store.publishedProducts()) productJson(product),
  ]);

  Future<Response> product(Request request) async {
    final id = ProductId(request.rawPathParameters[#id]!);
    final found = await store.product(id);
    if (found == null || !found.published) return domainProblem(ProductNotFound(id));
    return json(200, productJson(found));
  }

  // Porudžbine.

  /// Kupac vidi svoje porudžbine, a proizvođač one iz svoje ponude.
  Future<Response> orders(Request request) => _signedIn(request, (actor) async {
    final orders = switch (actor.role) {
      UserRole.buyer => await store.ordersOfBuyer(actor.id),
      UserRole.producer => await store.ordersOfProducer(actor.id),
    };
    return json(200, [
      for (final order in orders)
        if (canViewOrder(actor, order)) orderJson(order),
    ]);
  });

  Future<Response> placeOrder(Request request) => _signedIn(request, (actor) async {
    final body = await readObject(request);
    final lines = [
      for (final item in field<List<Object?>>(body, 'lines'))
        switch (item) {
          final Map<String, Object?> line => OrderRequestLine(
            productId: ProductId(field<String>(line, 'productId')),
            quantity: field<int>(line, 'quantity'),
          ),
          _ => throw const FormatException('Stavka porudžbine mora biti objekat'),
        },
    ];
    final method = enumField(body, 'method', DeliveryMethod.values);
    final address = switch (optionalField<String>(body, 'address')) {
      null => null,
      final raw => DeliveryAddress.parse(raw),
    };
    if (address case Failure(:final error)) return domainProblem(error);

    return store.transaction((store) async {
      // Redosled zaključavanja je uvek isti (kupac, pa proizvodi po id-u),
      // pa dve transakcije ne mogu da čekaju jedna drugu u krug.
      await store.lockUser(actor.id);
      final catalog = await store.productsByIds(
        {for (final line in lines) line.productId},
        forUpdate: true,
      );
      final placed = domain.placeOrder(
        id: OrderId('o-${_token()}'),
        buyer: actor,
        request: lines,
        catalog: catalog,
        existingOrders: await store.ordersOfBuyer(actor.id),
        method: method,
        address: address?.valueOrNull,
        now: _clock().toUtc(),
      );
      if (placed case Failure(:final error)) return domainProblem(error);
      final order = placed.valueOrNull!;

      // Porudžbina odmah rezerviše zalihu, pa drugi kupac vidi koliko je ostalo.
      final reserved = reserveStock(order, catalog);
      if (reserved case Failure(:final error)) return domainProblem(error);
      await store.insertOrder(order);
      for (final product in reserved.valueOrNull!) {
        await store.updateProduct(product);
      }
      return json(201, orderJson(order));
    });
  });

  /// Proizvođač pomera porudžbinu napred: accepted, preparing, shipped, delivered.
  /// Vreme prihvatanja i slanja postavlja server, ne klijent.
  Future<Response> changeStatus(Request request) => _signedIn(request, (actor) async {
    final body = await readObject(request);
    final now = _clock().toUtc();
    final OrderStatus target = switch (field<String>(body, 'status')) {
      'accepted' => Accepted(acceptedAt: now),
      'preparing' => const Preparing(),
      'shipped' => Shipped(shippedAt: now),
      'delivered' => const Delivered(),
      final other => throw FormatException(
        'Stanje "$other" ne postoji ili se ne menja ovom rutom (otkazivanje: /orders/:id/cancellation)',
      ),
    };
    return _changeOrder(request, actor, (order) => changeOrderStatus(order, target, actor: actor));
  });

  /// Otkazuje kupac ili proizvođač; razlog sledi iz uloge (domen, `cancelOrder`).
  Future<Response> cancel(Request request) => _signedIn(
    request,
    (actor) => _changeOrder(request, actor, (order) => cancelOrder(order, actor: actor)),
  );

  Future<Response> _changeOrder(
    Request request,
    User actor,
    Result<Order> Function(Order order) change,
  ) => store.transaction((store) async {
    final id = OrderId(request.rawPathParameters[#id]!);
    final order = await store.order(id, forUpdate: true);
    // Tuđa porudžbina se ne razlikuje od nepostojeće: ne otkrivamo da postoji.
    if (order == null || !canViewOrder(actor, order)) return domainProblem(OrderNotFound(id));
    final changed = change(order);
    if (changed case Failure(:final error)) return domainProblem(error);
    final updated = changed.valueOrNull!;
    await store.updateOrderStatus(updated);
    if (updated.status is Cancelled) {
      // Otkazana porudžbina vraća rezervisanu zalihu (domen, `releaseStock`).
      final products = await store.productsByIds(
        {for (final line in updated.lines) line.productId},
        forUpdate: true,
      );
      for (final product in releaseStock(updated, products)) {
        await store.updateProduct(product);
      }
    }
    return json(200, orderJson(updated));
  });

  // Proizvodi (proizvođač).

  /// Svi proizvodi prijavljenog proizvođača, i neobjavljeni.
  Future<Response> myProducts(Request request) => _signedIn(request, (actor) async {
    if (actor.role != UserRole.producer) return domainProblem(NotAuthorized(actor.id));
    return json(200, [for (final product in await store.productsOf(actor.id)) productJson(product)]);
  });

  Future<Response> createProduct(Request request) => _signedIn(request, (actor) async {
    final body = await readObject(request);
    final created = domain.createProduct(
      id: ProductId('p-${_token()}'),
      actor: actor,
      name: field<String>(body, 'name'),
      description: optionalField<String>(body, 'description') ?? '',
      category: enumField(body, 'category', ProductCategory.values),
      unit: enumField(body, 'unit', ProductUnit.values),
      priceDinars: field<int>(body, 'priceDinars'),
      stockUnits: field<int>(body, 'stockUnits'),
    );
    if (created case Failure(:final error)) return domainProblem(error);
    await store.insertProduct(created.valueOrNull!);
    return json(201, productJson(created.valueOrNull!));
  });

  Future<Response> changePrice(Request request) => _changeProduct(request, (product, body, actor) {
    return updatePrice(product, field<int>(body, 'priceDinars'), actor: actor);
  });

  Future<Response> changeStock(Request request) => _changeProduct(request, (product, body, actor) {
    return updateStock(product, field<int>(body, 'stockUnits'), actor: actor);
  });

  Future<Response> deleteProduct(Request request) => _signedIn(request, (actor) async {
    final id = ProductId(request.rawPathParameters[#id]!);
    final product = await store.product(id);
    if (product == null) return domainProblem(ProductNotFound(id));
    if (!canManageProduct(actor, product)) return domainProblem(NotAuthorized(actor.id));
    await store.deleteProduct(id);
    return Response.noContent();
  });

  Future<Response> _changeProduct(
    Request request,
    Result<Product> Function(Product product, Map<String, Object?> body, User actor) change,
  ) => _signedIn(request, (actor) async {
    final body = await readObject(request);
    return store.transaction((store) async {
      final id = ProductId(request.rawPathParameters[#id]!);
      final product = await store.product(id, forUpdate: true);
      if (product == null) return domainProblem(ProductNotFound(id));
      final changed = change(product, body, actor);
      if (changed case Failure(:final error)) return domainProblem(error);
      await store.updateProduct(changed.valueOrNull!);
      return json(200, productJson(changed.valueOrNull!));
    });
  });

  // Pomoćno.

  Future<Response> _signedIn(Request request, Future<Response> Function(User actor) handle) async {
    final actor = await actorOf(request, store);
    if (actor == null) {
      return problem(
        status: 401,
        code: 'sign_in_required',
        title: 'Nepoznat korisnik: pošalji postojeći id u zaglavlju $actorHeader',
      );
    }
    return handle(actor);
  }

  String _token() => [
    for (var i = 0; i < 6; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
