// Prijava demo naloga za skripte u ovom folderu. Skripte se predstavljaju
// serveru isto kao aplikacije: korisničko ime i lozinka, pa token.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

final base = Uri.parse(Platform.environment['SERVER_URL'] ?? 'http://localhost:8080');
final demoPassword = Platform.environment['DEMO_PASSWORD'] ?? 'svezko-demo';

const demoLogins = {
  'u-buyer-1': 'kupac1',
  'u-buyer-2': 'kupac2',
  'pr-1': 'proizvodjac1',
  'pr-2': 'proizvodjac2',
  'pr-9': 'proizvodjac9',
};

final _tokens = <String, String>{};

Future<String> tokenOf(String userId) async {
  if (_tokens[userId] case final token?) return token;
  final login = demoLogins[userId] ?? (throw ArgumentError('$userId nema nalog za prijavu'));
  final response = await http.post(
    base.replace(path: '/sessions'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': login, 'password': demoPassword}),
  );
  if (response.statusCode != 201) {
    throw StateError('Prijava $login nije uspela: ${response.statusCode} ${response.body}');
  }
  return _tokens[userId] = (jsonDecode(response.body) as Map)['token'] as String;
}

Future<Map<String, String>> headersAs(String? userId) async => {
  'Content-Type': 'application/json',
  if (userId != null) 'Authorization': 'Bearer ${await tokenOf(userId)}',
};