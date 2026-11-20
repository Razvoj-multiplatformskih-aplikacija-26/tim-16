import 'json.dart';
import 'money.dart';
import 'wire_time.dart';

final class OrderStatusDto {
  const OrderStatusDto(this.code, {this.at, this.cancelledBy});

  factory OrderStatusDto.fromJson(JsonMap json) => OrderStatusDto(
    json.read<String>('code'),
    at: json.readOptionalTime('at'),
    cancelledBy: json.readOptional<String>('cancelledBy'),
  );

  static const pending = 'pending';
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const byBuyer = 'buyer';
  static const byProducer = 'producer';

  final String code;

  final DateTime? at;

  final String? cancelledBy;

  JsonMap toJson() => {
    'code': code,
    if (at case final at?) 'at': encodeTime(at),
    'cancelledBy': ?cancelledBy,
  };
}

final class OrderLineDto {
  const OrderLineDto({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderLineDto.fromJson(JsonMap json) => OrderLineDto(
    productId: json.read<String>('productId'),
    productName: json.read<String>('productName'),
    unitPrice: MoneyDto.fromJson(json.readObject('unitPrice')),
    quantity: json.read<int>('quantity'),
  );

  final String productId;

  final String productName;
  final MoneyDto unitPrice;
  final int quantity;

  JsonMap toJson() => {
    'productId': productId,
    'productName': productName,
    'unitPrice': unitPrice.toJson(),
    'quantity': quantity,
  };
}

final class OrderDto {
  const OrderDto({
    required this.id,
    required this.buyerId,
    required this.producerId,
    required this.status,
    required this.method,
    required this.createdAt,
    required this.lines,
    required this.total,
    this.address,
  });

  factory OrderDto.fromJson(JsonMap json) => OrderDto(
    id: json.read<String>('id'),
    buyerId: json.read<String>('buyerId'),
    producerId: json.read<String>('producerId'),
    status: OrderStatusDto.fromJson(json.readObject('status')),
    method: json.read<String>('method'),
    address: json.readOptional<String>('address'),
    createdAt: json.readTime('createdAt'),
    lines: json.readList('lines', OrderLineDto.fromJson),
    total: MoneyDto.fromJson(json.readObject('total')),
  );

  final String id;
  final String buyerId;
  final String producerId;
  final OrderStatusDto status;

  final String method;
  final String? address;
  final DateTime createdAt;
  final List<OrderLineDto> lines;

  final MoneyDto total;

  JsonMap toJson() => {
    'id': id,
    'buyerId': buyerId,
    'producerId': producerId,
    'status': status.toJson(),
    'method': method,
    'address': ?address,
    'createdAt': encodeTime(createdAt),
    'lines': [for (final line in lines) line.toJson()],
    'total': total.toJson(),
  };
}
