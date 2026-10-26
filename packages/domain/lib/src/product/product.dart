import 'package:domain/src/product/price.dart';
import 'package:domain/src/product/product_name.dart';
import 'package:domain/src/product/stock.dart';
import 'package:equatable/equatable.dart';

import '../identifiers.dart';

enum ProductCategory {fruit,vegetables,dairy,honey,preserves}

enum ProductUnit {kilogram,piece,liter,jar}

final class Product extends Equatable{
  const Product({
    required this.id,
    required this.producerId,
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.price,
    required this.stock,
    this.published = true,
});
  final ProductId id;
  final UserId producerId;
  final ProductName name;
  final String description;
  final ProductCategory category;
  final ProductUnit unit;
  final Price price;
  final Stock stock;

  final bool published;

  bool get isAvailable => published&&stock.units >0;

  Product copyWith({Price? price, Stock? stock, bool? published}) => Product(
    id: id,
    producerId: producerId,
    name: name,
    description: description,
    category: category,
    unit: unit,
    price: price ?? this.price,
    stock: stock ?? this.stock,
    published: published ?? this.published,
  );

  @override
  // TODO: implement props
  List<Object?> get props => [
    id,
    producerId,
    name,
    description,
    category,
    unit,
    price,
    stock,
    published,
  ];
}