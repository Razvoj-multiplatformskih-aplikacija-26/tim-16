import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';
import 'shop_repository.dart';

import 'api_client.dart';
import 'http_shop_repository.dart';
import 'session_repository.dart';

final class HttpSessionRepository implements SessionRepository {
  const HttpSessionRepository(this._api);

  final ApiClient _api;

  @override
  Future<User?> logIn({required String username, required String password}) async {
    final login = LoginDto(username: username.trim(), password: password, cookie: _api.keepsSessionInCookie);
    final response = await _api.post(ApiPaths.sessions, body: login.toJson());
    if (response.statusCode == 401) return null;
    if (response.statusCode != 201) throw rejectionOf(response.statusCode, response.bodyBytes);
    final session = SessionDto.fromJson(asObject(jsonDecode(utf8.decode(response.bodyBytes))));
    if (session.token case final token?) await _api.tokens.write(token);
    return userFromDto(session.user);
  }

  @override
  Future<User?> current() async {
    if (!_api.keepsSessionInCookie && await _api.tokens.read() == null) return null;
    try {
      final response = await _api.get(ApiPaths.currentSession);
      if (response.statusCode != 200) throw rejectionOf(response.statusCode, response.bodyBytes);
      return userFromDto(SessionDto.fromJson(asObject(jsonDecode(utf8.decode(response.bodyBytes)))).user);
    } on SessionEnded {
      await _api.tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await _api.delete(ApiPaths.currentSession);
    } on Exception {
      // Odjava na uređaju važi i kada server nije dostupan.
    } finally {
      await _api.tokens.clear();
    }
  }

  @override
  Stream<void> get expirations => _api.expirations;
}