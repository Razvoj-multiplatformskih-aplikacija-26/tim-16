// Šalje serveru pozive mimo aplikacije koji krše pravila i ispisuje odgovor.
// Nijedan od njih ne sme da prođe, a svaki vraća kôd greške domenskog pravila.
//
//   dart run apps/server/tool/pozivi_mimo_aplikacije.dart
//
// Isto se može poslati i curl-om (Git Bash), na primer:
//   curl -i -X POST http://localhost:8080/products/p1/price \
//     -H "Content-Type: application/json" -H "X-User-Id: pr-1" \
//     -d '{"priceDinars": 0}'
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

final base = Uri.parse(Platform.environment['SERVER_URL'] ?? 'http://localhost:8080');

Future<void> main() async {
  await call(
    'Količina 0',
    'POST', '/orders', user: 'u-buyer-1',
    body: {'lines': [{'productId': 'p1', 'quantity': 0}], 'method': 'pickup'},
  );
  await call(
    'Više nego što ima na stanju',
    'POST', '/orders', user: 'u-buyer-1',
    body: {'lines': [{'productId': 'p3', 'quantity': 99}], 'method': 'pickup'},
  );
  await call(
    'Isporuka bez adrese',
    'POST', '/orders', user: 'u-buyer-1',
    body: {'lines': [{'productId': 'p1', 'quantity': 1}], 'method': 'delivery'},
  );
  await call(
    'Kupac pokušava da prihvati porudžbinu',
    'POST', '/orders/o-1001/status', user: 'u-buyer-1',
    body: {'status': 'accepted'},
  );
  await call(
    'Isporučena porudžbina nazad u prihvaćenu',
    'POST', '/orders/o-1005/status', user: 'pr-1',
    body: {'status': 'accepted'},
  );
  await call(
    'Otkazivanje poslate porudžbine',
    'POST', '/orders/o-1004/cancellation', user: 'u-buyer-1',
  );
  await call(
    'Kupac otkazuje tuđu porudžbinu',
    'POST', '/orders/o-1007/cancellation', user: 'u-buyer-1',
  );
  await call(
    'Cena van opsega',
    'POST', '/products/p1/price', user: 'pr-1',
    body: {'priceDinars': 0},
  );
  await call(
    'Proizvođač menja cenu tuđeg proizvoda',
    'POST', '/products/p1/price', user: 'pr-2',
    body: {'priceDinars': 200},
  );
  await call(
    'Negativna zaliha',
    'POST', '/products/p1/stock', user: 'pr-1',
    body: {'stockUnits': -5},
  );
  await call('Bez korisnika', 'GET', '/orders');
}

Future<void> call(
  String title,
  String method,
  String path, {
  String? user,
  Map<String, Object?>? body,
}) async {
  final request = http.Request(method, base.replace(path: path))
    ..headers.addAll({'Content-Type': 'application/json', if (user != null) 'X-User-Id': user});
  if (body != null) request.body = jsonEncode(body);
  final response = await http.Response.fromStream(await request.send());
  stdout
    ..writeln('— $title')
    ..writeln('  $method $path  →  ${response.statusCode}  ${response.body}')
    ..writeln();
}
