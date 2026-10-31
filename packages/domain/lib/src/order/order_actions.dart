import 'package:domain/src/errors.dart';
import 'package:domain/src/order/order_status.dart';
import 'package:domain/src/order/transitions.dart';
import 'package:domain/src/result.dart';
import 'package:domain/src/user.dart';

import 'order.dart';

///Ko moze da vidi porudzbinu
bool canViewOrder (User user,Order order)=>switch(user.role)
{
  UserRole.buyer=>user.id==order.buyerId,
  UserRole.producer=>user.id==order.producerId,
};


Result<Order>changeOrderStatus(
Order order,
OrderStatus to,{
required User actor,
}

){
  if(!canViewOrder(actor, order)){
    return Failure<Order>(NotAuthorized(actor.id));
  }

  final allowedForRole=switch(actor.role)
      {


    UserRole.buyer => to is Cancelled && to.reason==CancelReason.byBuyer,
    UserRole.producer => to is! Cancelled || to.reason == CancelReason.byProducer,
     };

  if(!allowedForRole)
    {
      return Failure<Order>(NotAuthorized(actor.id));
    }

  final result = switch( to )
      {
        Cancelled(:final reason) => cancel(order.status,reason:reason),
         _ => transition(order.status, to),
      };

  final error = result.errorOrNull;
  if(error != null )
    return Failure<Order>(error);

  return Success<Order>(order.withStatus(to));
}

Result<Order> cancelOrder(Order order, {required User actor}) {
  final reason = actor.role == UserRole.buyer
      ? CancelReason.byBuyer
      : CancelReason.byProducer;
  return changeOrderStatus(order, Cancelled(reason), actor: actor);
}
