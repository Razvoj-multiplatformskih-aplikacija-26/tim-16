import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'data/demo_shop_repository.dart';

const serverUrl = String.fromEnvironment('SERVER_URL');

void main() {
  const producer = User(
    id: UserId('pr-1'),
    fullName: 'Demo proizvođač',
    role: UserRole.producer,
  );
  final ShopRepository repository = serverUrl.isEmpty
      ? DemoShopRepository()
      : HttpShopRepository(baseUrl: Uri.parse(serverUrl), user: producer);

  runApp(
    RepositoryProvider<ShopRepository>.value(
      value: repository,
      child: BlocProvider(
        create: (_) =>
            ShopBloc(repository: repository, currentUser: producer)
              ..add(const LoadShopDataEvent()),
        child: const SvezkoBackofficeApp(),
      ),
    ),
  );
}
