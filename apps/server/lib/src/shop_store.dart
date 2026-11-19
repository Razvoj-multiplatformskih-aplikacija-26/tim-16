import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

/// Čitanje i upis podataka u PostgreSQL. Svaki red iz baze se pretvara u
/// domenski model kroz iste `parse` funkcije koje koriste i klijenti, pa
/// server radi sa istim tipovima i pravilima kao mobilna aplikacija i backoffice.
final class ShopStore {
  const ShopStore(this._database);

  final Session _database;

  Future<User?> user(UserId id) async {
    final rows = await _database.execute(
      Sql.named('SELECT id, full_name, role FROM users WHERE id = @id'),
      parameters: {'id': id.value},
    );
    return rows.isEmpty ? null : userFromRow(rows.single);
  }

  Future<List<User>> producers() async {
    final rows = await _database.execute(
      "SELECT id, full_name, role FROM users WHERE role = 'producer' ORDER BY full_name",
    );
    return [for (final row in rows) userFromRow(row)];
  }

  /// Javna ponuda: samo objavljeni proizvodi.
  Future<List<Product>> publishedProducts() =>
      _products(where: 'published', parameters: const {});

  Future<List<Product>> productsOf(UserId producerId) =>
      _products(where: 'producer_id = @producer', parameters: {'producer': producerId.value});

  Future<Product?> product(ProductId id) async {
    final found = await _products(where: 'id = @id', parameters: {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  Future<List<Product>> _products({
    required String where,
    required Map<String, Object?> parameters,
  }) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id, producer_id, name, description, category, unit,
               price_dinars, stock_units, published, image_url
        FROM products
        WHERE $where
        ORDER BY created_at, id
      '''),
      parameters: parameters,
    );
    return [for (final row in rows) productFromRow(row.toColumnMap())];
  }

  Future<List<Order>> ordersOfBuyer(UserId buyerId) =>
      _orders(where: 'o.buyer_id = @user', parameters: {'user': buyerId.value});

  Future<List<Order>> ordersOfProducer(UserId producerId) =>
      _orders(where: 'o.producer_id = @user', parameters: {'user': producerId.value});

  Future<Order?> order(OrderId id) async {
    final found = await _orders(where: 'o.id = @id', parameters: {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  Future<List<Order>> _orders({
    required String where,
    required Map<String, Object?> parameters,
  }) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT o.id, o.buyer_id, o.producer_id, o.status, o.status_at,
               o.cancel_reason, o.method, o.address, o.created_at,
               l.product_id, l.product_name, l.unit_price_dinars, l.quantity
        FROM orders o
        JOIN order_lines l ON l.order_id = o.id
        WHERE $where
        ORDER BY o.created_at DESC, o.id, l.position
      '''),
      parameters: parameters,
    );
    return ordersFromRows([for (final row in rows) row.toColumnMap()]);
  }
}

User userFromRow(ResultRow row) => User(
  id: UserId(row[0]! as String),
  fullName: row[1]! as String,
  role: UserRole.values.byName(row[2]! as String),
);

Product productFromRow(Map<String, dynamic> row) => Product(
  id: ProductId(row['id'] as String),
  producerId: UserId(row['producer_id'] as String),
  name: ProductName.parse(row['name'] as String).valueOrNull!,
  description: row['description'] as String,
  category: ProductCategory.values.byName(row['category'] as String),
  unit: ProductUnit.values.byName(row['unit'] as String),
  price: Price.parse(row['price_dinars'] as int).valueOrNull!,
  stock: Stock.parse(row['stock_units'] as int).valueOrNull!,
  published: row['published'] as bool,
  imageUrl: row['image_url'] as String,
);

/// Spaja redove `orders JOIN order_lines` u porudžbine, čuvajući redosled.
List<Order> ordersFromRows(List<Map<String, dynamic>> rows) {
  final heads = <String, Map<String, dynamic>>{};
  final lines = <String, List<OrderLine>>{};
  for (final row in rows) {
    final id = row['id'] as String;
    heads.putIfAbsent(id, () => row);
    final quantity = row['quantity'] as int;
    (lines[id] ??= []).add(
      OrderLine(
        productId: ProductId(row['product_id'] as String),
        productName: row['product_name'] as String,
        unitPrice: Price.parse(row['unit_price_dinars'] as int).valueOrNull!,
        // Količina je već prošla proveru zalihe kada je porudžbina napravljena.
        quantity: Quantity.parse(quantity, available: quantity).valueOrNull!,
      ),
    );
  }
  return [
    for (final MapEntry(key: id, value: row) in heads.entries)
      Order(
        id: OrderId(id),
        buyerId: UserId(row['buyer_id'] as String),
        producerId: UserId(row['producer_id'] as String),
        lines: lines[id]!,
        status: orderStatusFromColumns(
          status: row['status'] as String,
          at: row['status_at'] as DateTime?,
          cancelReason: row['cancel_reason'] as String?,
        ),
        createdAt: (row['created_at'] as DateTime).toUtc(),
        method: DeliveryMethod.values.byName(row['method'] as String),
        address: switch (row['address']) {
          final String text => DeliveryAddress.parse(text).valueOrNull,
          _ => null,
        },
      ),
  ];
}

OrderStatus orderStatusFromColumns({
  required String status,
  DateTime? at,
  String? cancelReason,
}) => switch (status) {
  'pending' => const Pending(),
  'accepted' => Accepted(acceptedAt: at!.toUtc()),
  'preparing' => const Preparing(),
  'shipped' => Shipped(shippedAt: at!.toUtc()),
  'delivered' => const Delivered(),
  'cancelled' => Cancelled(switch (cancelReason) {
    'by_producer' => CancelReason.byProducer,
    _ => CancelReason.byBuyer,
  }),
  _ => throw StateError('Nepoznato stanje porudžbine u bazi: $status'),
};

/// Kolone `status`, `status_at` i `cancel_reason` za dato stanje.
({String status, DateTime? at, String? cancelReason}) orderStatusColumns(
  OrderStatus status,
) => switch (status) {
  Pending() => (status: 'pending', at: null, cancelReason: null),
  Accepted(:final acceptedAt) => (status: 'accepted', at: acceptedAt, cancelReason: null),
  Preparing() => (status: 'preparing', at: null, cancelReason: null),
  Shipped(:final shippedAt) => (status: 'shipped', at: shippedAt, cancelReason: null),
  Delivered() => (status: 'delivered', at: null, cancelReason: null),
  Cancelled(:final reason) => (
    status: 'cancelled',
    at: null,
    cancelReason: switch (reason) {
      CancelReason.byBuyer => 'by_buyer',
      CancelReason.byProducer => 'by_producer',
    },
  ),
};
