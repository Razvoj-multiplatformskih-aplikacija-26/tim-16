import 'package:flutter/material.dart';
import 'package:svezko_app/route.dart';
import 'theme/theme.dart';
import 'screens/home_screen.dart';

class SvezkoApp extends StatelessWidget {
const SvezkoApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp.router(
    title: 'Svezko',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    routerConfig: appRouter,
  );
}
}