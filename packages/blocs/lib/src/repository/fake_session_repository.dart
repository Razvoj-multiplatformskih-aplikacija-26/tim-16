import 'package:domain/domain.dart';

import 'session_repository.dart';

/// Lažna prijava za rad bez servera (--dart-define=FAKE=true). Korisnik je
/// već prijavljen; svaka lozinka prolazi. Pravila uloga ostaju ista,
/// jer ih proverava SessionBloc (admits), a ne repozitorijum.
final class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository(this.user);

  final User user;
  var _signedIn = true;

  @override
  Future<User?> logIn({required String username, required String password}) async {
    _signedIn = true;
    return user;
  }

  @override
  Future<User?> current() async => _signedIn ? user : null;

  @override
  Future<void> logOut() async => _signedIn = false;

  @override
  Stream<void> get expirations => const Stream.empty();
}