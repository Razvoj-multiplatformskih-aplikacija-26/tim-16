import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';

Future<void> main() async {
  final config = ServerConfig.fromEnvironment(serverEnvironment());
  final database = Pool<void>.withUrl(config.databaseUrl);
  await seedDemoPasswords(
    database,
    demoPassword: config.demoPassword ??
        (throw StateError('DEMO_PASSWORD nije podešen. Kopiraj .env.example u .env.')),
  );
  final store = ShopStore(database);
  final handlers = ShopHandlers(store: store, lineLimit: config.lineLimit);

  final server = RelicServer(
    () => IOAdapter.bind(InternetAddress(config.host), port: config.port),
  );

  final sessions = SessionHandlers(
    accounts: AccountStore(database),
    secret: config.jwtSecret,
    ttl: config.sessionTtl,
    secureCookie: config.secureCookie,
  );
  await server.mountAndStart(buildHandler(handlers, sessions, corsOrigins: config.corsOrigins));

  stdout.writeln('Svežko server na http://${config.host}:${config.port}');
  if (config.lineLimit case final limit?) {
    stdout.writeln('Novo pravilo: najviše $limit po stavci porudžbine');
  }

  await _stopSignal();
  await server.close();
  await database.close();
}

/// Čeka Ctrl+C (ili SIGTERM iz Dockera) da bi server i baza bili uredno zatvoreni.
Future<void> _stopSignal() async {
  final stop = Completer<void>();
  final subscriptions = [
    for (final signal in [
      ProcessSignal.sigint,
      if (!Platform.isWindows) ProcessSignal.sigterm,
    ])
      signal.watch().listen((_) => stop.isCompleted ? null : stop.complete()),
  ];
  await stop.future;
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
}
