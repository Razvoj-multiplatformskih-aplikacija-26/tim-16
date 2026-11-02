import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:blocs/blocs.dart'; // TVOJ PAKET
import '../repository/mock_data.dart';
import '../theme/colors.dart';
import '../widgets/product_card.dart';
import 'filter_screen.dart';
// import 'package:svezko_app/repository/fake_shop_repository.dart'; // Trebaće ti da pristupiš forceError()

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  FilterOptions _currentFilters = FilterOptions();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: const Text('Svezko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            tooltip: 'Izazovi grešku (Test)',
            onPressed: () {
              final repo = context.read<ShopRepository>() as FakeShopRepository;
              repo.forceError();
              context.read<ShopBloc>().add(LoadShopDataEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filteri',
            onPressed: () async {
              final result = await context.push<FilterOptions>('/filters', extra: _currentFilters);
              if (result != null) {
                setState(() => _currentFilters = result);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                if (state is ShopLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ShopError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ShopBloc>().add(LoadShopDataEvent());
                          },
                          child: const Text('Pokušaj ponovo'),
                        )
                      ],
                    ),
                  );
                }

                if (state is ShopEmpty) {
                  return const Center(child: Text('Nema dostupnih proizvoda u bazi.'));
                }
                if (state is ShopLoaded) {
                  final allProducts = state.products;

                  final filteredProducts = allProducts.where((product) {
                    final query = searchQuery.toLowerCase();
                    final searchMatches = product.name.toLowerCase().contains(query) || product.producer.toLowerCase().contains(query);
                    final priceMatches = product.price <= _currentFilters.maxPrice;
                    final availabilityMatches = !_currentFilters.onlyAvailable || product.availableQuantity > 0;
                    return searchMatches && priceMatches && availabilityMatches;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('Nema proizvoda koji odgovaraju filterima.'));
                  }

                  return ListView.builder(
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
                        isAvailable: product.availableQuantity > 0,
                        onAddToCart: product.availableQuantity > 0 ? () {
                          context.read<ShopBloc>().add(CreateOrderEvent(product, 1));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proizvod je dodan u narudžbe!')),
                          );
                        } : null,
                        onTap: () => context.push('/item-detail', extra: product),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}