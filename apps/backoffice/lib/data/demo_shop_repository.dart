import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

/// Lokalni adapter za pokretanje kostura dok se ne uvede serverski API.
/// Početni podaci su usklađeni sa mock podacima iz mobilne aplikacije.
class DemoShopRepository implements ShopRepository, ProductManagementRepository {
  final List<User> _producers = [
    _producer('pr-1', 'Bojan Matić'),
    _producer('pr-2', 'Gazdinstvo Petrović'),
    _producer('pr-3', 'Farma koza'),
    _producer('pr-4', 'Farma koka'),
    _producer('pr-5', 'Mlekara M'),
    _producer('pr-6', 'Gazdinstvo Ilić'),
    _producer('pr-7', 'Voćar doo'),
    _producer('pr-8', 'Baka Nada'),
    _producer('pr-9', 'Primorje'),
  ];

  late final List<Product> _products = _seedProducts();
  late final List<Order> _orders = _seedOrders(_products);

  @override
  Future<List<User>> loadProducers() async => List.unmodifiable(_producers);

  @override
  Future<List<Product>> loadProducts() async => List.unmodifiable(_products);

  @override
  Future<List<Order>> loadOrders() async => List.unmodifiable(_orders);

  @override
  Future<void> saveOrder(Order order) async {
    final index = _orders.indexWhere((existing) => existing.id == order.id);
    if (index == -1) {
      _orders.insert(0, order);
    } else {
      _orders[index] = order;
    }
  }

  @override
  Future<void> deleteProduct(ProductId productId) async {
    _products.removeWhere((product) => product.id == productId);
  }

  @override
  Future<void> addProduct(Product product) async {
    _products.insert(0, product);
  }

  static User _producer(String id, String name) =>
      User(id: UserId(id), fullName: name, role: UserRole.producer);

  List<Product> _seedProducts() {
    final producers = {for (final producer in _producers) producer.id.value: producer};
    const imageBase = 'https://commons.wikimedia.org/wiki/Special:FilePath';

    Product product({
      required String id,
      required String producerId,
      required String name,
      required String description,
      required ProductCategory category,
      required ProductUnit unit,
      required int price,
      required int stock,
      required String image,
    }) => Product(
      id: ProductId(id),
      producerId: producers[producerId]!.id,
      name: ProductName.parse(name).valueOrNull!,
      description: description,
      category: category,
      unit: unit,
      price: Price.parse(price).valueOrNull!,
      stock: Stock.parse(stock).valueOrNull!,
      imageUrl: '$imageBase/$image?width=500',
    );

    return [
      product(id: 'p1', producerId: 'pr-1', name: 'Domaće maline', description: 'Sveže maline iz Arilja.', category: ProductCategory.fruit, unit: ProductUnit.kilogram, price: 150, stock: 10, image: 'Raspberries_(Rubus_idaeus).jpg'),
      product(id: 'p2', producerId: 'pr-2', name: 'Med', description: 'Prirodni livadski med.', category: ProductCategory.honey, unit: ProductUnit.jar, price: 800, stock: 5, image: 'Runny_hunny.jpg'),
      product(id: 'p3', producerId: 'pr-3', name: 'Sir kozji', description: 'Stari kozji sir.', category: ProductCategory.dairy, unit: ProductUnit.kilogram, price: 1200, stock: 2, image: 'Goat_Cheese.jpg'),
      product(id: 'p4', producerId: 'pr-4', name: 'Domaća jaja', description: 'Slobodan uzgoj.', category: ProductCategory.dairy, unit: ProductUnit.piece, price: 20, stock: 30, image: 'Eggs_in_a_cardboard_box.jpg'),
      product(id: 'p5', producerId: 'pr-5', name: 'Kravlji sir', description: 'Mladi domaći kravlji sir.', category: ProductCategory.dairy, unit: ProductUnit.kilogram, price: 800, stock: 5, image: 'Feta_Cheese.jpg'),
      product(id: 'p6', producerId: 'pr-6', name: 'Krompir', description: 'Beli krompir, odličan za pečenje.', category: ProductCategory.vegetables, unit: ProductUnit.kilogram, price: 100, stock: 50, image: 'Potato_and_halves.jpg'),
      product(id: 'p7', producerId: 'pr-7', name: 'Sok od jabuke', description: '100% prirodni sok bez šećera.', category: ProductCategory.preserves, unit: ProductUnit.liter, price: 300, stock: 15, image: 'Apple_juice.jpg'),
      product(id: 'p8', producerId: 'pr-1', name: 'Orah očišćen', description: 'Sveže očišćeni orasi.', category: ProductCategory.fruit, unit: ProductUnit.kilogram, price: 1500, stock: 4, image: 'Walnut.jpg'),
      product(id: 'p9', producerId: 'pr-8', name: 'Džem od šljiva', description: 'Domaći džem spreman po tradicionalnom receptu.', category: ProductCategory.preserves, unit: ProductUnit.jar, price: 450, stock: 8, image: 'Damson_jam.jpg'),
      product(id: 'p10', producerId: 'pr-9', name: 'Suve smokve', description: 'Slatke suve smokve iz uvoza, pakovane lokalno.', category: ProductCategory.fruit, unit: ProductUnit.kilogram, price: 600, stock: 0, image: 'Dried_Figs.jpg'),
    ];
  }

  List<Order> _seedOrders(List<Product> products) {
    final byId = {for (final product in products) product.id.value: product};
    final buyerId = UserId('u-buyer-1');

    Order order({
      required String id,
      required List<(String, int)> items,
      required OrderStatus status,
      required DateTime createdAt,
      DeliveryMethod method = DeliveryMethod.pickup,
      String? address,
    }) {
      final orderedProducts = items.map((item) => byId[item.$1]!).toList();
      return Order(
        id: OrderId(id),
        buyerId: buyerId,
        producerId: orderedProducts.first.producerId,
        lines: [
          for (var i = 0; i < items.length; i++)
            OrderLine(
              productId: orderedProducts[i].id,
              productName: orderedProducts[i].name.value,
              unitPrice: orderedProducts[i].price,
              quantity: Quantity.parse(items[i].$2, available: items[i].$2).valueOrNull!,
            ),
        ],
        status: status,
        createdAt: createdAt,
        method: method,
        address: address == null ? null : DeliveryAddress.parse(address).valueOrNull!,
      );
    }

    final orders = [
      order(id: 'o-1001', items: [('p1', 2)], status: const Pending(), createdAt: DateTime(2026, 11, 2, 18, 30)),
      order(id: 'o-1002', items: [('p2', 1)], status: Accepted(acceptedAt: DateTime(2026, 11, 2, 13)), createdAt: DateTime(2026, 11, 2, 12), method: DeliveryMethod.delivery, address: 'Knez Mihailova 12, Beograd'),
      order(id: 'o-1003', items: [('p4', 12)], status: const Preparing(), createdAt: DateTime(2026, 11, 1, 9, 15)),
      order(id: 'o-1004', items: [('p3', 1)], status: Shipped(shippedAt: DateTime(2026, 11, 1, 8)), createdAt: DateTime(2026, 10, 31, 17, 45), method: DeliveryMethod.delivery, address: 'Bulevar kralja Aleksandra 45, Beograd'),
      order(id: 'o-1005', items: [('p1', 3), ('p8', 1)], status: const Delivered(), createdAt: DateTime(2026, 10, 27, 10), method: DeliveryMethod.delivery, address: 'Takovska 7, Beograd'),
      order(id: 'o-1006', items: [('p6', 10)], status: const Delivered(), createdAt: DateTime(2026, 10, 24, 15, 20)),
      order(id: 'o-1007', items: [('p7', 4)], status: const Delivered(), createdAt: DateTime(2026, 10, 20, 11, 5), method: DeliveryMethod.delivery, address: 'Resavska 30, Beograd'),
      order(id: 'o-1008', items: [('p5', 1)], status: const Cancelled(CancelReason.byBuyer), createdAt: DateTime(2026, 10, 29, 19)),
      order(id: 'o-1009', items: [('p9', 1)], status: const Cancelled(CancelReason.byBuyer), createdAt: DateTime(2026, 10, 22, 8, 40)),
      order(id: 'o-1010', items: [('p10', 2)], status: const Cancelled(CancelReason.byProducer), createdAt: DateTime(2026, 10, 18, 14, 10)),
    ];
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }
}
