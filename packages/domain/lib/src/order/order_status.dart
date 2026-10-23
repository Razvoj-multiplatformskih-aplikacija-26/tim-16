sealed class OrderStatus{
  const OrderStatus();
}

final class Pending extends OrderStatus {
  const Pending();
}

final class Accepted extends OrderStatus {
  const Accepted({required this.acceptedAt});
  final DateTime acceptedAt;
}

final class Preparing extends OrderStatus{
  const Preparing();
}

final class Shipped extends OrderStatus{
  const Shipped({required this.shippedAt});
  final DateTime shippedAt;
}

final class Delivered extends OrderStatus{
  const Delivered();
}

enum CancelReason {byBuyer,byProducer}

final class Cancelled extends OrderStatus{
  const Cancelled(this.reason);
  final CancelReason reason;
}
