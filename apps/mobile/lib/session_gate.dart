import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'screens/login_screen.dart';
import 'theme/theme.dart';

/// Bez prijave nema prodavnice: ShopBloc se pravi tek sa korisnikom iz prijave.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SessionBloc, SessionState>(
    builder: (context, session) => switch (session) {
      SignedIn(:final user) => BlocProvider(
        key: ValueKey(user.id),
        create: (context) =>
        ShopBloc(repository: context.read<ShopRepository>(), currentUser: user)..add(const LoadShopDataEvent()),
        child: const SvezkoApp(),
      ),
      SignedOut(:final reason) => MaterialApp(
        title: 'Svezko',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: LoginScreen(
          title: 'Svežko',
          roleNotAllowedMessage: 'Aplikacija je za kupce. Proizvođači koriste backoffice.',
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