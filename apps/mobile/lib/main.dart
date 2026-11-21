import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:svezko_app/repository/mock_data.dart';
import 'data/secure_token_store.dart';
import 'server_address.dart';
import 'session_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const useFake = bool.fromEnvironment('FAKE');
  final ShopRepository shop;
  final SessionRepository sessions;
  if (useFake) {

    shop = FakeShopRepository();
    sessions = FakeSessionRepository(demoBuyer);
  } else {
    final api = ApiClient(baseUrl: serverAddress(), tokens: const SecureTokenStore());
    shop = HttpShopRepository(api);
    sessions = HttpSessionRepository(api);
  }
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ShopRepository>.value(value: shop),
        RepositoryProvider<SessionRepository>.value(value: sessions),
      ],
      child: BlocProvider(
        create: (_) => SessionBloc(sessions: sessions, admits: canUseMobileApp)..add(const SessionRestoreRequested()),
        child: const SessionGate(),
      ),
    ),
  );
}