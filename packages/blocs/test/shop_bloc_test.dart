import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const buyer = User(
  id: UserId('buyer-1'),
  fullName: 'Marko Kupac',
  role: UserRole.buyer,
);
const producer = User(
  id: UserId('prod-1'),
  fullName: 'Jelena Proizvođač',
  role: UserRole.producer,
);

Product makeProduct({String id = 'p1', int stock = 5, bool published = true}) {
  final created = createProduct(
    id: ProductId(id),
    actor: producer,
    name: 'Domaće maline',
    description: 'Sveže',
    category: ProductCategory.fruit,
    unit: ProductUnit.kilogram,
    priceDinars: 150,
    stockUnits: stock,
  ).valueOrNull!;
  return created.copyWith(published: published);
}

Order makeOrder(String id, OrderStatus status) => Order(
  id: OrderId(id),
  buyerId: buyer.id,
  producerId: producer.id,
  lines: [
    OrderLine(
      productId: const ProductId('p1'),
      productName: 'Domaće maline',
      unitPrice: Price.parse(150).valueOrNull!,
      quantity: Quantity.parse(1, available: 5).valueOrNull!,
    ),
  ],
  status: status,
  createdAt: DateTime.utc(2026, 11, 1),
  method: DeliveryMethod.pickup,
);

class FakeRepo implements ShopRepository {
  FakeRepo({
    this.products = const [],
    this.orders = const [],
    this.failLoad = false,
    this.failSave = false,
  });

  final List<Product> products;
  final List<Order> orders;
  bool failLoad;
  bool failSave;
  final saved = <Order>[];

  @override
  Future<List<User>> loadProducers() async => [producer];

  @override
  Future<List<Product>> loadProducts() async {
    if (failLoad) throw Exception('mreža');
    return products;
  }

  @override
  Future<List<Order>> loadOrders() async => orders;

  @override
  Future<void> saveOrder(Order order) async {
    if (failSave) throw Exception('mreža');
    saved.add(order);
  }
}

ShopBloc makeBloc(FakeRepo repo) {
  var tick = 0;
  return ShopBloc(
    repository: repo,
    currentUser: buyer,
    clock: () => DateTime.utc(2026, 11, 3).add(Duration(seconds: tick++)),
  );
}

Future<ShopLoaded> loaded(ShopBloc bloc) async =>
    await bloc.stream.firstWhere((s) => s is ShopLoaded) as ShopLoaded;

Future<ShopLoaded> withFeedback(ShopBloc bloc) async => await bloc.stream
    .firstWhere((s) => s is ShopLoaded && s.feedback != null) as ShopLoaded;

void main() {
  group('učitavanje', () {
    test('uspeh daje ShopLoaded sa proizvodima i porudžbinama', () async {
      final repo = FakeRepo(
        products: [makeProduct()],
        orders: [makeOrder('o1', const Pending())],
      );
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      final state = await loaded(bloc);
      expect(state.products.length, 1);
      expect(state.orders.length, 1);
      expect(state.producerName(producer.id), 'Jelena Proizvođač');
      await bloc.close();
    });

    test('bez proizvoda daje ShopEmpty', () async {
      final bloc = makeBloc(FakeRepo())..add(const LoadShopDataEvent());
      final state = await bloc.stream.firstWhere((s) => s is! ShopLoading);
      expect(state, isA<ShopEmpty>());
      await bloc.close();
    });

    test('nepublikovan proizvod se ne prikazuje', () async {
      final repo = FakeRepo(
        products: [makeProduct(), makeProduct(id: 'p2', published: false)],
      );
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      final state = await loaded(bloc);
      expect(state.products.length, 1);
      await bloc.close();
    });

    test('greška daje ShopError, a ponovni pokušaj uspeva', () async {
      final repo = FakeRepo(products: [makeProduct()], failLoad: true);
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      final error = await bloc.stream.firstWhere((s) => s is ShopError);
      expect(error, isA<ShopError>());

      repo.failLoad = false;
      bloc.add(const LoadShopDataEvent());
      final state = await loaded(bloc);
      expect(state.products.length, 1);
      await bloc.close();
    });
  });

  group('pravljenje porudžbine', () {
    test('uspeh: nova porudžbina je Pending i prva u listi', () async {
      final repo = FakeRepo(products: [makeProduct()]);
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      await loaded(bloc);

      bloc.add(const CreateOrderEvent(productId: ProductId('p1'), quantity: 2));
      final state = await withFeedback(bloc);

      expect(state.feedback, isA<OrderPlaced>());
      expect(state.orders.length, 1);
      expect(state.orders.first.status, const Pending());
      expect(repo.saved.length, 1);
      await bloc.close();
    });

    test('količina veća od zalihe: pravilo iz domena odbija', () async {
      final repo = FakeRepo(products: [makeProduct(stock: 3)]);
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      await loaded(bloc);

      bloc.add(const CreateOrderEvent(productId: ProductId('p1'), quantity: 4));
      final state = await withFeedback(bloc);

      final feedback = state.feedback;
      expect(feedback, isA<RuleViolated>());
      expect((feedback as RuleViolated).error, isA<QuantityExceedsStock>());
      expect(state.orders.length, 0);
      expect(repo.saved.length, 0);
      await bloc.close();
    });

    test('više od 5 aktivnih porudžbina se odbija', () async {
      final repo = FakeRepo(
        products: [makeProduct(stock: 50)],
        orders: [for (var i = 0; i < 5; i++) makeOrder('o$i', const Pending())],
      );
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      await loaded(bloc);

      bloc.add(const CreateOrderEvent(productId: ProductId('p1'), quantity: 1));
      final state = await withFeedback(bloc);

      final feedback = state.feedback as RuleViolated;
      expect(feedback.error, isA<TooManyActiveOrders>());
      await bloc.close();
    });

    test('greška repozitorijuma daje ActionFailed i ne dodaje porudžbinu',
            () async {
          final repo = FakeRepo(products: [makeProduct()], failSave: true);
          final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
          await loaded(bloc);

          bloc.add(const CreateOrderEvent(productId: ProductId('p1'), quantity: 1));
          final state = await withFeedback(bloc);

          expect(state.feedback, isA<ActionFailed>());
          expect(state.orders.length, 0);
          await bloc.close();
        });
  });

  group('otkazivanje', () {
    test('Pending se otkazuje', () async {
      final repo = FakeRepo(
        products: [makeProduct()],
        orders: [makeOrder('o1', const Pending())],
      );
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      await loaded(bloc);

      bloc.add(const CancelOrderEvent(OrderId('o1')));
      final state = await withFeedback(bloc);

      expect(state.feedback, isA<OrderCancelled>());
      expect(state.orders.first.status, isA<Cancelled>());
      expect(repo.saved.length, 1);
      await bloc.close();
    });

    test('Shipped se ne može otkazati', () async {
      final repo = FakeRepo(
        products: [makeProduct()],
        orders: [makeOrder('o1', Shipped(shippedAt: DateTime.utc(2026, 11, 2)))],
      );
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      await loaded(bloc);

      bloc.add(const CancelOrderEvent(OrderId('o1')));
      final state = await withFeedback(bloc);

      final feedback = state.feedback as RuleViolated;
      expect(feedback.error, isA<CancellationNotAllowed>());
      expect(state.orders.first.status, isA<Shipped>());
      await bloc.close();
    });

    test('nepoznata porudžbina daje OrderNotFound', () async {
      final repo = FakeRepo(products: [makeProduct()]);
      final bloc = makeBloc(repo)..add(const LoadShopDataEvent());
      await loaded(bloc);

      bloc.add(const CancelOrderEvent(OrderId('nema')));
      final state = await withFeedback(bloc);

      final feedback = state.feedback as RuleViolated;
      expect(feedback.error, isA<OrderNotFound>());
      await bloc.close();
    });
  });
}
