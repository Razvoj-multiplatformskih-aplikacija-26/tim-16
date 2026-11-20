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
    on<AddProductEvent>(_onAddProduct);
  }

  final ShopRepository repository;
  final User currentUser;
  final DateTime Function() _clock;

  /// Server je odbio akciju pravilom jer je klijent radio nad zastarelim
  /// podacima. Korisnik vidi razlog (ista poruka kao kada pravilo proveri
  /// klijent), a ekran se ponovo učita sa podacima po kojima je server odlučio.
  Future<void> _reloadAfter(ShopFeedback feedback, Emitter<ShopState> emit) async {
    final latest = state;
    if (latest is! ShopLoaded) return;
    try {
      final products = await repository.loadProducts();
      final orders = await repository.loadOrders();
      emit(latest.copyWith(
        products: products.where((p) => p.published).toList(),
        orders: orders,
        feedback: feedback,
      ));
    } catch (_) {
      // Ponovno učitavanje nije uspelo, ali razlog odbijanja i dalje važi.
      emit(latest.copyWith(feedback: feedback));
    }
  }

  Future<void> _onAddProduct(AddProductEvent event, Emitter<ShopState> emit) async {
    final current = state;
    if (current is! ShopLoaded) return;
    emit(current.copyWith());
    final productRepository = repository;
    if (productRepository is! ProductManagementRepository) {
      emit(current.copyWith(feedback: const ActionFailed()));
      return;
    }
    final managementRepository = productRepository as ProductManagementRepository;
    final result = createProduct(
      id: ProductId('p-${_clock().microsecondsSinceEpoch}'),
      actor: currentUser,
      name: event.name,
      description: event.description,
      category: event.category,
      unit: event.unit,
      priceDinars: event.priceDinars,
      stockUnits: event.stockUnits,
    );
    switch (result) {
      case Failure(:final error):
        emit(current.copyWith(feedback: RuleViolated(error)));
      case Success(:final value):
        final Product saved;
        try {
          saved = await managementRepository.addProduct(value);
        } on ActionRejected catch (rejection) {
          await _reloadAfter(RuleViolated(rejection.error), emit);
          return;
        } on ActionRefused catch (refusal) {
          await _reloadAfter(RefusedByServer(refusal.code), emit);
          return;
        } catch (_) {
          emit(current.copyWith(feedback: const ActionFailed()));
          return;
        }
        final latest = state;
        if (latest is! ShopLoaded) return;
        emit(latest.copyWith(products: [saved, ...latest.products], feedback: ProductAdded(saved)));
    }
  }

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
        final Order saved;
        try {
          saved = await repository.saveOrder(value);
        } on ActionRejected catch (rejection) {
          await _reloadAfter(RuleViolated(rejection.error), emit);
          return;
        } on ActionRefused catch (refusal) {
          await _reloadAfter(RefusedByServer(refusal.code), emit);
          return;
        } catch (_) {
          emit(current.copyWith(feedback: const ActionFailed()));
          return;
        }
        final latest = state;
        if (latest is! ShopLoaded) return;
        emit(latest.copyWith(
          orders: [for (final item in latest.orders) item.id == saved.id ? saved : item],
          feedback: OrderStatusChanged(saved),
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
    } on ActionRejected catch (rejection) {
      await _reloadAfter(RuleViolated(rejection.error), emit);
      return;
    } on ActionRefused catch (refusal) {
      await _reloadAfter(RefusedByServer(refusal.code), emit);
      return;
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
    if (visible.isEmpty && orders.isEmpty) {
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
      final Order saved;
      try {
        saved = await repository.saveOrder(value);
      } on ActionRejected catch (rejection) {
        await _reloadAfter(RuleViolated(rejection.error), emit);
        return;
      } on ActionRefused catch (refusal) {
        await _reloadAfter(RefusedByServer(refusal.code), emit);
        return;
      } catch (_) {
        emit(current.copyWith(feedback: const ActionFailed()));
        return;
      }
      final latest = state;
      if (latest is! ShopLoaded) return;
      emit(
        latest.copyWith(
          orders: [saved, ...latest.orders],
          feedback: OrderPlaced(saved),
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
        final Order saved;
        try {
          saved = await repository.saveOrder(value);
        } on ActionRejected catch (rejection) {
          await _reloadAfter(RuleViolated(rejection.error), emit);
          return;
        } on ActionRefused catch (refusal) {
          await _reloadAfter(RefusedByServer(refusal.code), emit);
          return;
        } catch (_) {
          emit(current.copyWith(feedback: const ActionFailed()));
          return;
        }
        final latest = state;
        if (latest is! ShopLoaded) return;
        emit(
          latest.copyWith(
            orders: [for (final o in latest.orders) o.id == saved.id ? saved : o],
            feedback: OrderCancelled(saved),
          ),
        );
    }
  }
}
