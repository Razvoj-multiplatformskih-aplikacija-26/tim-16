import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const buyer = User(id: UserId('u-buyer-1'), fullName: 'Marko', role: UserRole.buyer);
const producer = User(id: UserId('pr-1'), fullName: 'Bojan', role: UserRole.producer);

final class FakeSessions implements SessionRepository {
  FakeSessions([this.saved]);

  User? saved;
  var loggedOut = false;
  final expirationsController = StreamController<void>.broadcast();

  @override
  Future<User?> current() async => saved;

  @override
  Future<User?> logIn({required String username, required String password}) async => saved;

  @override
  Future<void> logOut() async => loggedOut = true;

  @override
  Stream<void> get expirations => expirationsController.stream;
}

void main() {
  blocTest<SessionBloc, SessionState>(
    'sačuvana prijava kupca važi u mobilnoj aplikaciji',
    build: () => SessionBloc(sessions: FakeSessions(buyer), admits: canUseMobileApp),
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedIn(buyer)],
  );

  test('kupac u backoffice-u: odjava i razlog roleNotAllowed', () async {
    final sessions = FakeSessions(buyer);
    final bloc = SessionBloc(sessions: sessions, admits: canUseBackoffice)..add(const SessionStarted(buyer));
    await expectLater(bloc.stream, emits(const SignedOut(reason: SignOutReason.roleNotAllowed)));
    expect(sessions.loggedOut, isTrue);
    await bloc.close();
  });

  test('istek prijave vraća na prijavu sa razlogom expired', () async {
    final sessions = FakeSessions(producer);
    final bloc = SessionBloc(sessions: sessions, admits: canUseBackoffice)..add(const SessionStarted(producer));
    await expectLater(bloc.stream, emits(const SignedIn(producer)));
    sessions.expirationsController.add(null);
    await expectLater(bloc.stream, emits(const SignedOut(reason: SignOutReason.expired)));
    await bloc.close();
  });

  blocTest<SessionBloc, SessionState>(
    'odjava',
    build: () => SessionBloc(sessions: FakeSessions(producer), admits: canUseBackoffice),
    seed: () => const SignedIn(producer),
    act: (bloc) => bloc.add(const SessionLogOutRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.loggedOut)],
  );
}