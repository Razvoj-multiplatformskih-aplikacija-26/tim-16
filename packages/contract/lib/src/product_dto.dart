import 'json.dart';
import 'money.dart';

final class ProductDto {
  const ProductDto({
    required this.id,
    required this.producerId,
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.price,
    required this.availableUnits,
    required this.imageUrl,
    this.published,
  });

  factory ProductDto.fromJson(JsonMap json) => ProductDto(
    id: json.read<String>('id'),
    producerId: json.read<String>('producerId'),
    name: json.read<String>('name'),
    description: json.readOptional<String>('description') ?? '',
    category: json.read<String>('category'),
    unit: json.read<String>('unit'),
    price: MoneyDto.fromJson(json.readObject('price')),
    availableUnits: json.read<int>('availableUnits'),
    imageUrl: json.readOptional<String>('imageUrl') ?? '',
    published: json.readOptional<bool>('published'),
  );

  final String id;
  final String producerId;
  final String name;
  final String description;
  final String category;
  final String unit;
  final MoneyDto price;
  final int availableUnits;
  final String imageUrl;

  final bool? published;

  JsonMap toJson() => {
    'id': id,
    'producerId': producerId,
    'name': name,
    'description': description,
    'category': category,
    'unit': unit,
    'price': price.toJson(),
    'availableUnits': availableUnits,
    'imageUrl': imageUrl,
    'published': ?published,
  };
}
