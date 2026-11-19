import 'dart:convert';
import 'dart:io';

import 'package:relic/relic.dart';

/// JSON odgovor sa zadatim statusom.
Response json(int status, Object? body) => Response(
  status,
  body: Body.fromString(jsonEncode(body), mimeType: MimeType.json),
);

/// Greška koju server vraća u jednom obliku za sve slučajeve:
/// `{"status": 400, "code": "bad_request", "title": "...", "details": {...}}`.
/// Klijent prepoznaje grešku po `code`, a poruku za korisnika pravi sam.
Response problem({
  required int status,
  required String code,
  required String title,
  Map<String, Object?> details = const {},
}) => json(status, {
  'status': status,
  'code': code,
  'title': title,
  if (details.isNotEmpty) 'details': details,
});

const maxBodyBytes = 16 * 1024;

final class UnsupportedMediaType implements Exception {
  const UnsupportedMediaType();
}

/// Telo zahteva kao JSON objekat; sve ostalo je 400 ili 415.
Future<Map<String, Object?>> readObject(Request request) async {
  if (request.mimeType != MimeType.json) throw const UnsupportedMediaType();
  return switch (jsonDecode(
    await request.readAsString(maxLength: maxBodyBytes),
  )) {
    final Map<String, Object?> object => object,
    _ => throw const FormatException('Očekivan je JSON objekat'),
  };
}

/// Pretvara izuzetke u odgovore sa istim oblikom greške, da server nikada
/// ne vrati stack trace klijentu.
Middleware handleErrors() =>
    (Handler next) => (Request request) async {
      try {
        return await next(request);
      } on FormatException catch (error) {
        return problem(status: 400, code: 'bad_request', title: error.message);
      } on UnsupportedMediaType {
        return problem(
          status: 415,
          code: 'unsupported_media_type',
          title: 'Očekivan je application/json',
        );
      } on MaxBodySizeExceeded {
        return problem(
          status: 413,
          code: 'payload_too_large',
          title: 'Telo zahteva je preveliko',
        );
      } catch (error, stackTrace) {
        stderr.writeln(
          '${request.method} ${request.url.path}: $error\n$stackTrace',
        );
        return problem(
          status: 500,
          code: 'server_error',
          title: 'Greška na serveru',
        );
      }
    };
