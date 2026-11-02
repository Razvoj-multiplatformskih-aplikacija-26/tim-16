import 'package:equatable/equatable.dart';

sealed class OrderStatus extends Equatable{
  const OrderStatus();
}

final class Pending extends OrderStatus {
  const Pending();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

final class Accepted extends OrderStatus {
  const Accepted({required this.acceptedAt});
  final DateTime acceptedAt;

  @override
  // TODO: implement props
  List<Object?> get props => [acceptedAt];
}

final class Preparing extends OrderStatus{
  const Preparing();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

final class Shipped extends OrderStatus{
  const Shipped({required this.shippedAt});
  final DateTime shippedAt;

  @override
  // TODO: implement props
  List<Object?> get props => [shippedAt];
}

final class Delivered extends OrderStatus{
  const Delivered();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

enum CancelReason {byBuyer,byProducer}

final class Cancelled extends OrderStatus{
  const Cancelled(this.reason);
  final CancelReason reason;

  @override
  // TODO: implement props
  List<Object?> get props => [reason];
}
