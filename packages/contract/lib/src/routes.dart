abstract final class ApiPaths {
  static const health = '/health';
  static const sessions='/sessions';
  static const currentSession='/sessions/current';
  static const producers = '/producers';
  static const products = '/products';
  static String product(String id) => '/products/$id';

  static const orders = '/orders';
  static String orderStatus(String id) => '/orders/$id/status';
  static String orderCancellation(String id) => '/orders/$id/cancellation';

  static const myProducts = '/my/products';
  static String productPrice(String id) => '/products/$id/price';
  static String productStock(String id) => '/products/$id/stock';
}
abstract final class ApiCookies {
  static const session = 'svezko_session';
}
