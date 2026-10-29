// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/product_card.dart';
import 'package:svezko_app/repository/mock_data.dart';
import 'filter_screen.dart'; // DODAN IMPORT DA BISMO KORISTILI FilterOptions

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Ovdje čuvamo trenutno aktivne filtere
  FilterOptions _currentFilters = FilterOptions();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = FakeDatabase.products;

    // Proširena logika filtriranja (tekst + cijena + dostupnost)
    final filteredProducts = allProducts.where((product) {
      final query = searchQuery.toLowerCase();
      final nameMatches = product.name.toLowerCase().contains(query);
      final producerMatches = product.producer.toLowerCase().contains(query);
      final searchMatches = nameMatches || producerMatches;

      // Provjera iz FilterScreen-a
      final priceMatches = product.price <= _currentFilters.maxPrice;
      final availabilityMatches = !_currentFilters.onlyAvailable || product.availableQuantity > 0;

      return searchMatches && priceMatches && availabilityMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: const Text('Svezko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filteri',
            onPressed: () async {
              // Otvaramo FilterScreen i čekamo da korisnik klikne "Primijeni"
              final result = await context.push<FilterOptions>(
                '/filters',
                extra: _currentFilters, // Šaljemo mu trenutne filtere da podesi klizače
              );

              // Ako je korisnik sačuvao filtere (nije kliknuo X na vrhu)
              if (result != null) {
                setState(() {
                  _currentFilters = result; // Osvježavamo ekran sa novim filterima
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Traži proizvode ili proizvođače...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
              child: Text('Nema proizvoda koji odgovaraju pretrazi i filterima.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                return ProductCard(
                  name: product.name,
                  producer: product.producer,
                  price: product.price,
                  unit: product.unit,
                  imageUrl: product.imageUrl,
                  isAvailable: product.availableQuantity > 0, // Prosljeđujemo dostupnost kartici
                  onAddToCart: product.availableQuantity > 0
                      ? () {
                    FakeDatabase.addOrder(product, 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proizvod je dodan u narudžbe!')),
                    );
                  }
                      : null, // Gumb će biti neaktivan ako nema na stanju
                  onTap: () {
                    context.push('/item-detail', extra: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}