import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/demo_shop_repository.dart';
import 'data/secure_token_store.dart';
import 'server_address.dart';
import 'session_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const useFake = bool.fromEnvironment('FAKE');
  final ShopRepository shop;
  final SessionRepository sessions;
  if (useFake) {
    shop = DemoShopRepository();
    sessions = FakeSessionRepository(
      const User(id: UserId('pr-1'), fullName: 'Demo proizvođač', role: UserRole.producer),
    );
  } else {
    // U pregledaču prijavu nosi httpOnly kolačić, pa se token ne čuva nigde.
    final api = ApiClient(
      baseUrl: serverAddress(),
      tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore(),
    );
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
        create: (_) => SessionBloc(sessions: sessions, admits: canUseBackoffice)..add(const SessionRestoreRequested()),
        child: const SessionGate(),
      ),
    ),
  );
}