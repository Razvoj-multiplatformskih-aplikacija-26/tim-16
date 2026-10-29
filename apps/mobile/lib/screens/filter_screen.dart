// lib/screens/filter_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/app_button.dart';

// Klasa koja čuva odabrane filtere
class FilterOptions {
  final double maxPrice;
  final bool onlyAvailable;

  FilterOptions({this.maxPrice = 5000, this.onlyAvailable = false});
}

class FilterScreen extends StatefulWidget {
  final FilterOptions? initialFilters;

  const FilterScreen({super.key, this.initialFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late double _maxPrice;
  late bool _onlyAvailable;

  @override
  void initState() {
    super.initState();
    // Učitavamo proslijeđene filtere ili postavljamo podrazumijevane vrijednosti
    _maxPrice = widget.initialFilters?.maxPrice ?? 5000;
    _onlyAvailable = widget.initialFilters?.onlyAvailable ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filteri'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(), // Zatvara bez čuvanja
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maksimalna cijena: ${_maxPrice.toStringAsFixed(0)} RSD',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Widget za odabir cijene
            Slider(
              value: _maxPrice,
              min: 0,
              max: 5000,
              divisions: 50, // Koraci po 100 RSD
              activeColor: colorScheme.primary,
              label: '${_maxPrice.toStringAsFixed(0)} RSD',
              onChanged: (value) {
                setState(() {
                  _maxPrice = value;
                });
              },
            ),

            const SizedBox(height: 30),

            // Widget za odabir dostupnosti
            SwitchListTile(
              title: const Text(
                'Samo dostupni proizvodi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Sakrij proizvode kojih trenutno nema na stanju'),
              value: _onlyAvailable,
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _onlyAvailable = value;
                });
              },
            ),

            const Spacer(),

            // Dugme koje čuva podatke i vraća se nazad
            AppButton(
              text: 'Primijeni filtere',
              onPressed: () {
                final newFilters = FilterOptions(
                  maxPrice: _maxPrice,
                  onlyAvailable: _onlyAvailable,
                );
                // Vraćamo odabrane filtere nazad na HomeScreen
                context.pop(newFilters);
              },
            ),
          ],
        ),
      ),
    );
  }
}