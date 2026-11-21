import 'dart:convert';


final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.corsOrigins,
    required this.jwtSecret,
    this.sessionTtl = const Duration(hours: 8),
    this.secureCookie = false,
    this.demoPassword,
    this.lineLimit,
  });

  factory ServerConfig.fromEnvironment(Map<String, String> environment) => ServerConfig(
    host: environment['HOST'] ?? '127.0.0.1',
    port: int.parse(environment['PORT'] ?? '8080'),
    databaseUrl:
    environment['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL nije podešen. Kopiraj .env.example u .env u korenu repozitorijuma.')),
    corsOrigins: [
      for (final origin in (environment['CORS_ORIGINS'] ?? 'http://localhost:8081').split(','))
        if (origin.trim().isNotEmpty) origin.trim(),
    ],
    sessionTtl: Duration(minutes: int.parse(environment['SESSION_TTL_MINUTES'] ?? '480')),
    secureCookie: environment['COOKIE_SECURE'] == 'true',
    demoPassword: environment['DEMO_PASSWORD'],
    jwtSecret: _jwtSecret(environment['JWT_SECRET']),
    lineLimit: int.tryParse(environment['NOVO_PRAVILO_NAJVISE_PO_STAVCI'] ?? ''),
  );

  final String host;
  final int port;
  final String databaseUrl;

  /// Poreklo backoffice-a u pregledaču (npr. http://localhost:8081).
  final List<String> corsOrigins;

  /// Koliko važi prijava (SESSION_TTL_MINUTES).
  final Duration sessionTtl;

  /// Kolačić samo preko HTTPS-a; lokalno je false.
  final bool secureCookie;

  /// Lozinka demo naloga, heširana pri pokretanju.
  final String? demoPassword;

  /// Tajna kojom server potpisuje prijave; zna je samo server.
  final String jwtSecret;

  final int? lineLimit;
}

String _jwtSecret(String? secret) => switch (secret) {
  null => throw StateError('JWT_SECRET nije podešen. Kopiraj .env.example u .env u korenu repozitorijuma.'),
  final secret when utf8.encode(secret).length < 32 => throw StateError('JWT_SECRET mora imati bar 32 bajta.'),
  final secret => secret,
};