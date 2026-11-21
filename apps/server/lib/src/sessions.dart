import 'package:contract/contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';
import 'package:relic/relic.dart' hide Result;

import 'account_store.dart';
import 'http.dart';
import 'passwords.dart';

final class AuthSession {
  const AuthSession({required this.user, required this.expiresAt});

  final User user;
  final DateTime expiresAt;
}

final currentSession = ContextProperty<AuthSession>('session');

const _signInRequired = ProblemDto(status: 401, code: ErrorCodes.signInRequired, title: 'Potrebna je prijava');
const _sessionExpired = ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Prijava je istekla');
const _invalidCredentials = ProblemDto(
  status: 401,
  code: ErrorCodes.invalidCredentials,
  title: 'Pogrešno korisničko ime ili lozinka',
);
const _algorithm = JWTAlgorithm.HS256;

final class SessionHandlers {
  SessionHandlers({
    required this.accounts,
    required String secret,
    required this.ttl,
    this.secureCookie = false,
  }) : _key = SecretKey(secret),
        _noAccountHash = hashPassword('no such account');

  final AccountStore accounts;
  final Duration ttl;
  final bool secureCookie;
  final SecretKey _key;

  final Future<String> _noAccountHash;

  Handler signedIn(Handler handler) => (Request request) async {
    final token = _tokenOf(request);
    if (token == null) return _unauthorized(_signInRequired);
    final session = _verify(token);
    if (session == null) return _unauthorized(_sessionExpired);
    currentSession[request] = session;
    return handler(request);
  };

  Future<Response> logIn(Request request) async {
    final body = LoginDto.fromJson(await readObject(request));
    final account = await accounts.account(body.username.trim());
    final matches = await verifyPassword(body.password, account?.passwordHash ?? await _noAccountHash);
    if (account == null || !matches) return _unauthorized(_invalidCredentials);
    final user = account.user;
    final token = JWT(
      {'name': user.fullName, 'role': user.role.name},
      subject: user.id.value,
    ).sign(_key, algorithm: _algorithm, expiresIn: ttl);
    final expiresAt = _verify(token)!.expiresAt;
    final dto = SessionDto(user: userToDto(user), expiresAt: expiresAt, token: body.cookie ? null : token);
    final response = json(201, dto.toJson());
    if (!body.cookie) return response;
    return response.copyWith(
      headers: response.headers.transform(
            (headers) => headers.setCookie = _cookie(token, maxAge: ttl.inSeconds),
      ),
    );
  }

  Future<Response> current(Request request) async {
    final session = currentSession.get(request);
    return json(200, SessionDto(user: userToDto(session.user), expiresAt: session.expiresAt).toJson());
  }

  Future<Response> logOut(Request request) async =>
      Response.noContent(headers: Headers.build((headers) => headers.setCookie = _cookie('', maxAge: 0)));

  SetCookieHeader _cookie(String value, {required int maxAge}) => SetCookieHeader(
    name: ApiCookies.session,
    value: value,
    path: Uri.parse('/'),
    maxAge: maxAge,
    httpOnly: true,
    secure: secureCookie,
    sameSite: SameSite.lax,
  );

  Response _unauthorized(ProblemDto problem) {
    final response = problemResponse(problem);
    return response.copyWith(
      headers: response.headers.transform((headers) => headers['WWW-Authenticate'] = ['Bearer']),
    );
  }

  AuthSession? _verify(String token) {
    try {
      // Prihvata se samo algoritam koji server koristi (ne `none` ni drugi).
      if (JWT.decode(token).header?['alg'] != _algorithm.name) return null;
      return switch (JWT.verify(token, _key).payload) {
        {
        'sub': final String id,
        'name': final String name,
        'role': final String role,
        'exp': final int exp,
        } =>
            AuthSession(
              user: User(id: UserId(id), fullName: name, role: UserRole.values.byName(role)),
              expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
            ),
        _ => null,
      };
    } on JWTException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  String? _tokenOf(Request request) => switch (request.headers.authorization) {
    BearerAuthorizationHeader(:final token) => token,
    _ => request.headers.cookie?.getCookie(ApiCookies.session)?.value,
  };
}