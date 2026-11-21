import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/secure_token_store.dart';
import 'server_address.dart';
import 'session_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // U pregledaču prijavu nosi httpOnly kolačić, pa se token ne čuva nigde.
  final api = ApiClient(
    baseUrl: serverAddress(),
    tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore(),
  );
  final shop = HttpShopRepository(api);
  final sessions = HttpSessionRepository(api);

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