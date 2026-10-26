import 'package:domain/src/errors.dart';
import 'package:domain/src/result.dart';
import 'package:domain/src/text_rules.dart';
import 'package:equatable/equatable.dart';

final class ProductName extends Equatable{
  const ProductName._(this.value);
  final String value;

  static const int min=2;
  static const int max=60;

  static Result<ProductName>parse(String raw){
    final result=parseBoundedText(raw, kind: TextKind.productName, min: min, max: max);
    final error=result.errorOrNull;
    if(error!=null)return Failure<ProductName>(error);
    return Success<ProductName>(ProductName._(result.valueOrNull!));
  }

  @override
  // TODO: implement props
  List<Object?> get props =>[value];
}