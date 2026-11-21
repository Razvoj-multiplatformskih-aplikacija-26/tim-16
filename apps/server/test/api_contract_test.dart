@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';
import 'support.dart';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:mapping/mapping.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';

late Pool<void> database;
late RelicServer server;
late Uri base;



Future<http.Response> get(String path, {String? user, Map<String, String>? query}) =>
    http.get(base.replace(path: path, queryParameters: query), headers: authAs(user));

Future<http.Response> post(String path, String user, JsonMap body) => http.post(
  base.replace(path: path),
  headers: {'Content-Type': 'application/json', ...authAs(user)},
  body: jsonEncode(body),
);

Future<http.Response> logIn(String username, String password) => http.post(
  base.replace(path: ApiPaths.sessions),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(LoginDto(username: username, password: password).toJson()),
);

JsonMap bodyOf(http.Response response) => asObject(jsonDecode(response.body));

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
    final admin = Pool<void>.withUrl(config.databaseUrl);
    await admin.execute('DROP DATABASE IF EXISTS svezko_test_api WITH (FORCE)');
    await admin.execute('CREATE DATABASE svezko_test_api');
    await admin.close();

    final url = Uri.parse(config.databaseUrl);
    database = Pool<void>.withUrl(url.replace(path: '/svezko_test_api').toString());
    await applyMigrations(database);

    await seedDemoPasswords(database, demoPassword: 'test-lozinka');

    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        ShopHandlers(store: ShopStore(database), lineLimit: 3),
        testSessions(database),
        corsOrigins: const [testOrigin],
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  group('prijava', () {
    test('tačna lozinka daje prijavu za pravog korisnika', () async {
      final response = await logIn('kupac1', 'test-lozinka');
      expect(response.statusCode, 201);
      final session = SessionDto.fromJson(bodyOf(response));
      expect(userFromDto(session.user).id, const UserId('u-buyer-1'));
      expect(session.token, isNotNull);

      final current = await http.get(
        base.replace(path: ApiPaths.currentSession),
        headers: {'Authorization': 'Bearer ${session.token}'},
      );
      expect(current.statusCode, 200);
    });

    test('pogrešna lozinka i nepostojeći nalog daju isti odgovor', () async {
      final wrong = await logIn('kupac1', 'pogresna');
      final unknown = await logIn('niko', 'test-lozinka');
      expect(wrong.statusCode, 401);
      expect(bodyOf(wrong)['code'], ErrorCodes.invalidCredentials);
      expect(unknown.statusCode, 401);
      expect(bodyOf(unknown)['code'], ErrorCodes.invalidCredentials);
    });

    test('u bazi je samo Argon2id heš lozinke', () async {
      final rows = await database.execute('SELECT password_hash FROM users WHERE login IS NOT NULL');
      expect(rows.map((row) => row[0]! as String), everyElement(startsWith(r'$argon2id$')));
    });

    test('server ne veruje zaglavlju X-User-Id', () async {
      final response = await http.get(base.replace(path: ApiPaths.orders), headers: {'X-User-Id': 'pr-1'});
      expect(response.statusCode, 401);
      expect(bodyOf(response)['code'], ErrorCodes.signInRequired);
    });

    test('token potpisan tuđom tajnom ne važi', () async {
      final forged = tokenFor('pr-1', secret: 'neka-druga-tajna-0123456789abcdef-xyz');
      final response = await http.get(base.replace(path: ApiPaths.orders), headers: {'Authorization': 'Bearer $forged'});
      expect(response.statusCode, 401);
    });

    test('istekla prijava se odbija kodom session_expired', () async {
      final expired = tokenFor('u-buyer-1', validFor: const Duration(minutes: -1));
      final response = await http.get(base.replace(path: ApiPaths.orders), headers: {'Authorization': 'Bearer $expired'});
      expect(response.statusCode, 401);
      expect(bodyOf(response)['code'], ErrorCodes.sessionExpired);
    });
  });

  group('uloge na serveru', () {
    test('kupac ne može da prihvati porudžbinu ni pozivom mimo aplikacije', () async {
      final response = await post(ApiPaths.orderStatus('o-1001'), 'u-buyer-1', {'status': 'accepted'});
      expect(response.statusCode, 403);
      expect(bodyOf(response)['code'], ErrorCodes.notAuthorized);
    });

    test('kupac ne može da menja cenu proizvoda', () async {
      final response = await post(ApiPaths.productPrice('p1'), 'u-buyer-1', ChangePriceRequest(const MoneyDto(200)).toJson());
      expect(response.statusCode, 403);
      expect(bodyOf(response)['code'], ErrorCodes.notAuthorized);
    });

    test('kupac ne može da otkaže tuđu porudžbinu', () async {
      // o-1007 je porudžbina kupca u-buyer-2.
      final response = await post(ApiPaths.orderCancellation('o-1007'), 'u-buyer-1', const {});
      expect(response.statusCode, 404);
      expect(bodyOf(response)['code'], ErrorCodes.orderNotFound);
    });
  });

  group('pregledač', () {
    test('backoffice-ovo poreklo dobija CORS zaglavlja', () async {
      final response = await http.get(base.replace(path: ApiPaths.products), headers: {'Origin': testOrigin});
      expect(response.headers['access-control-allow-origin'], testOrigin);
    });

    test('upis sa tuđeg porekla se odbija', () async {
      final response = await http.post(
        base.replace(path: ApiPaths.sessions),
        headers: {'Origin': 'http://zlonamerni.example', 'Content-Type': 'application/json'},
        body: jsonEncode(const LoginDto(username: 'kupac1', password: 'test-lozinka').toJson()),
      );
      expect(response.statusCode, 403);
    });
  });

  group('straničenje', () {
    test('javna ponuda se čita deo po deo, bez ponavljanja i preskakanja', () async {
      final seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        final response = await get(ApiPaths.products, query: {'limit': '4', 'cursor': ?cursor});
        expect(response.statusCode, 200);
        final page = PageDto.fromJson(bodyOf(response), ProductDto.fromJson);
        expect(page.items.length, lessThanOrEqualTo(4));
        seen.addAll(page.items.map((item) => item.id));
        cursor = page.nextCursor;
        pages++;
      } while (cursor != null);

      expect(pages, 3);
      expect(seen.toSet(), hasLength(10));
    });

    test('porudžbine kupca stižu od najnovije, po stranama', () async {
      final first = PageDto.fromJson(bodyOf(await get(ApiPaths.orders, user: 'u-buyer-1', query: {'limit': '3'})), OrderDto.fromJson);
      final second = PageDto.fromJson(
        bodyOf(await get(ApiPaths.orders, user: 'u-buyer-1', query: {'limit': '3', 'cursor': first.nextCursor!})),
        OrderDto.fromJson,
      );
      final all = [...first.items, ...second.items];
      expect(all.map((order) => order.buyerId).toSet(), {'u-buyer-1'});
      for (var i = 1; i < all.length; i++) {
        expect(all[i - 1].createdAt.isBefore(all[i].createdAt), isFalse);
      }
    });

    test('pogrešan limit ili kursor je 400 bad_request', () async {
      expect(bodyOf(await get(ApiPaths.products, query: {'limit': '1000'}))['code'], ErrorCodes.badRequest);
      expect(bodyOf(await get(ApiPaths.products, query: {'cursor': 'nije-kursor'}))['code'], ErrorCodes.badRequest);
    });
  });

  group('šta vidi koja uloga', () {
    test('javni proizvod nema published, proizvođač za svoje ima', () async {
      final public = PageDto.fromJson(bodyOf(await get(ApiPaths.products)), ProductDto.fromJson);
      expect(public.items.every((item) => item.published == null), isTrue);

      final own = PageDto.fromJson(bodyOf(await get(ApiPaths.myProducts, user: 'pr-1')), ProductDto.fromJson);
      expect(own.items.map((item) => item.producerId).toSet(), {'pr-1'});
      expect(own.items.every((item) => item.published != null), isTrue);
    });

    test('proizvođač u javnom delu nema ulogu, samo ime', () async {
      final producers = jsonDecode((await get(ApiPaths.producers)).body) as List<Object?>;
      expect((producers.first! as Map).keys.toSet(), {'id', 'fullName'});
    });
  });

  group('novac, vreme i stanja na mreži', () {
    test('cena je ceo broj sa valutom, vreme u UTC, stanje je kôd', () async {
      final product = bodyOf(await get(ApiPaths.product('p1')));
      expect(product['price'], {'amount': 150, 'currency': 'RSD'});

      final orders = PageDto.fromJson(bodyOf(await get(ApiPaths.orders, user: 'u-buyer-1', query: {'limit': '100'})), (json) => json);
      final accepted = orders.items.firstWhere((order) => order['id'] == 'o-1002');
      expect(accepted['status'], {'code': 'accepted', 'at': '2026-11-02T12:00:00.000Z'});
      expect(accepted['createdAt'], '2026-11-02T11:00:00.000Z');
      expect(accepted['total'], {'amount': 800, 'currency': 'RSD'});
    });

    test('svaka porudžbina sa servera postaje domenski model kroz mapping', () async {
      final orders = PageDto.fromJson(bodyOf(await get(ApiPaths.orders, user: 'u-buyer-1', query: {'limit': '100'})), OrderDto.fromJson);
      expect(orders.items.map(orderFromDto), everyElement(isA<Order>()));
    });
  });

  group('greške', () {
    test('kršenje pravila nosi kôd i podatke, i vraća se u istu domensku grešku', () async {
      final response = await post(ApiPaths.productPrice('p1'), 'pr-1', ChangePriceRequest(const MoneyDto(0)).toJson());
      expect(response.statusCode, 422);
      final problem = ProblemDto.fromJson(bodyOf(response));
      expect(problem.code, ErrorCodes.priceOutOfRange);
      expect(
        domainErrorOf(problem),
        isA<PriceOutOfRange>().having((error) => error.min, 'min', Price.min).having((error) => error.max, 'max', Price.max),
      );
    });

    test('pravilo koje aplikacija ne poznaje ima svoj kôd i podatke', () async {
      final response = await post(
        ApiPaths.orders,
        'u-buyer-2',
        const PlaceOrderRequest(lines: [OrderLineRequest(productId: 'p6', quantity: 5)], method: 'pickup').toJson(),
      );
      expect(response.statusCode, 422);
      final problem = ProblemDto.fromJson(bodyOf(response));
      expect(problem.code, ShopHandlers.lineLimitCode);
      expect(problem.params, {'limit': 3});
      expect(domainErrorOf(problem), isNull);
    });

    test('pogrešan oblik zahteva je 400, a ne kršenje pravila', () async {
      final response = await post(ApiPaths.productPrice('p1'), 'pr-1', {'priceDinars': 200});
      expect(response.statusCode, 400);
      expect(bodyOf(response)['code'], ErrorCodes.badRequest);
    });
  });
}
