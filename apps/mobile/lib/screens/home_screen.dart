import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../repository/mock_data.dart';
import '../text/labels.dart';
import '../theme/colors.dart';
import '../widgets/error_view.dart';
import '../widgets/product_card.dart';
import 'filter_screen.dart';

/// Šta test-meni radi: greška pri učitavanju ili pri sledećem čuvanju.
enum _DebugAction { load, save }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  FilterOptions _currentFilters = FilterOptions();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDebugAction(_DebugAction action) {
    final repository = context.read<ShopRepository>();
    if (repository is FakeShopRepository) repository.forceError();
    if (action == _DebugAction.load) {
      context.read<ShopBloc>().add(const LoadShopDataEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: const Text('Svezko'),
        actions: [
          PopupMenuButton<_DebugAction>(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            tooltip: 'Izazovi grešku (test)',
            onSelected: _onDebugAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _DebugAction.load,
                child: Text('Greška pri učitavanju'),
              ),
              PopupMenuItem(
                value: _DebugAction.save,
                child: Text('Greška pri sledećem čuvanju'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filteri',
            onPressed: () async {
              final result = await context.push<FilterOptions>(
                '/filters',
                extra: _currentFilters,
              );
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Pretraži proizvode ili proizvođače',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) => switch (state) {
                ShopLoading() =>
                const Center(child: CircularProgressIndicator()),
                ShopError(:final message) => ErrorView(message: message),
                ShopEmpty() =>
                const Center(child: Text('Nema dostupnih proizvoda.')),
                final ShopLoaded loaded => _ProductList(
                  state: loaded,
                  query: _searchQuery.trim().toLowerCase(),
                  filters: _currentFilters,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.state,
    required this.query,
    required this.filters,
  });

  final ShopLoaded state;
  final String query;
  final FilterOptions filters;

  @override
  Widget build(BuildContext context) {
    final products = state.products.where((product) {
      final producer = state.producerName(product.producerId).toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.value.toLowerCase().contains(query) ||
          producer.contains(query);
      final matchesPrice = product.price.dinars <= filters.maxPrice;
      final matchesAvailability = !filters.onlyAvailable || product.isAvailable;
      return matchesSearch && matchesPrice && matchesAvailability;
    }).toList();

    if (products.isEmpty) {
      return const Center(
        child: Text('Nema proizvoda koji odgovaraju pretrazi i filterima.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          name: product.name.value,
          producer: state.producerName(product.producerId),
          price: product.price.dinars.toDouble(),
          unit: product.unit.label,
          imageUrl: product.imageUrl,
          isAvailable: product.isAvailable,
          onAddToCart: product.isAvailable
              ? () => context.read<ShopBloc>().add(
            CreateOrderEvent(productId: product.id, quantity: 1),
          )
              : null,
          onTap: () => context.push('/products/${product.id.value}'),
        );
      },
    );
  }
}