import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

final class Account {
  const Account({required this.user, required this.passwordHash});

  final User user;
  final String passwordHash;
}

final class AccountStore {
  const AccountStore(this._database);

  final Pool<void> _database;

  Future<Account?> account(String login) async {
    final rows = await _database.execute(
      Sql.named(
        'SELECT id, full_name, role, password_hash FROM users '
            'WHERE login = @login AND password_hash IS NOT NULL',
      ),
      parameters: {'login': login},
    );
    if (rows.isEmpty) return null;
    final [id, fullName, role, hash] = rows.single;
    return Account(
      user: User(
        id: UserId(id! as String),
        fullName: fullName! as String,
        role: UserRole.values.byName(role! as String),
      ),
      passwordHash: hash! as String,
    );
  }
}