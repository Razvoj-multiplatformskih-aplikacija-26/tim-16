import 'package:bloc/bloc.dart';
import 'shop_event.dart';
import 'shop_state.dart';
import '../repository/shop_repository.dart';
import '../models/models.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopRepository repository;

  ShopBloc({required this.repository}) : super(ShopLoading()) {
    on<LoadShopDataEvent>(_onLoadShopData);
    on<CreateOrderEvent>(_onCreateOrder);
    // 1. Registrujemo novi događaj
    on<CancelOrderEvent>(_onCancelOrder);
  }

  Future<void> _onLoadShopData(LoadShopDataEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());

    try {
      final products = await repository.loadProducts();
      final orders = await repository.loadOrders();

      if (products.isEmpty) {
        emit(ShopEmpty());
      } else {
        emit(ShopLoaded(products: products, orders: orders));
      }
    } catch (e) {
      emit(ShopError("Došlo je do greške pri učitavanju podataka."));
    }
  }

  Future<void> _onCreateOrder(CreateOrderEvent event, Emitter<ShopState> emit) async {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;

      try {
        final newOrder = await repository.createOrder(event.product, event.quantity);

        final updatedOrders = List<Order>.from(currentState.orders)..insert(0, newOrder);

        emit(ShopLoaded(
          products: currentState.products,
          orders: updatedOrders,
        ));
      } catch (e) {
        // Greška pri kreiranju
      }
    }
  }

  // 2. Dodajemo metodu za obradu otkazivanja
  void _onCancelOrder(CancelOrderEvent event, Emitter<ShopState> emit) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;

      // Mapiramo stare porudžbine u novu listu i menjamo status samo onoj koja se otkazuje
      final updatedOrders = currentState.orders.map((o) {
        if (o.id == event.order.id) {
          // Vraćamo istu porudžbinu, ali sa promenjenim stanjem u 'cancelled'
          return Order(o.id, o.product, o.quantity, OrderState.cancelled);
        }
        return o; // Ostale ostaju nepromenjene
      }).toList();

      // Emitujemo osveženo stanje
      emit(ShopLoaded(
        products: currentState.products,
        orders: updatedOrders,
      ));
    }
  }
}