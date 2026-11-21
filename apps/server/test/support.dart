import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:server/server.dart';

/// Tajna samo za testove (bar 32 bajta, kao u ServerConfig).
const testSecret = 'test-only-secret-0123456789abcdef-0123';

/// Poreklo backoffice-a u pregledaču, kao u .env.example.
const testOrigin = 'http://localhost:8081';

Future<void> applyMigrations(Session session) async {
  final files = Directory('migrations').listSync().whereType<File>().where((file) => file.path.endsWith('.sql')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final text = file.readAsStringSync();
    final up = text.substring(text.indexOf('-- migrate:up'), text.indexOf('-- migrate:down'));
    await session.execute(up, queryMode: QueryMode.simple);
  }
}

SessionHandlers testSessions(Pool<void> database) =>
    SessionHandlers(accounts: AccountStore(database), secret: testSecret, ttl: const Duration(hours: 1));

/// Token kakav bi server izdao posle prijave. Uloga se čita iz id-a
/// (pr-… je proizvođač, ostali su kupci), kao u početnim podacima.
String tokenFor(String userId, {Duration validFor = const Duration(hours: 1), String secret = testSecret}) => JWT(
  {'name': 'Test $userId', 'role': userId.startsWith('pr-') ? 'producer' : 'buyer'},
  subject: userId,
).sign(SecretKey(secret), algorithm: JWTAlgorithm.HS256, expiresIn: validFor);

Map<String, String> authAs(String? userId) =>
    userId == null ? const {} : {'Authorization': 'Bearer ${tokenFor(userId)}'};