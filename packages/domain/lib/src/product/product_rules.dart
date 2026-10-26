import 'package:domain/src/errors.dart';
import 'package:domain/src/identifiers.dart';
import 'package:domain/src/product/price.dart';
import 'package:domain/src/product/product.dart';
import 'package:domain/src/product/product_name.dart';
import 'package:domain/src/product/stock.dart';
import 'package:domain/src/result.dart';
import 'package:domain/src/user.dart';

bool canManageProduct(User user,Product product)=>
    user.role==UserRole.producer && user.id==product.producerId;

Result<Product>createProduct({
  required ProductId id,
  required User actor,
  required String name,
  required String description,
required ProductCategory category,
required ProductUnit unit,
required int priceDinar,
required int stockUnits,
}){
  if(actor.role!=UserRole.producer)
    {
      return Failure<Product>(NotAuthorized(actor.id));
    }

  final parsedName=ProductName.parse(name);
  final nameError=parsedName.errorOrNull;

  if(nameError != null ) return Failure<Product>(nameError);

  final parsedPrice=Price.parse(priceDinar);
  final priceError=parsedPrice.errorOrNull;
  if (priceError != null) return Failure<Product>(priceError);

  final parsedStock = Stock.parse(stockUnits);
  final stockError = parsedStock.errorOrNull;
  if (stockError != null) return Failure<Product>(stockError);

  return Success<Product>(
    Product(
      id: id,
      producerId: actor.id,
      name: parsedName.valueOrNull!,
      description: description.trim(),
      category: category,
      unit: unit,
      price: parsedPrice.valueOrNull!,
      stock:parsedStock.valueOrNull!,
    ),
  );
}


Result<Product>updatePrice(
Product product,
int dinar,
{required User actor,}
)
{
  if(!canManageProduct(actor, product))
    {
      return Failure<Product>(NotAuthorized(actor.id));
    }
  final parsed=Price.parse(dinar);
  final error=parsed.errorOrNull;
  if(error!=null)return Failure<Product>(error);
  return Success<Product>(product.copyWith(price: parsed.valueOrNull));
}


Result<Product>updateStock(
  Product product,
int units,
{required User actor,}
)
{
  if(!canManageProduct(actor, product))
    {
      return Failure<Product>(NotAuthorized(actor.id));
    }
  final parsed=Stock.parse(units);
  final error=parsed.errorOrNull;
  if(error!=null)return Failure<Product>(error);
  return Success<Product>(product.copyWith(stock: parsed.valueOrNull));
}


