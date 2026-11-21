import 'package:postgres/postgres.dart';

import 'passwords.dart';

/// Nalozima iz migracije (kolona `login`) upisuje heš lozinke iz
/// `DEMO_PASSWORD`. Već upisane lozinke ne dira.
Future<void> seedDemoPasswords(Pool<void> database, {required String demoPassword}) async {
  final rows = await database.execute(
    'SELECT id FROM users WHERE login IS NOT NULL AND password_hash IS NULL',
  );
  for (final row in rows) {
    await database.execute(
      Sql.named('UPDATE users SET password_hash = @hash WHERE id = @id'),
      parameters: {'id': row[0]! as String, 'hash': await hashPassword(demoPassword)},
    );
  }
}