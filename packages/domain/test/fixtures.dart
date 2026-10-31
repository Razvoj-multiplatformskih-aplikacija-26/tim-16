import 'package:domain/domain.dart';

final DateTime t0 = DateTime.utc(2026, 10, 22, 12);

const User buyer = User(
  id: UserId('buyer-1'),
  fullName: 'Marko Kupac',
  role: UserRole.buyer,
);
const User otherBuyer = User(
  id: UserId('buyer-2'),
  fullName: 'Ana Kupac',
  role: UserRole.buyer,
);
const User producer = User(
  id: UserId('prod-1'),
  fullName: 'Jelena Proizvođač',
  role: UserRole.producer,
);
const User otherProducer = User(
  id: UserId('prod-2'),
  fullName: 'Petar Proizvođač',
  role: UserRole.producer,
);

Quantity qty(int n) => Quantity.parse(n, available: 1000).valueOrNull!;

Product makeProduct({
  String id = 'p1',
  User owner = producer,
  int stock = 10,
  int price = 200,
  bool published = true,
}) =>
    Product(
      id: ProductId(id),
      producerId: owner.id,
      name: ProductName.parse('Domaće jabuke').valueOrNull!,
      description: 'Sveže sa imanja',
      category: ProductCategory.fruit,
      unit: ProductUnit.kilogram,
      price: Price.parse(price).valueOrNull!,
      stock: Stock.parse(stock).valueOrNull!,
      published: published,
    );

OrderLine makeLine({
  String productId = 'p1',
  int quantity = 2,
  int price = 200,
}) =>
    OrderLine(
      productId: ProductId(productId),
      productName: 'Domaće jabuke',
      unitPrice: Price.parse(price).valueOrNull!,
      quantity: qty(quantity),
    );

Order makeOrder({
  String id = 'o1',
  User by = buyer,
  User seller = producer,
  OrderStatus status = const Pending(),
  List<OrderLine>? lines,
  DateTime? createdAt,
}) =>
    Order(
      id: OrderId(id),
      buyerId: by.id,
      producerId: seller.id,
      lines: lines ?? [makeLine()],
      status: status,
      createdAt: createdAt ?? t0,
      method: DeliveryMethod.pickup,
    );
