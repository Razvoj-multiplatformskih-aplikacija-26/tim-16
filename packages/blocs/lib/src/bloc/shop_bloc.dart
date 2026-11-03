import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';

import '../repository/shop_repository.dart';
import 'shop_event.dart';
import 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc({
    required this.repository,
    required this.currentUser,
    this._clock = DateTime.now,
  }) : super(const ShopLoading()) {
    on<LoadShopDataEvent>(_onLoad);
    on<CreateOrderEvent>(_onCreateOrder);
    on<CancelOrderEvent>(_onCancelOrder);
    on<ChangeOrderStatusEvent>(_onChangeOrderStatus);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  final ShopRepository repository;
  final User currentUser;
  final DateTime Function() _clock;

  Future<void> _onChangeOrderStatus(ChangeOrderStatusEvent event, Emitter<ShopState> emit) async {
    final current = state;
    if (current is! ShopLoaded) return;
    final order = current.orders.where((item) => item.id == event.orderId).firstOrNull;
    if (order == null) {
      emit(current.copyWith(feedback: RuleViolated(OrderNotFound(event.orderId))));
      return;
    }
    final result = changeOrderStatus(order, event.status, actor: currentUser);
    switch (result) {
      case Failure(:final error):
        emit(current.copyWith(feedback: RuleViolated(error)));
      case Success(:final value):
        try {
          await repository.saveOrder(value);
        } catch (_) {
          emit(current.copyWith(feedback: const ActionFailed()));
          return;
        }
        final latest = state;
        if (latest is! ShopLoaded) return;
        emit(latest.copyWith(
          orders: [for (final item in latest.orders) item.id == value.id ? value : item],
          feedback: OrderStatusChanged(value),
        ));
    }
  }

  Future<void> _onDeleteProduct(DeleteProductEvent event, Emitter<ShopState> emit) async {
    final current = state;
    if (current is! ShopLoaded) return;
    if (!current.products.any((item) => item.id == event.productId)) return;
    final productRepository = repository;
    if (productRepository is! ProductManagementRepository) {
      emit(current.copyWith(feedback: const ActionFailed()));
      return;
    }
    final managementRepository = productRepository as ProductManagementRepository;
    try {
      await managementRepository.deleteProduct(event.productId);
    } catch (_) {
      emit(current.copyWith(feedback: const ActionFailed()));
      return;
    }
    final latest = state;
    if (latest is! ShopLoaded) return;
    emit(latest.copyWith(
      products: latest.products.where((item) => item.id != event.productId).toList(),
      feedback: ProductDeleted(event.productId),
    ));
  }


Future<void> _onLoad(
    LoadShopDataEvent event,
    Emitter<ShopState>emit,
    )async {
  emit(const ShopLoading());
  try {
    final products = await repository.loadProducts();
    final orders = await repository.loadOrders();
    final producers = await repository.loadProducers();

    final visible = products.where((p) => p.published).toList();
    if (visible.isEmpty) {
      emit(const ShopEmpty());
      return;
    }
    emit(
      ShopLoaded(
        products: visible,
        orders: orders,
        producers: {for (final u in producers) u.id: u},
      ),
    );
  } catch (_) {
    emit(const ShopError('Došlo je do greške pri učitavanju podataka.'));
  }
}

 Future<void>_onCreateOrder(
     CreateOrderEvent event,
     Emitter<ShopState>emit,
     )async {
  final current=state;
  if(current is! ShopLoaded) return;
  emit(current.copyWith());

  final now=_clock();
  final result=placeOrder(
    id:OrderId('o-${now.microsecondsSinceEpoch}'),
    buyer:currentUser,
    request: [
      OrderRequestLine(productId: event.productId, quantity: event.quantity),
    ],
    catalog: current.products,
    existingOrders: current.orders,
    method: event.method,
    address: event.address,
    now: now,
  );

  switch (result) {
    case Failure(:final error):
      emit(current.copyWith(feedback: RuleViolated(error)));
    case Success(:final value):
      try {
        await repository.saveOrder(value);
      } catch (_) {
        emit(current.copyWith(feedback: const ActionFailed()));
        return;
      }
      final latest = state;
      if (latest is! ShopLoaded) return;
      emit(
        latest.copyWith(
          orders: [value, ...latest.orders],
          feedback: OrderPlaced(value),
        ),
      );
  }
 }

  Future<void> _onCancelOrder(
      CancelOrderEvent event,
      Emitter<ShopState> emit,
      ) async {
    final current = state;
    if (current is! ShopLoaded) return;
    emit(current.copyWith());

    final order = current.orders.where((o) => o.id == event.orderId).firstOrNull;
    if (order == null) {
      emit(current.copyWith(feedback: RuleViolated(OrderNotFound(event.orderId))));
      return;
    }

    final result = cancelOrder(order, actor: currentUser);

    switch (result) {
      case Failure(:final error):
        emit(current.copyWith(feedback: RuleViolated(error)));
      case Success(:final value):
        try {
          await repository.saveOrder(value);
        } catch (_) {
          emit(current.copyWith(feedback: const ActionFailed()));
          return;
        }
        final latest = state;
        if (latest is! ShopLoaded) return;
        emit(
          latest.copyWith(
            orders: [for (final o in latest.orders) o.id == value.id ? value : o],
            feedback: OrderCancelled(value),
          ),
        );
    }
  }
}
