import 'package:blocs/blocs.dart'; // Tvoj čisti dart paket

class FakeShopRepository implements ShopRepository {
  // Dugme/akcija iz UI-a će postaviti ovo na true da bi demonstrirao Error stanje na odbrani
  bool _forceErrorOnNextCall = false;

  void forceError() {
    _forceErrorOnNextCall = true;
  }

  // Tvoji lažni podaci ostaju ovde u memoriji aplikacije
  final List<Product> _mockProducts = [
    const Product('p1', 'Domaće maline', 'Bojan Matić', 150, 'kg', 10, 'Sveže maline iz Arilja.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Raspberries_(Rubus_idaeus).jpg?width=500'),
    const Product('p2', 'Med', 'Gazdinstvo Petrović', 800, 'tegla', 5, 'Prirodni livadski med.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Runny_hunny.jpg?width=500'),
    const Product('p3', 'Sir kozji', 'Farma koza', 1200, 'kg', 2, 'Stari kozji sir.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Goat_Cheese.jpg?width=500'),
    const Product('p4', 'Domaća jaja', 'Farma koka', 20, 'kom', 30, 'Slobodan uzgoj.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Eggs_in_a_cardboard_box.jpg?width=500'),
    const Product('p5', 'Kravlji sir', 'Mlekara M', 800, 'kg', 5, 'Mladi domaći kravlji sir.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Feta_Cheese.jpg?width=500'),
    const Product('p6', 'Krompir', 'Gazdinstvo Ilić', 100, 'kg', 50, 'Beli krompir, odličan za pečenje.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Potato_and_halves.jpg?width=500'),
    const Product('p7', 'Sok od jabuke', 'Voćar doo', 300, 'flaša', 15, '100% prirodni sok bez šećera.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Apple_juice.jpg?width=500'),
    const Product('p8', 'Orah očišćen', 'Bojan Matić', 1500, 'kg', 4, 'Sveže očišćeni orasi.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Walnut.jpg?width=500'),
    const Product('p9', 'Džem od šljiva', 'Baka Nada', 450, 'tegla', 8, 'Domaći džem spreman po tradicionalnom receptu.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Damson_jam.jpg?width=500'),
    const Product('p10', 'Suve smokve', 'Primorje', 600, 'kg', 10, 'Slatke suve smokve iz uvoza, pakovane lokalno.', 'https://commons.wikimedia.org/wiki/Special:FilePath/Dried_Figs.jpg?width=500'),
  ];

  // Umesto ValueNotifier-a, koristimo običnu listu. BLoC će obaveštavati UI o promenama.
  final List<Order> _mockOrders = [];

  @override
  Future<List<Product>> loadProducts() async {
    // 1. Veštačko kašnjenje za Loading stanje
    await Future.delayed(const Duration(seconds: 1));

    // 2. Provera za Error stanje (Zahtev 3 sa odbrane)
    if (_forceErrorOnNextCall) {
      _forceErrorOnNextCall = false; // Resetujemo da bi "Pokušaj ponovo" radilo
      throw Exception('Namerno bačena greška sa mreže!');
    }

    return _mockProducts;
  }

  @override
  Future<List<Order>> loadOrders() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockOrders;
  }

  @override
  Future<Order> createOrder(Product product, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newOrder = Order(
        'o_new_${DateTime.now().millisecondsSinceEpoch}',
        product,
        quantity,
        OrderState.pending
    );

    _mockOrders.insert(0, newOrder);
    return newOrder;
  }
}