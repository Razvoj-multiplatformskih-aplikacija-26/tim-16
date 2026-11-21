import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'screens/login_screen.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  static final _theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF347A52)),
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) => BlocBuilder<SessionBloc, SessionState>(
    builder: (context, session) => switch (session) {
      SignedIn(:final user) => BlocProvider(
        key: ValueKey(user.id),
        create: (context) =>
        ShopBloc(repository: context.read<ShopRepository>(), currentUser: user)..add(const LoadShopDataEvent()),
        child: const SvezkoBackofficeApp(),
      ),
      SignedOut(:final reason) => MaterialApp(
        title: 'Svežko Backoffice',
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: LoginScreen(
          title: 'Svežko Backoffice',
          roleNotAllowedMessage: 'Backoffice je za proizvođače. Kupci koriste mobilnu aplikaciju.',
          reason: reason,
        ),
      ),
      SessionUnknown() => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    },
  );
}