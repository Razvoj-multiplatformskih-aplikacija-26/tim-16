/// Podešavanja servera. Vrednosti dolaze iz okruženja ili iz `.env` u korenu
/// repozitorijuma (vidi `.env.example`).
final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.databaseUrl,
    this.lineLimit,
  });

  factory ServerConfig.fromEnvironment(Map<String, String> environment) =>
      ServerConfig(
        host: environment['HOST'] ?? '127.0.0.1',
        port: int.parse(environment['PORT'] ?? '8080'),
        databaseUrl:
            environment['DATABASE_URL'] ??
            (throw StateError(
              'DATABASE_URL nije podešen. Kopiraj .env.example u .env u korenu repozitorijuma.',
            )),
        lineLimit: int.tryParse(environment['NOVO_PRAVILO_NAJVISE_PO_STAVCI'] ?? ''),
      );

  final String host;
  final int port;
  final String databaseUrl;

  final int? lineLimit;
}
