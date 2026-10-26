import 'package:domain/src/errors.dart';
import 'package:domain/src/result.dart';
import 'package:equatable/equatable.dart';

final class Price extends Equatable{
  const Price._(this.dinars);
  final int dinars;
  static const int min=1;
  static const int max=100000;

  static Result<Price>parse (int dinars)
  {
    if(dinars<min||dinars>max)
      {
        return Failure<Price>(PriceOutOfRange(value: dinars,min:min,max:max));
      }
    return Success<Price>(Price._(dinars));
  }

  @override
  // TODO: implement props
  List<Object?> get props => [dinars];
}