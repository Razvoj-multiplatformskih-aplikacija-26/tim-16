import 'package:flutter/material.dart';

import 'router.dart';

class SvezkoBackofficeApp extends StatelessWidget {
  const SvezkoBackofficeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Svežko Backoffice',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF347A52)),
      useMaterial3: true,
    ),
    routerConfig: backofficeRouter,
  );
}
