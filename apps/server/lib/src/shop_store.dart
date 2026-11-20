import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'paging.dart';

typedef ProductRow = ({Product product, DateTime createdAt});

/// Čitanje i upis podataka u PostgreSQL. Svaki red iz baze se pretvara u
/// domenski model kroz iste `parse` funkcije koje koriste i klijenti, pa
/// server radi sa istim tipovima i pravilima kao mobilna aplikacija i backoffice.
final class ShopStore {
  ShopStore(Pool<void> pool) : _database = pool, _pool = pool;

  ShopStore._inTransaction(TxSession transaction)
    : _database = transaction,
      _pool = null;

  final Session _database;
  final Pool<void>? _pool;

  /// Izvršava [work] u jednoj transakciji: ili se upiše sve, ili ništa.
  Future<T> transaction<T>(Future<T> Function(ShopStore store) work) {
    final pool = _pool;
    if (pool == null) return work(this);
    return pool.runTx((transaction) => work(ShopStore._inTransaction(transaction)));
  }

  /// Zaključava red korisnika do kraja transakcije. Tako se dve porudžbine
  /// istog kupca (npr. sa telefona i iz pregledača) obrađuju jedna za drugom,
  /// pa pravilo o najviše 5 aktivnih porudžbina važi i kada stignu istovremeno.
  Future<void> lockUser(UserId id) async {
    await _database.execute(
      Sql.named('SELECT 1 FROM users WHERE id = @id FOR UPDATE'),
      parameters: {'id': id.value},
    );
  }

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

  /// Sa [forUpdate] red ostaje zaključan do kraja transakcije: drugi zahtev
  /// koji menja isti proizvod čeka i posle toga čita već izmenjenu zalihu.
  Future<Product?> product(ProductId id, {bool forUpdate = false}) async {
    final found = await _products(
      where: 'id = @id',
      parameters: {'id': id.value},
      forUpdate: forUpdate,
    );
    return found.isEmpty ? null : found.single;
  }

  Future<List<Product>> productsByIds(Iterable<ProductId> ids, {bool forUpdate = false}) => _products(
    where: 'id = ANY(@ids)',
    parameters: {
      'ids': TypedValue(Type.textArray, [for (final id in ids) id.value]),
    },
    forUpdate: forUpdate,
  );

  Future<List<Product>> _products({
    required String where,
    required Map<String, Object?> parameters,
    bool forUpdate = false,
  }) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id, producer_id, name, description, category, unit,
               price_dinars, stock_units, published, image_url
        FROM products
        WHERE $where
        ${forUpdate ? 'ORDER BY id FOR UPDATE' : 'ORDER BY created_at, id'}
      '''),
      parameters: parameters,
    );
    return [for (final row in rows) productFromRow(row.toColumnMap())];
  }

  Future<List<ProductRow>> publishedProductsPage({required int limit, Position? after}) =>
      _productPage(where: 'published', parameters: const {}, limit: limit, after: after);

  Future<List<ProductRow>> productsOfPage(UserId producerId, {required int limit, Position? after}) =>
      _productPage(
        where: 'producer_id = @producer',
        parameters: {'producer': producerId.value},
        limit: limit,
        after: after,
      );

  Future<List<ProductRow>> _productPage({
    required String where,
    required Map<String, Object?> parameters,
    required int limit,
    Position? after,
  }) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id, producer_id, name, description, category, unit,
               price_dinars, stock_units, published, image_url, created_at
        FROM products
        WHERE $where
        ${after == null ? '' : 'AND (created_at, id) > (@afterAt, @afterId)'}
        ORDER BY created_at, id
        LIMIT @limit
      '''),
      parameters: {...parameters, ..._pageParameters(limit, after)},
    );
    return [
      for (final columns in rows.map((row) => row.toColumnMap()))
        (product: productFromRow(columns), createdAt: (columns['created_at'] as DateTime).toUtc()),
    ];
  }

  Future<List<Order>> ordersPage(User actor, {required int limit, Position? after}) async {
    final participant = switch (actor.role) {
      UserRole.buyer => 'buyer_id',
      UserRole.producer => 'producer_id',
    };
    final rows = await _database.execute(
      Sql.named('''
        WITH page AS (
          SELECT id FROM orders
          WHERE $participant = @user
          ${after == null ? '' : 'AND (created_at < @afterAt OR (created_at = @afterAt AND id > @afterId))'}
          ORDER BY created_at DESC, id
          LIMIT @limit
        )
        SELECT o.id, o.buyer_id, o.producer_id, o.status, o.status_at,
               o.cancel_reason, o.method, o.address, o.created_at,
               l.product_id, l.product_name, l.unit_price_dinars, l.quantity
        FROM page
        JOIN orders o ON o.id = page.id
        JOIN order_lines l ON l.order_id = o.id
        ORDER BY o.created_at DESC, o.id, l.position
      '''),
      parameters: {'user': actor.id.value, ..._pageParameters(limit, after)},
    );
    return ordersFromRows([for (final row in rows) row.toColumnMap()]);
  }

  Map<String, Object?> _pageParameters(int limit, Position? after) => {
    'limit': TypedValue(Type.integer, limit),
    if (after != null) ...{
      'afterAt': TypedValue(Type.timestampTz, after.at),
      'afterId': TypedValue(Type.text, after.id),
    },
  };

  Future<List<Order>> ordersOfBuyer(UserId buyerId) =>
      _orders(where: 'o.buyer_id = @user', parameters: {'user': buyerId.value});

  Future<List<Order>> ordersOfProducer(UserId producerId) =>
      _orders(where: 'o.producer_id = @user', parameters: {'user': producerId.value});

  Future<Order?> order(OrderId id, {bool forUpdate = false}) async {
    final found = await _orders(
      where: 'o.id = @id',
      parameters: {'id': id.value},
      forUpdate: forUpdate,
    );
    return found.isEmpty ? null : found.single;
  }

  Future<List<Order>> _orders({
    required String where,
    required Map<String, Object?> parameters,
    bool forUpdate = false,
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
        ${forUpdate ? 'FOR UPDATE OF o' : ''}
      '''),
      parameters: parameters,
    );
    return ordersFromRows([for (final row in rows) row.toColumnMap()]);
  }

  // Upisi. Pozivaju se tek kada domenska pravila dozvole izmenu.

  Future<void> insertOrder(Order order) async {
    final columns = orderStatusColumns(order.status);
    await _database.execute(
      Sql.named('''
        INSERT INTO orders (id, buyer_id, producer_id, status, status_at, cancel_reason, method, address, created_at)
        VALUES (@id, @buyer, @producer, @status, @statusAt, @reason, @method, @address, @created)
      '''),
      parameters: {
        'id': order.id.value,
        'buyer': order.buyerId.value,
        'producer': order.producerId.value,
        'status': columns.status,
        'statusAt': columns.at?.toUtc(),
        'reason': columns.cancelReason,
        'method': order.method.name,
        'address': order.address?.value,
        'created': order.createdAt.toUtc(),
      },
    );
    for (final (position, line) in order.lines.indexed) {
      await _database.execute(
        Sql.named('''
          INSERT INTO order_lines (order_id, position, product_id, product_name, unit_price_dinars, quantity)
          VALUES (@order, @position, @product, @name, @price, @quantity)
        '''),
        parameters: {
          'order': order.id.value,
          'position': position,
          'product': line.productId.value,
          'name': line.productName,
          'price': line.unitPrice.dinars,
          'quantity': line.quantity.value,
        },
      );
    }
  }

  Future<void> updateOrderStatus(Order order) async {
    final columns = orderStatusColumns(order.status);
    await _database.execute(
      Sql.named('''
        UPDATE orders SET status = @status, status_at = @statusAt, cancel_reason = @reason
        WHERE id = @id
      '''),
      parameters: {
        'id': order.id.value,
        'status': columns.status,
        'statusAt': columns.at?.toUtc(),
        'reason': columns.cancelReason,
      },
    );
  }

  Future<void> insertProduct(Product product) async {
    await _database.execute(
      Sql.named('''
        INSERT INTO products (id, producer_id, name, description, category, unit, price_dinars, stock_units, published, image_url)
        VALUES (@id, @producer, @name, @description, @category, @unit, @price, @stock, @published, @image)
      '''),
      parameters: {
        'id': product.id.value,
        'producer': product.producerId.value,
        'name': product.name.value,
        'description': product.description,
        'category': product.category.name,
        'unit': product.unit.name,
        'price': product.price.dinars,
        'stock': product.stock.units,
        'published': product.published,
        'image': product.imageUrl,
      },
    );
  }

  /// Upisuje cenu, zalihu i objavljenost proizvoda.
  Future<void> updateProduct(Product product) async {
    await _database.execute(
      Sql.named('''
        UPDATE products SET price_dinars = @price, stock_units = @stock, published = @published
        WHERE id = @id
      '''),
      parameters: {
        'id': product.id.value,
        'price': product.price.dinars,
        'stock': product.stock.units,
        'published': product.published,
      },
    );
  }

  Future<void> deleteProduct(ProductId id) async {
    await _database.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': id.value},
    );
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
