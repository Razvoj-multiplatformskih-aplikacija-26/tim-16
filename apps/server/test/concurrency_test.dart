@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';

// Pokretanje (iz apps/server, uz pokrenutu bazu: docker compose up -d db):
//   dart test
//
// Test pravi svoju bazu `svezko_test`, primeni iste migracije kao dbmate i
// podigne server na slobodnom portu, pa ne dira podatke za razvoj.

late Pool<void> database;
late RelicServer server;
late Uri base;

Future<void> applyMigrations(Session session) async {
  final files = Directory('migrations').listSync().whereType<File>().where((file) => file.path.endsWith('.sql')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final text = file.readAsStringSync();
    final up = text.substring(text.indexOf('-- migrate:up'), text.indexOf('-- migrate:down'));
    await session.execute(up, queryMode: QueryMode.simple);
  }
}

Future<http.Response> post(String path, String user, [Map<String, Object?>? body]) => http.post(
  base.replace(path: path),
  headers: {'Content-Type': 'application/json', 'X-User-Id': user},
  body: body == null ? null : jsonEncode(body),
);

Future<http.Response> order(String buyer, String productId, int quantity) =>
    post('/orders', buyer, {
      'lines': [
        {'productId': productId, 'quantity': quantity},
      ],
      'method': 'pickup',
    });

Map<String, Object?> bodyOf(http.Response response) => jsonDecode(response.body) as Map<String, Object?>;

Future<int> stockOf(String productId) async {
  final rows = await database.execute(
    Sql.named('SELECT stock_units FROM products WHERE id = @id'),
    parameters: {'id': productId},
  );
  return rows.single[0]! as int;
}

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
    final admin = Pool<void>.withUrl(config.databaseUrl);
    await admin.execute('DROP DATABASE IF EXISTS svezko_test WITH (FORCE)');
    await admin.execute('CREATE DATABASE svezko_test');
    await admin.close();

    final url = Uri.parse(config.databaseUrl);
    database = Pool<void>.withUrl(url.replace(path: '/svezko_test').toString());
    await applyMigrations(database);
    for (var n = 1; n <= 10; n++) {
      await database.execute(
        Sql.named("INSERT INTO users (id, full_name, role) VALUES (@id, @name, 'buyer')"),
        parameters: {'id': 'u-test-$n', 'name': 'Test kupac $n'},
      );
    }

    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(buildHandler(ShopHandlers(store: ShopStore(database))));
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  test('poslednji komad, dva kupca u istom trenutku: prolazi tačno jedan', () async {
    expect(await stockOf('p10'), 1);

    final answers = await Future.wait([order('u-test-1', 'p10', 1), order('u-test-2', 'p10', 1)]);

    expect(answers.map((answer) => answer.statusCode), unorderedEquals([201, 409]));
    final lost = bodyOf(answers.firstWhere((answer) => answer.statusCode == 409));
    expect(lost['code'], 'quantity_exceeds_stock');
    expect((lost['details']! as Map)['available'], 0);
    expect(await stockOf('p10'), 0);
  });

  test('deset kupaca istovremeno, dva komada: prolaze tačno dva, zaliha nije negativna', () async {
    expect(await stockOf('p3'), 2);

    final answers = await Future.wait([for (var n = 1; n <= 10; n++) order('u-test-$n', 'p3', 1)]);

    expect(answers.where((answer) => answer.statusCode == 201), hasLength(2));
    expect(answers.where((answer) => answer.statusCode == 409), hasLength(8));
    expect(await stockOf('p3'), 0);
  });

  test('isti kupac sa dva uređaja preko granice aktivnih porudžbina: prolazi jedna', () async {
    // u-buyer-1 u početnim podacima ima 4 aktivne porudžbine, a granica je 5.
    final answers = await Future.wait([order('u-buyer-1', 'p6', 1), order('u-buyer-1', 'p6', 1)]);

    expect(answers.map((answer) => answer.statusCode), unorderedEquals([201, 409]));
    expect(bodyOf(answers.firstWhere((answer) => answer.statusCode == 409))['code'], 'too_many_active_orders');
  });

  test('otkazivanje vraća rezervisanu zalihu', () async {
    final before = await stockOf('p7');
    final placed = await order('u-test-3', 'p7', 4);
    expect(placed.statusCode, 201);
    expect(await stockOf('p7'), before - 4);

    final cancelled = await post('/orders/${bodyOf(placed)['id']}/cancellation', 'u-test-3');

    expect(cancelled.statusCode, 200);
    expect(await stockOf('p7'), before);
  });

  test('proizvođač prihvata istu porudžbinu iz dva prozora: prolazi tačno jedan', () async {
    final placed = await order('u-test-4', 'p9', 1);
    final id = bodyOf(placed)['id'];

    final answers = await Future.wait([
      post('/orders/$id/status', 'pr-8', {'status': 'accepted'}),
      post('/orders/$id/status', 'pr-8', {'status': 'accepted'}),
    ]);

    expect(answers.map((answer) => answer.statusCode), unorderedEquals([200, 409]));
    expect(bodyOf(answers.firstWhere((answer) => answer.statusCode == 409))['code'], 'transition_not_allowed');
  });
}
