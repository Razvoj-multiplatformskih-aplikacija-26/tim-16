import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

const demoBuyer = User(
  id:UserId('u-buyer-1'),
  fullName: 'Marko Petrovic',
  role:UserRole.buyer,
);

User _producer(String id, String name)=>
    User(id:UserId(id),fullName:name,role:UserRole.producer);

final _bojan = _producer('pr-1', 'Bojan Matić');
final _petrovic = _producer('pr-2', 'Gazdinstvo Petrović');
final _farmaKoza = _producer('pr-3', 'Farma koza');
final _farmaKoka = _producer('pr-4', 'Farma koka');
final _mlekaraM = _producer('pr-5', 'Mlekara M');
final _ilic = _producer('pr-6', 'Gazdinstvo Ilić');
final _vocar = _producer('pr-7', 'Voćar doo');
final _bakaNada = _producer('pr-8', 'Baka Nada');
final _primorje = _producer('pr-9', 'Primorje');

final List<User> _producers = [
  _bojan,
  _petrovic,
  _farmaKoza,
  _farmaKoka,
  _mlekaraM,
  _ilic,
  _vocar,
  _bakaNada,
  _primorje,
];

Product makeProduct({
required String id,
required User producer,
required String name,
required String description,
required ProductCategory category,
required ProductUnit unit,
required int priceDinars,
required int stockUnits,
String imageUrl = '',
})
{
  return Product(
    id: ProductId(id),
    producerId: producer.id,
    name: ProductName.parse(name).valueOrNull!,
    description: description,
    category: category,
    unit: unit,
    price: Price.parse(priceDinars).valueOrNull!,
    stock: Stock.parse(stockUnits).valueOrNull!,
    imageUrl: imageUrl,
  );
}

const _img = 'https://commons.wikimedia.org/wiki/Special:FilePath';

final _maline = makeProduct(
  id: 'p1',
  producer: _bojan,
  name: 'Domaće maline',
  description: 'Sveže maline iz Arilja.',
  category: ProductCategory.fruit,
  unit: ProductUnit.kilogram,
  priceDinars: 150,
  stockUnits: 10,
  imageUrl: '$_img/Raspberries_(Rubus_idaeus).jpg?width=500',
);

final _med = makeProduct(
  id: 'p2',
  producer: _petrovic,
  name: 'Med',
  description: 'Prirodni livadski med.',
  category: ProductCategory.honey,
  unit: ProductUnit.jar,
  priceDinars: 800,
  stockUnits: 5,
  imageUrl: '$_img/Runny_hunny.jpg?width=500',
);
final _sirKozji = makeProduct(
  id: 'p3',
  producer: _farmaKoza,
  name: 'Sir kozji',
  description: 'Stari kozji sir.',
  category: ProductCategory.dairy,
  unit: ProductUnit.kilogram,
  priceDinars: 1200,
  stockUnits: 2,
  imageUrl: '$_img/Goat_Cheese.jpg?width=500',
);
final _jaja = makeProduct(
  id: 'p4',
  producer: _farmaKoka,
  name: 'Domaća jaja',
  description: 'Slobodan uzgoj.',
  category: ProductCategory.dairy,
  unit: ProductUnit.piece,
  priceDinars: 20,
  stockUnits: 30,
  imageUrl: '$_img/Eggs_in_a_cardboard_box.jpg?width=500',
);
final _sirKravlji = makeProduct(
  id: 'p5',
  producer: _mlekaraM,
  name: 'Kravlji sir',
  description: 'Mladi domaći kravlji sir.',
  category: ProductCategory.dairy,
  unit: ProductUnit.kilogram,
  priceDinars: 800,
  stockUnits: 5,
  imageUrl: '$_img/Feta_Cheese.jpg?width=500',
);
final _krompir = makeProduct(
  id: 'p6',
  producer: _ilic,
  name: 'Krompir',
  description: 'Beli krompir, odličan za pečenje.',
  category: ProductCategory.vegetables,
  unit: ProductUnit.kilogram,
  priceDinars: 100,
  stockUnits: 50,
  imageUrl: '$_img/Potato_and_halves.jpg?width=500',
);
final _sok = makeProduct(
  id: 'p7',
  producer: _vocar,
  name: 'Sok od jabuke',
  description: '100% prirodni sok bez šećera.',
  category: ProductCategory.preserves,
  unit: ProductUnit.liter,
  priceDinars: 300,
  stockUnits: 15,
  imageUrl: '$_img/Apple_juice.jpg?width=500',
);
final _orah = makeProduct(
  id: 'p8',
  producer: _bojan,
  name: 'Orah očišćen',
  description: 'Sveže očišćeni orasi.',
  category: ProductCategory.fruit,
  unit: ProductUnit.kilogram,
  priceDinars: 1500,
  stockUnits: 4,
  imageUrl: '$_img/Walnut.jpg?width=500',
);
final _dzem = makeProduct(
  id: 'p9',
  producer: _bakaNada,
  name: 'Džem od šljiva',
  description: 'Domaći džem spreman po tradicionalnom receptu.',
  category: ProductCategory.preserves,
  unit: ProductUnit.jar,
  priceDinars: 450,
  stockUnits: 8,
  imageUrl: '$_img/Damson_jam.jpg?width=500',
);
// Nema na stanju: za prikaz nedostupnog proizvoda.
final _smokve = makeProduct(
  id: 'p10',
  producer: _primorje,
  name: 'Suve smokve',
  description: 'Slatke suve smokve iz uvoza, pakovane lokalno.',
  category: ProductCategory.fruit,
  unit: ProductUnit.kilogram,
  priceDinars: 600,
  stockUnits: 0,
  imageUrl: '$_img/Dried_Figs.jpg?width=500',
);

final List<Product> _products = [
  _maline,
  _med,
  _sirKozji,
  _jaja,
  _sirKravlji,
  _krompir,
  _sok,
  _orah,
  _dzem,
  _smokve,
];

Order _order ({
required String id,
required List<(Product, int)> items,
required OrderStatus status,
required DateTime createdAt,
DeliveryMethod method = DeliveryMethod.pickup,
String? address,
})
{
  return Order(
    id: OrderId(id),
    buyerId: demoBuyer.id,
    producerId: items.first.$1.producerId,
    lines: [
      for (final (product, qty) in items)
        OrderLine(
          productId: product.id,
          productName: product.name.value,
          unitPrice: product.price,
          quantity: Quantity.parse(qty, available: qty).valueOrNull!,
        ),
    ],
    status: status,
    createdAt: createdAt,
    method: method,
    address: address == null ? null : DeliveryAddress.parse(address).valueOrNull!,
  );
}

List<Order> _seedOrders() {
  final orders = <Order>[
    // Pending
    _order(
      id: 'o-1001',
      items: [(_maline, 2)],
      status: const Pending(),
      createdAt: DateTime(2026, 11, 2, 18, 30),
    ),
    // Accepted
    _order(
      id: 'o-1002',
      items: [(_med, 1)],
      status: Accepted(acceptedAt: DateTime(2026, 11, 2, 13, 0)),
      createdAt: DateTime(2026, 11, 2, 12, 0),
      method: DeliveryMethod.delivery,
      address: 'Knez Mihailova 12, Beograd',
    ),
    // Preparing
    _order(
      id: 'o-1003',
      items: [(_jaja, 12)],
      status: const Preparing(),
      createdAt: DateTime(2026, 11, 1, 9, 15),
    ),
    // Shipped
    _order(
      id: 'o-1004',
      items: [(_sirKozji, 1)],
      status: Shipped(shippedAt: DateTime(2026, 11, 1, 8, 0)),
      createdAt: DateTime(2026, 10, 31, 17, 45),
      method: DeliveryMethod.delivery,
      address: 'Bulevar kralja Aleksandra 45, Beograd',
    ),
    // Delivered (jedna sa dve stavke istog proizvođača)
    _order(
      id: 'o-1005',
      items: [(_maline, 3), (_orah, 1)],
      status: const Delivered(),
      createdAt: DateTime(2026, 10, 27, 10, 0),
      method: DeliveryMethod.delivery,
      address: 'Takovska 7, Beograd',
    ),
    _order(
      id: 'o-1006',
      items: [(_krompir, 10)],
      status: const Delivered(),
      createdAt: DateTime(2026, 10, 24, 15, 20),
    ),
    _order(
      id: 'o-1007',
      items: [(_sok, 4)],
      status: const Delivered(),
      createdAt: DateTime(2026, 10, 20, 11, 5),
      method: DeliveryMethod.delivery,
      address: 'Resavska 30, Beograd',
    ),
    // Cancelled (dva puta kupac, jednom proizvođač)
    _order(
      id: 'o-1008',
      items: [(_sirKravlji, 1)],
      status: const Cancelled(CancelReason.byBuyer),
      createdAt: DateTime(2026, 10, 29, 19, 0),
    ),
    _order(
      id: 'o-1009',
      items: [(_dzem, 1)],
      status: const Cancelled(CancelReason.byBuyer),
      createdAt: DateTime(2026, 10, 22, 8, 40),
    ),
    _order(
      id: 'o-1010',
      items: [(_smokve, 2)],
      status: const Cancelled(CancelReason.byProducer),
      createdAt: DateTime(2026, 10, 18, 14, 10),
    ),
  ];
  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return orders;
}


class FakeNetworkException implements Exception {
  const FakeNetworkException();

  @override
  String toString() => 'FakeNetworkException: namerno izazvana greška';
}

class FakeShopRepository implements ShopRepository {
  FakeShopRepository({this.latency = const Duration(milliseconds: 800)});

  final Duration latency;
  final List<Order> _orders = _seedOrders();
  bool _failNext = false;

  /// Sledeći zahtev (bilo koji) baca grešku, a zatim se sve vraća u normalu,
  /// pa „Pokušaj ponovo“ radi.
  void forceError() => _failNext = true;

  Future<void> _simulateRequest(Duration delay) async {
    await Future<void>.delayed(delay);
    if (_failNext) {
      _failNext = false;
      throw const FakeNetworkException();
    }
  }

  @override
  Future<List<User>> loadProducers() async {
    await _simulateRequest(latency ~/ 4);
    return List.of(_producers);
  }

  @override
  Future<List<Product>> loadProducts() async {
    await _simulateRequest(latency);
    return List.of(_products);
  }

  @override
  Future<List<Order>> loadOrders() async {
    await _simulateRequest(latency ~/ 2);
    return List.of(_orders);
  }

  @override
  Future<void> saveOrder(Order order) async {
    await _simulateRequest(latency ~/ 2);
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index == -1) {
      _orders.insert(0, order);
    } else {
      _orders[index] = order;
    }
  }
}