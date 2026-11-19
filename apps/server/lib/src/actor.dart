import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'shop_store.dart';

/// PRIVREMENO (do stavke 4 KT2): ko poziva, server saznaje iz zaglavlja
/// `X-User-Id` i proverava da taj korisnik postoji u bazi. U stavci 4 ovo
/// zamenjuje prijava koju izdaje sam server, a klijent više ne bira ko je.
const actorHeader = 'X-User-Id';

Future<User?> actorOf(Request request, ShopStore store) async {
  final id = request.headers[actorHeader]?.firstOrNull?.trim();
  if (id == null || id.isEmpty) return null;
  return store.user(UserId(id));
}
