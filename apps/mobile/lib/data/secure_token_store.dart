import 'package:blocs/blocs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token prijave u bezbednom skladištu platforme: Keychain (iOS, macOS),
/// Keystore (Android), Credential Manager (Windows), libsecret (Linux).
/// Lozinka se na uređaju ne čuva, samo token.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore([
    // Data protection keychain traži potpisanu aplikaciju; login keychain radi i bez potpisa.
    this._storage = const FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false)),
  ]);

  static const _key = 'svezko_session';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}