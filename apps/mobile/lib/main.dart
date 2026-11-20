import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'repository/mock_data.dart';

const serverUrl = String.fromEnvironment('SERVER_URL');

void main() {
  // Lažna implementacija porta. Za drugu implementaciju (odbrana) zameni
  // sa SecondFakeShopRepository() iz mock_dataV2.dart.
  final ShopRepository repository = serverUrl.isEmpty
      ? FakeShopRepository()
      : HttpShopRepository(baseUrl: Uri.parse(serverUrl), user: demoBuyer);

  runApp(
    // Repozitorijum je dostupan i ekranu (dugme za izazivanje greške).
    RepositoryProvider<ShopRepository>.value(
      value: repository,
      child: BlocProvider<ShopBloc>(
        create: (_) => ShopBloc(repository: repository, currentUser: demoBuyer)
          ..add(const LoadShopDataEvent()),
        child: const SvezkoApp(),
      ),
    ),
  );
}
