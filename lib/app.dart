import 'package:flutter/material.dart';
import 'theme/theme.dart';

class SvezkoApp extends StatelessWidget {
const SvezkoApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Svežko',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const Scaffold(
      body: Center(
        child: Text('Dobro došli u Svežko!'),
      ),
    ),
  );
}
}