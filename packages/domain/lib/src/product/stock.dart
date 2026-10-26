import 'package:domain/src/errors.dart';
import 'package:domain/src/result.dart';
import 'package:equatable/equatable.dart';

final class Stock extends Equatable{
  const Stock._(this.units);

  final int units;

  static const int max=100000;
  static const Stock empty=Stock._(0);

  static Result<Stock>parse(int units)
  {
    if(units < 0 || units>max)
      {
        return Failure<Stock>(StockOutOfRange(units:units,max:max));
      }
    return Success<Stock>(Stock._(units));
  }

  @override
  // TODO: implement props
  List<Object?> get props => [units];
}