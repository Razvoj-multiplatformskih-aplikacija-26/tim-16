import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

import 'codes.dart';

MoneyDto moneyOf(int dinars) => MoneyDto(dinars);

int dinarsOf(MoneyDto money) {
  if (money.currency != MoneyDto.rsd) {
    throw WireFormatException('Nepodržana valuta "${money.currency}"');
  }
  return money.amount;
}

ProductDto productToDto(Product product, {bool ownerView = false}) => ProductDto(
  id: product.id.value,
  producerId: product.producerId.value,
  name: product.name.value,
  description: product.description,
  category: categoryCode(product.category),
  unit: unitCode(product.unit),
  price: moneyOf(product.price.dinars),
  availableUnits: product.stock.units,
  imageUrl: product.imageUrl,
  published: ownerView ? product.published : null,
);

Product productFromDto(ProductDto dto) => Product(
  id: ProductId(dto.id),
  producerId: UserId(dto.producerId),
  name: _valid(ProductName.parse(dto.name), 'name'),
  description: dto.description,
  category: categoryFromCode(dto.category),
  unit: unitFromCode(dto.unit),
  price: _valid(Price.parse(dinarsOf(dto.price)), 'price'),
  stock: _valid(Stock.parse(dto.availableUnits), 'availableUnits'),
  published: dto.published ?? true,
  imageUrl: dto.imageUrl,
);

T _valid<T>(Result<T> result, String field) => switch (result) {
  Success(:final value) => value,
  Failure(:final error) => throw WireFormatException('Polje "$field" krši pravilo: $error'),
};
