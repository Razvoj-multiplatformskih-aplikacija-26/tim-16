import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PagePlaceholder(
    title: 'Pregled poslovanja',
    description: 'Ovde će biti sažetak ponude i porudžbina.',
  );
}

class _PagePlaceholder extends StatelessWidget {
  const _PagePlaceholder({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description),
      ],
    ),
  );
}
