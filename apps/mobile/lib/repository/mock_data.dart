import 'package:flutter/material.dart';

enum OrderState { pending, accepted, preparing, shipped, delivered, cancelled }

extension OrderStateExtension on OrderState {
  String get nameSr {
    switch (this) {
      case OrderState.pending: return 'Na čekanju';
      case OrderState.accepted: return 'Prihvaćena';
      case OrderState.preparing: return 'U pripremi';
      case OrderState.shipped: return 'Poslata';
      case OrderState.delivered: return 'Isporučena';
      case OrderState.cancelled: return 'Otkazana';
    }
  }
}

class Product {
  final String id;
  final String name;
  final String producer;
  final double price;
  final String unit;
  final int availableQuantity;
  final String description;
  final String imageUrl;

  Product(this.id, this.name, this.producer, this.price, this.unit, this.availableQuantity, this.description, this.imageUrl);
}

class Order {
  final String id;
  final Product product;
  final int quantity;
  OrderState state;

  Order(this.id, this.product, this.quantity, this.state);
}

class FakeDatabase {
  static final List<Product> products = [
    Product('p1', 'Domaće maline', 'Bojan Matić', 150, 'kg', 10, 'Sveže maline iz Arilja.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Raspberries_(Rubus_idaeus).jpg?width=500'),

    Product('p2', 'Med', 'Gazdinstvo Petrović', 800, 'tegla', 5, 'Prirodni livadski med.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Runny_hunny.jpg?width=500'),

    Product('p3', 'Sir kozji', 'Farma koza', 1200, 'kg', 2, 'Stari kozji sir.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Goat_Cheese.jpg?width=500'),

    Product('p4', 'Domaća jaja', 'Farma koka', 20, 'kom', 30, 'Slobodan uzgoj.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Eggs_in_a_cardboard_box.jpg?width=500'),

    Product('p5', 'Kravlji sir', 'Mlekara M', 800, 'kg', 5, 'Mladi domaći kravlji sir.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Feta_Cheese.jpg?width=500'),

    Product('p6', 'Krompir', 'Gazdinstvo Ilić', 100, 'kg', 50, 'Beli krompir, odličan za pečenje.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Potato_and_halves.jpg?width=500'),

    Product('p7', 'Sok od jabuke', 'Voćar doo', 300, 'flaša', 15, '100% prirodni sok bez šećera.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Apple_juice.jpg?width=500'),

    Product('p8', 'Orah očišćen', 'Bojan Matić', 1500, 'kg', 4, 'Sveže očišćeni orasi.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Walnut.jpg?width=500'),

    Product('p9', 'Džem od šljiva', 'Baka Nada', 450, 'tegla', 8, 'Domaći džem spreman po tradicionalnom receptu.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Damson_jam.jpg?width=500'),

    Product('p10', 'Suve smokve', 'Primorje', 600, 'kg', 10, 'Slatke suve smokve iz uvoza, pakovane lokalno.',
        'https://commons.wikimedia.org/wiki/Special:FilePath/Dried_Figs.jpg?width=500'),
  ];

  static final ValueNotifier<List<Order>> ordersNotifier = ValueNotifier<List<Order>>([]);


  static void addOrder(Product product, int quantity) {
    final newOrder = Order('o_new_${DateTime.now().millisecondsSinceEpoch}', product, quantity, OrderState.pending);
    final updatedList = List<Order>.from(ordersNotifier.value);
    updatedList.insert(0, newOrder);
    ordersNotifier.value = updatedList;
  }
}