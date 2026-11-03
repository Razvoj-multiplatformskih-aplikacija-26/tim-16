import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  ProductCategory _category = ProductCategory.fruit;
  ProductUnit _unit = ProductUnit.kilogram;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<ShopBloc, ShopState>(
    listenWhen: (_, state) => state is ShopLoaded && state.feedback != null,
    listener: (context, state) {
      if (state is! ShopLoaded) return;
      switch (state.feedback) {
        case ProductAdded():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proizvod je dodat u ponudu.')),
          );
          context.go('/products');
        case RuleViolated(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_domainMessage(error))),
          );
        case ActionFailed():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Čuvanje nije uspelo. Pokušajte ponovo.')),
          );
        default:
          break;
      }
    },
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 720,
          child: Form(
            key: _formKey,
            child: ListView(children: [
              Row(children: [
                IconButton(tooltip: 'Nazad na proizvode', onPressed: () => context.go('/products'), icon: const Icon(Icons.arrow_back)),
                const SizedBox(width: 8),
                Text('Dodaj proizvod', style: Theme.of(context).textTheme.headlineMedium),
              ]),
              const SizedBox(height: 8),
              const Text('Proizvod će biti dodat na nalog trenutno prijavljenog proizvođača.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                maxLength: ProductName.max,
                decoration: const InputDecoration(labelText: 'Naziv proizvoda', border: OutlineInputBorder()),
                validator: (value) {
                  final parsed = ProductName.parse(value ?? '');
                  return parsed.errorOrNull == null ? null : 'Unesite naziv od 2 do ${ProductName.max} znakova.';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Opis', alignLabelWithHint: true, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProductCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategorija', border: OutlineInputBorder()),
                items: [for (final item in ProductCategory.values) DropdownMenuItem(value: item, child: Text(_categoryName(item)))],
                onChanged: (value) => setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProductUnit>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Prodajna jedinica', border: OutlineInputBorder()),
                items: [for (final item in ProductUnit.values) DropdownMenuItem(value: item, child: Text(_unitName(item)))],
                onChanged: (value) => setState(() => _unit = value ?? _unit),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cena po jedinici (RSD)', border: OutlineInputBorder()),
                validator: (value) => _integerError(value, min: Price.min, max: Price.max, label: 'Cena'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Početna zaliha (${_unitName(_unit)})', border: const OutlineInputBorder()),
                validator: (value) => _integerError(value, min: 0, max: Stock.max, label: 'Zaliha'),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj proizvod'),
                ),
              ),
            ]),
          ),
        ),
      ),
    ),
  );

  String? _integerError(String? raw, {required int min, required int max, required String label}) {
    final value = int.tryParse((raw ?? '').trim());
    if (value == null) return '$label mora biti ceo broj.';
    if (value < min || value > max) return '$label mora biti između $min i $max.';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ShopBloc>().add(AddProductEvent(
      name: _nameController.text,
      description: _descriptionController.text,
      category: _category,
      unit: _unit,
      priceDinars: int.parse(_priceController.text.trim()),
      stockUnits: int.parse(_stockController.text.trim()),
    ));
  }

  String _categoryName(ProductCategory value) => switch (value) {
    ProductCategory.fruit => 'Voće',
    ProductCategory.vegetables => 'Povrće',
    ProductCategory.dairy => 'Mlečni proizvodi',
    ProductCategory.honey => 'Med',
    ProductCategory.preserves => 'Prerađevine',
  };

  String _unitName(ProductUnit value) => switch (value) {
    ProductUnit.kilogram => 'kg',
    ProductUnit.piece => 'komad',
    ProductUnit.liter => 'litar',
    ProductUnit.jar => 'tegla',
  };

  String _domainMessage(DomainError error) => switch (error) {
    TextLengthInvalid(:final kind, :final min, :final max) when kind == TextKind.productName => 'Naziv mora imati između $min i $max znakova.',
    PriceOutOfRange(:final min, :final max) => 'Cena mora biti između $min i $max RSD.',
    StockOutOfRange(:final max) => 'Zaliha mora biti između 0 i $max.',
    NotAuthorized() => 'Nemate pravo da dodate proizvod.',
    _ => 'Podaci za proizvod nisu ispravni.',
  };
}
