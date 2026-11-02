import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/blocs.dart';
import 'repository/mock_data.dart'; // Prilagodi putanju ako ti se fajl zove drugačije
import 'app.dart';

void main() {
  // 1. Kreiramo instancu lažnog repozitorijuma
  final fakeRepository = FakeShopRepository();

  runApp(
    // 2. Omogućavamo pristupačnost repozitorijumu (potrebno za dugme za grešku na odbrani)
    RepositoryProvider<ShopRepository>.value(
      value: fakeRepository,
      child: MultiBlocProvider(
        providers: [
          // 3. Kreiramo ShopBloc i odmah mu šaljemo događaj za učitavanje početnih podataka
          BlocProvider(
            create: (context) => ShopBloc(repository: fakeRepository)
              ..add(LoadShopDataEvent()),
          ),
        ],
        child: const SvezkoApp(),
      ),
    ),
  );
}