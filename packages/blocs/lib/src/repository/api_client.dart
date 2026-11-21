import 'dart:async';
import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:http/http.dart' as http;

import 'platform_client.dart';
import 'shop_repository.dart';
import 'token_store.dart';

final class ApiClient {
  ApiClient({
    required this.baseUrl,
    TokenStore? tokens,
    http.Client? httpClient,
    this.keepsSessionInCookie = platformKeepsSessionInCookie,
    this.timeout = const Duration(seconds: 10),

}):tokens = tokens ?? MemoryTokenStore(),
  _http=httpClient??platformHttpClient();

  final Uri baseUrl;
  final TokenStore tokens;
  final bool keepsSessionInCookie;
  final Duration timeout;
  final http.Client _http;
  final _expirations = StreamController<void>.broadcast();

  Stream<void>get expirations => _expirations.stream;

  Future<http.Response>get(String path,{Map<String, String>? query}) => _send('GET', path, query: query);

  Future<http.Response> post(String path, {JsonMap? body}) => _send('POST', path, body: body);

  Future<http.Response> delete(String path) => _send('DELETE', path);

  Future<http.Response> _send(String method, String path, {Map<String, String>? query, JsonMap? body}) async {
    final request = http.Request(
      method,
      baseUrl.replace(path: path, queryParameters: query == null || query.isEmpty ? null : query),
    )..headers['Accept'] = 'application/json';
    if (!keepsSessionInCookie) {
      if (await tokens.read() case final token?) request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await _http.send(request).then(http.Response.fromStream).timeout(timeout);
    } on http.ClientException catch (error) {
      throw RepositoryUnavailable('Mreža: ${error.message}');
    } on TimeoutException {
      throw RepositoryUnavailable('Server ne odgovara');
    }
    if (response.statusCode == 401 && _sessionEnded(response)) {
      _expirations.add(null);
      throw const SessionEnded();
    }
    return response;
  }

  bool _sessionEnded(http.Response response) {
    try {
      final code = ProblemDto.fromJson(asObject(jsonDecode(utf8.decode(response.bodyBytes)))).code;
      return code == ErrorCodes.sessionExpired || code == ErrorCodes.signInRequired;
    } on FormatException {
      return false;
    }
  }

}