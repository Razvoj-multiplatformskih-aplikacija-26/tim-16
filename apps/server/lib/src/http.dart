import 'dart:convert';
import 'dart:io';

import 'package:contract/contract.dart';
import 'package:relic/relic.dart';

/// JSON odgovor sa zadatim statusom.
Response json(int status, Object? body) => Response(
  status,
  body: Body.fromString(jsonEncode(body), mimeType: MimeType.json),
);

/// Greška koju server vraća u jednom obliku za sve slučajeve:
/// `{"status": 400, "code": "bad_request", "title": "...", "details": {...}}`.
/// Klijent prepoznaje grešku po `code`, a poruku za korisnika pravi sam.
Response problemResponse(ProblemDto problem) => json(problem.status, problem.toJson());

Response problem({required int status, required String code, required String title}) =>
    problemResponse(ProblemDto(status: status, code: code, title: title));

const maxBodyBytes = 16 * 1024;

final class UnsupportedMediaType implements Exception {
  const UnsupportedMediaType();
}

/// Telo zahteva kao JSON objekat; sve ostalo je 400 ili 415.
Future<JsonMap> readObject(Request request) async {
  if (request.mimeType != MimeType.json) throw const UnsupportedMediaType();
  return asObject(jsonDecode(await request.readAsString(maxLength: maxBodyBytes)));
}

/// Pretvara izuzetke u odgovore sa istim oblikom greške, da server nikada
/// ne vrati stack trace klijentu.
Middleware handleErrors() =>
    (Handler next) => (Request request) async {
      try {
        return await next(request);
      } on FormatException catch (error) {
        return problem(status: 400, code: ErrorCodes.badRequest, title: error.message);
      } on UnsupportedMediaType {
        return problem(
          status: 415,
          code: ErrorCodes.unsupportedMediaType,
          title: 'Očekivan je application/json',
        );
      } on MaxBodySizeExceeded {
        return problem(
          status: 413,
          code: ErrorCodes.payloadTooLarge,
          title: 'Telo zahteva je preveliko',
        );
      } catch (error, stackTrace) {
        stderr.writeln(
          '${request.method} ${request.url.path}: $error\n$stackTrace',
        );
        return problem(
          status: 500,
          code: ErrorCodes.serverError,
          title: 'Greška na serveru',
        );
      }
    };
