import 'package:domain/src/errors.dart';
import 'package:domain/src/order/order_status.dart';
import 'package:domain/src/result.dart';

bool canTransition(OrderStatus from,OrderStatus to) => switch ((from,to))
{
  (Pending(), Accepted()) => true,
  (Pending(), Cancelled()) => true,
  (Accepted(), Preparing()) => true,
  (Accepted(), Cancelled()) => true,
  (Preparing(), Shipped()) => true,
  (Shipped(), Delivered()) => true,
  _ => false,
};

Result<OrderStatus> transition(OrderStatus from,OrderStatus to)
{
  if(!canTransition(from, to))
    {
      return Failure<OrderStatus>(TransitionNotAllowed(from: from,to: to));
    }
  return Success<OrderStatus>(to);
}

bool canCancel(OrderStatus status)=>
    canTransition(status, const Cancelled(CancelReason.byBuyer));

Result<OrderStatus> cancel(
OrderStatus current, {
  required CancelReason reason,
}
){
  if(!canCancel(current))
    {
      return Failure<OrderStatus>(CancellationNotAllowed(current));
    }
  return Success<OrderStatus>(Cancelled(reason));
}

bool isFinal(OrderStatus status)=>status is Delivered || status is Cancelled;

bool isActive (OrderStatus status) => !isFinal(status);
