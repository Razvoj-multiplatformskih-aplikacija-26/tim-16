// Demonstracija za odbranu: dva kupca u istom trenutku poručuju poslednji
// komad suvih smokava (p10). Server pušta tačno jednu porudžbinu.
//
//   dart run apps/server/tool/poslednji_komad.dart
//
// Skripta prvo, kao proizvođač pr-9, vrati zalihu na 1 komad, a na kraju
// otkaže pobedničku porudžbinu (da kupcu ne raste broj aktivnih porudžbina),
// pa se može pokretati više puta. Sa `--zadrzi` porudžbina ostaje.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

final base = Uri.parse(Platform.environment['SERVER_URL'] ?? 'http://localhost:8080');

Future<http.Response> post(String path, String user, Map<String, Object?> body) => http.post(
  base.replace(path: path),
  headers: {'Content-Type': 'application/json', 'X-User-Id': user},
  body: jsonEncode(body),
);

Future<http.Response> order(String buyer) => post('/orders', buyer, {
  'lines': [
    {'productId': 'p10', 'quantity': 1},
  ],
  'method': 'pickup',
});

Future<void> main(List<String> args) async {
  final reset = await post('/products/p10/stock', 'pr-9', {'stockUnits': 1});
  stdout.writeln('Zaliha p10 vraćena na 1 → ${reset.statusCode}\n');

  // Oba zahteva kreću pre nego što bilo koji dobije odgovor.
  final answers = await Future.wait([order('u-buyer-1'), order('u-buyer-2')]);

  for (final (buyer, answer) in [('u-buyer-1', answers[0]), ('u-buyer-2', answers[1])]) {
    stdout.writeln('$buyer → ${answer.statusCode}  ${answer.body}\n');
  }
  final product = await http.get(base.replace(path: '/products/p10'));
  stdout.writeln('Zaliha posle: ${(jsonDecode(product.body) as Map)['availableUnits']}');

  if (args.contains('--zadrzi')) return;
  for (final (buyer, answer) in [('u-buyer-1', answers[0]), ('u-buyer-2', answers[1])]) {
    if (answer.statusCode != 201) continue;
    final id = (jsonDecode(answer.body) as Map)['id'];
    final cancelled = await post('/orders/$id/cancellation', buyer, const {});
    stdout.writeln('Pobednička porudžbina $id otkazana → ${cancelled.statusCode}');
  }
}
