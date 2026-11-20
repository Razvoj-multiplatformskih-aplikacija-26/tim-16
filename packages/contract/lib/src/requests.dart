import 'json.dart';
import 'money.dart';

final class PlaceOrderRequest {
  const PlaceOrderRequest({required this.lines, required this.method, this.address});

  factory PlaceOrderRequest.fromJson(JsonMap json) => PlaceOrderRequest(
    lines: json.readList('lines', OrderLineRequest.fromJson),
    method: json.read<String>('method'),
    address: json.readOptional<String>('address'),
  );

  final List<OrderLineRequest> lines;

  final String method;
  final String? address;

  JsonMap toJson() => {
    'lines': [for (final line in lines) line.toJson()],
    'method': method,
    'address': ?address,
  };
}

final class OrderLineRequest {
  const OrderLineRequest({required this.productId, required this.quantity});

  factory OrderLineRequest.fromJson(JsonMap json) => OrderLineRequest(
    productId: json.read<String>('productId'),
    quantity: json.read<int>('quantity'),
  );

  final String productId;
  final int quantity;

  JsonMap toJson() => {'productId': productId, 'quantity': quantity};
}

final class ChangeStatusRequest {
  const ChangeStatusRequest(this.status);

  factory ChangeStatusRequest.fromJson(JsonMap json) =>
      ChangeStatusRequest(json.read<String>('status'));

  final String status;

  JsonMap toJson() => {'status': status};
}

final class CreateProductRequest {
  const CreateProductRequest({
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.price,
    required this.stockUnits,
  });

  factory CreateProductRequest.fromJson(JsonMap json) => CreateProductRequest(
    name: json.read<String>('name'),
    description: json.readOptional<String>('description') ?? '',
    category: json.read<String>('category'),
    unit: json.read<String>('unit'),
    price: MoneyDto.fromJson(json.readObject('price')),
    stockUnits: json.read<int>('stockUnits'),
  );

  final String name;
  final String description;
  final String category;
  final String unit;
  final MoneyDto price;
  final int stockUnits;

  JsonMap toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'unit': unit,
    'price': price.toJson(),
    'stockUnits': stockUnits,
  };
}

final class ChangePriceRequest {
  const ChangePriceRequest(this.price);

  factory ChangePriceRequest.fromJson(JsonMap json) =>
      ChangePriceRequest(MoneyDto.fromJson(json.readObject('price')));

  final MoneyDto price;

  JsonMap toJson() => {'price': price.toJson()};
}

final class ChangeStockRequest {
  const ChangeStockRequest(this.stockUnits);

  factory ChangeStockRequest.fromJson(JsonMap json) =>
      ChangeStockRequest(json.read<int>('stockUnits'));

  final int stockUnits;

  JsonMap toJson() => {'stockUnits': stockUnits};
}
