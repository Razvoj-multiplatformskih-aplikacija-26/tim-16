import 'dart:convert';

import 'package:blocs/blocs.dart';
import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapping/mapping.dart';
import 'package:test/test.dart';

const buyer = User(id: UserId('u-buyer-1'), fullName: 'Marko', role: UserRole.buyer);

Product honey({int stock = 5}) => createProduct(
  id: const ProductId('p2'),
  actor: const User(id: UserId('pr-2'), fullName: 'Gazdinstvo', role: UserRole.producer),
  name: 'Med',
  description: '',
  category: ProductCategory.honey,
  unit: ProductUnit.jar,
  priceDinars: 800,
  stockUnits: stock,
).valueOrNull!;

http.Response jsonResponse(int status, Object? body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

JsonMap page(List<Object?> items, {String? next}) => {'items': items, 'nextCursor': next};

MockClient server({required http.Response Function(http.Request request) onOrder}) => MockClient((request) async {
  return switch ((request.method, request.url.path)) {
    ('GET', ApiPaths.producers) => jsonResponse(200, [
      {'id': 'pr-2', 'fullName': 'Gazdinstvo'},
    ]),
    ('GET', ApiPaths.products) => jsonResponse(200, page([productToDto(honey()).toJson()])),
    ('GET', ApiPaths.orders) => jsonResponse(200, page(const [])),
    ('POST', ApiPaths.orders) => onOrder(request),
    _ => jsonResponse(404, const ProblemDto(status: 404, code: 'not_found').toJson()),
  };
});

Future<ShopLoaded> feedbackOf(ShopBloc bloc) async =>
    await bloc.stream.firstWhere((s) => s is ShopLoaded && s.feedback != null) as ShopLoaded;

Future<ShopBloc> loadedBloc(ShopRepository repository) async {
  final bloc = ShopBloc(repository: repository, currentUser: buyer)..add(const LoadShopDataEvent());
  await bloc.stream.firstWhere((s) => s is ShopLoaded);
  return bloc;
}

void main() {
  final base = Uri.parse('http://server');

  group('put jedne greške do poruke', () {
    test('server odbije pravilom: korisnik vidi istu poruku kao kada pravilo proveri klijent', () async {
      final repository = HttpShopRepository(
        baseUrl: base,
        user: buyer,
        client: server(
          onOrder: (_) => jsonResponse(409, problemOf(const QuantityExceedsStock(requested: 3, available: 1)).toJson()),
        ),
      );
      final bloc = await loadedBloc(repository);

      bloc.add(const CreateOrderEvent(productId: ProductId('p2'), quantity: 3));
      final state = await feedbackOf(bloc);

      final feedback = state.feedback! as RuleViolated;
      expect(feedback.error, isA<QuantityExceedsStock>());
      final local = Quantity.parse(3, available: 1).errorOrNull!;
      expect(errorMessageOf(feedback), local.message);
      expect(errorMessageOf(feedback), 'Nedovoljna količina na stanju. Dostupno je 1.');
      await bloc.close();
    });

    test('granica u poruci je ona sa servera', () async {
      final repository = HttpShopRepository(
        baseUrl: base,
        user: buyer,
        client: server(onOrder: (_) => jsonResponse(409, problemOf(const TooManyActiveOrders(3)).toJson())),
      );
      final bloc = await loadedBloc(repository);

      bloc.add(const CreateOrderEvent(productId: ProductId('p2'), quantity: 1));
      final state = await feedbackOf(bloc);

      expect(errorMessageOf(state.feedback!), 'Možete imati najviše 3 aktivnih porudžbina.');
      await bloc.close();
    });

    test('uspeh: porudžbina u stanju ima id koji je dodelio server', () async {
      late JsonMap sent;
      final repository = HttpShopRepository(
        baseUrl: base,
        user: buyer,
        client: server(
          onOrder: (request) {
            sent = asObject(jsonDecode(request.body));
            return jsonResponse(201, {
              'id': 'o-server-1',
              'buyerId': buyer.id.value,
              'producerId': 'pr-2',
              'status': {'code': 'pending'},
              'method': 'pickup',
              'createdAt': '2026-11-20T14:00:00.000Z',
              'lines': [
                {'productId': 'p2', 'productName': 'Med', 'unitPrice': {'amount': 800, 'currency': 'RSD'}, 'quantity': 2},
              ],
              'total': {'amount': 1600, 'currency': 'RSD'},
            });
          },
        ),
      );
      final bloc = await loadedBloc(repository);

      bloc.add(const CreateOrderEvent(productId: ProductId('p2'), quantity: 2));
      final state = await feedbackOf(bloc);

      expect(state.feedback, isA<OrderPlaced>());
      expect(state.orders.first.id, const OrderId('o-server-1'));
      expect(sent, {
        'lines': [
          {'productId': 'p2', 'quantity': 2},
        ],
        'method': 'pickup',
      });
      await bloc.close();
    });
  });

  group('stara verzija aplikacije ne pada', () {
    test('pravilo koje aplikacija ne poznaje: opšta poruka, bez tehničkog teksta', () async {
      final repository = HttpShopRepository(
        baseUrl: base,
        user: buyer,
        client: server(
          onOrder: (_) => jsonResponse(
            422,
            const ProblemDto(
              status: 422,
              code: 'quantity_above_line_limit',
              params: {'limit': 1},
              title: 'Najviše 1 po stavci (novo pravilo na serveru)',
            ).toJson(),
          ),
        ),
      );
      final bloc = await loadedBloc(repository);

      bloc.add(const CreateOrderEvent(productId: ProductId('p2'), quantity: 2));
      final state = await feedbackOf(bloc);

      expect(state.feedback, const RefusedByServer('quantity_above_line_limit'));
      final message = errorMessageOf(state.feedback!)!;
      expect(message, refusedByServerMessage);
      expect(message, isNot(contains('quantity_above_line_limit')));
      expect(message, isNot(contains('422')));
      await bloc.close();
    });

    test('poznat kôd sa podacima u novom obliku takođe daje opštu poruku', () {
      final rejection = rejectionOf(
        409,
        utf8.encode(jsonEncode({'status': 409, 'code': 'quantity_exceeds_stock', 'params': {'available': 'malo'}})),
      );
      expect(rejection, isA<ActionRefused>());
    });

    test('greška na serveru ili odgovor koji nije iz ugovora: „pokušajte ponovo“', () {
      expect(
        rejectionOf(500, utf8.encode(jsonEncode(const ProblemDto(status: 500, code: 'server_error').toJson()))),
        isA<RepositoryUnavailable>(),
      );
      expect(rejectionOf(502, utf8.encode('<html>Bad gateway</html>')), isA<RepositoryUnavailable>());
      expect(
        rejectionOf(400, utf8.encode(jsonEncode(const ProblemDto(status: 400, code: 'bad_request').toJson()))),
        isA<RepositoryUnavailable>(),
      );
    });

    test('zapis koji aplikacija ne ume da pročita se preskače, ostali ostaju', () async {
      final order = orderToDto(
        Order(
          id: const OrderId('o-1'),
          buyerId: buyer.id,
          producerId: const UserId('pr-2'),
          lines: [
            OrderLine(
              productId: const ProductId('p2'),
              productName: 'Med',
              unitPrice: Price.parse(800).valueOrNull!,
              quantity: Quantity.parse(1, available: 1).valueOrNull!,
            ),
          ],
          status: const Pending(),
          createdAt: DateTime.utc(2026, 11, 20),
          method: DeliveryMethod.pickup,
        ),
      ).toJson();
      final newerStatus = {...order, 'id': 'o-2', 'status': {'code': 'ready_for_pickup'}};
      final newerCategory = {...productToDto(honey()).toJson(), 'id': 'p9', 'category': 'mushrooms'};

      final repository = HttpShopRepository(
        baseUrl: base,
        user: buyer,
        client: MockClient((request) async => switch (request.url.path) {
          ApiPaths.orders => jsonResponse(200, page([order, newerStatus])),
          _ => jsonResponse(200, page([productToDto(honey()).toJson(), newerCategory])),
        }),
      );

      expect((await repository.loadOrders()).map((o) => o.id), [const OrderId('o-1')]);
      expect((await repository.loadProducts()).map((p) => p.id), [const ProductId('p2')]);
      expect(repository.skippedRecords, 2);
    });
  });

  group('straničenje', () {
    test('klijent traži listu deo po deo dok server vraća kursor', () async {
      final requested = <Map<String, String>>[];
      final repository = HttpShopRepository(
        baseUrl: base,
        user: buyer,
        pageSize: 1,
        client: MockClient((request) async {
          requested.add(request.url.queryParameters);
          final first = request.url.queryParameters['cursor'] == null;
          final product = {...productToDto(honey()).toJson(), 'id': first ? 'p1' : 'p2'};
          return jsonResponse(200, page([product], next: first ? 'sledeca' : null));
        }),
      );

      final products = await repository.loadProducts();

      expect(products.map((p) => p.id.value), ['p1', 'p2']);
      expect(requested, [
        {'limit': '1'},
        {'limit': '1', 'cursor': 'sledeca'},
      ]);
    });
  });
}
