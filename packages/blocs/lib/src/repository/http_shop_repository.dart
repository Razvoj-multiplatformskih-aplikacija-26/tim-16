import 'dart:convert';

import 'package:contract/contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:mapping/mapping.dart';

import 'api_client.dart'; // IZMENA: nov import
import 'shop_repository.dart';

final class HttpShopRepository implements ShopRepository, ProductManagementRepository {
  HttpShopRepository(this._api, {this.pageSize = PageRequest.defaultLimit});

  final ApiClient _api;

  final int pageSize;

  int skippedRecords = 0;

  final _knownOrders = <OrderId>{};

  static const _maxPages = 1000;

  @override
  Future<List<User>> loadProducers() async {
    final items = switch (await _get(ApiPaths.producers)) {
      final List<Object?> list => list.whereType<JsonMap>(),
      _ => throw const WireFormatException('Očekivana je lista proizvođača'),
    };
    return _readEach(items, (json) => producerFromDto(ProducerDto.fromJson(json)));
  }

  @override
  Future<List<Product>> loadProducts() =>
      _allPages(ApiPaths.products, (json) => productFromDto(ProductDto.fromJson(json)));

  @override
  Future<List<Order>> loadOrders() async {
    final orders = await _allPages(ApiPaths.orders, (json) => orderFromDto(OrderDto.fromJson(json)));
    _knownOrders
      ..clear()
      ..addAll(orders.map((order) => order.id));
    return orders;
  }

  @override
  Future<Order> saveOrder(Order order) async {
    final id = order.id.value;
    final Object? body;
    if (!_knownOrders.contains(order.id)) {
      body = await _post(ApiPaths.orders, placeOrderRequestOf(order).toJson());
    } else if (order.status is Cancelled) {
      body = await _post(ApiPaths.orderCancellation(id), const {});
    } else {
      body = await _post(ApiPaths.orderStatus(id), changeStatusRequestOf(order.status).toJson());
    }
    final saved = orderFromDto(OrderDto.fromJson(asObject(body)));
    _knownOrders.add(saved.id);
    return saved;
  }

  @override
  Future<Product> addProduct(Product product) async {
    final body = await _post(ApiPaths.products, createProductRequestOf(product).toJson());
    return productFromDto(ProductDto.fromJson(asObject(body)));
  }

  @override
  Future<void> deleteProduct(ProductId productId) async {
    _bodyOf(await _api.delete(ApiPaths.product(productId.value))); // IZMENA
  }

  Future<List<T>> _allPages<T>(String path, T Function(JsonMap json) decode) async {
    final result = <T>[];
    String? cursor;
    var pages = 0;
    do {
      final page = PageDto.fromJson(
        asObject(await _get(path, query: PageRequest(limit: pageSize, cursor: cursor).toQuery())),
            (json) => json,
      );
      result.addAll(_readEach(page.items, decode));
      cursor = page.nextCursor;
    } while (cursor != null && ++pages < _maxPages);
    return result;
  }

  List<T> _readEach<T>(Iterable<JsonMap> items, T Function(JsonMap json) decode) {
    final result = <T>[];
    for (final item in items) {
      try {
        result.add(decode(item));
      } on FormatException {
        skippedRecords++;
      }
    }
    return result;
  }



  Future<Object?> _get(String path, {Map<String, String>? query}) async =>
      _bodyOf(await _api.get(path, query: query));

  Future<Object?> _post(String path, JsonMap body) async =>
      _bodyOf(await _api.post(path, body: body));

  Object? _bodyOf(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw rejectionOf(response.statusCode, response.bodyBytes);
  }
}

Exception rejectionOf(int status, List<int> bodyBytes) {
  final problem = _readProblem(bodyBytes);
  if (problem == null) return RepositoryUnavailable('HTTP $status bez greške iz ugovora');

  if (domainErrorOf(problem) case final error?) return ActionRejected(error);

  if (problem.status >= 500 || _technicalCodes.contains(problem.code)) {
    return RepositoryUnavailable('${problem.status} ${problem.code}');
  }

  return ActionRefused(problem.code, params: problem.params);
}

ProblemDto? _readProblem(List<int> bodyBytes) {
  try {
    return ProblemDto.fromJson(asObject(jsonDecode(utf8.decode(bodyBytes))));
  } on FormatException {
    return null;
  }
}

const _technicalCodes = {
  ErrorCodes.badRequest,
  ErrorCodes.routeNotFound,
  ErrorCodes.unsupportedMediaType,
  ErrorCodes.payloadTooLarge,
  ErrorCodes.signInRequired,
  ErrorCodes.serverError,
  ErrorCodes.unreadableResponse,
};