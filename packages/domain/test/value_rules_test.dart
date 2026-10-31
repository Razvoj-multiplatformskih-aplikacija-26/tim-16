import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';


void main() {
  group('Price.parse', () {
    test('prihvata cenu u opsegu', () {
      expect(Price.parse(250).valueOrNull?.dinars, 250);
    });
    test('odbija nulu, negativnu i preveliku cenu', () {
      expect(Price.parse(0).errorOrNull, isA<PriceOutOfRange>());
      expect(Price.parse(-5).errorOrNull, isA<PriceOutOfRange>());
      expect(Price.parse(Price.max + 1).errorOrNull, isA<PriceOutOfRange>());
    });
  });

  group('Stock.parse', () {
    test('nula je dozvoljena zaliha', () {
      expect(Stock.parse(0).valueOrNull, Stock.empty);
    });
    test('odbija negativnu zalihu', () {
      expect(Stock.parse(-1).errorOrNull, isA<StockOutOfRange>());
    });
    test('odbija preveliku zalihu', () {
      expect(Stock.parse(Stock.max + 1).errorOrNull, isA<StockOutOfRange>());
    });
  });

  group('ProductName.parse', () {
    test('uklanja razmake sa ivica', () {
      expect(ProductName.parse('  Med  ').valueOrNull?.value, 'Med');
    });
    test('odbija prekratak naziv', () {
      final error = ProductName.parse('A').errorOrNull;
      expect(error, isA<TextLengthInvalid>());
      expect((error! as TextLengthInvalid).kind, TextKind.productName);
    });
    test('odbija predugačak naziv', () {
      expect(
        ProductName.parse('x' * 61).errorOrNull,
        isA<TextLengthInvalid>(),
      );
    });
  });

  group('DeliveryAddress.parse', () {
    test('prihvata uobičajenu adresu', () {
      expect(
        DeliveryAddress.parse('Knez Mihailova 5, Beograd').isSuccess,
        isTrue,
      );
    });
    test('odbija prekratku adresu', () {
      final error = DeliveryAddress.parse('ab').errorOrNull;
      expect((error! as TextLengthInvalid).kind, TextKind.deliveryAddress);
    });
  });

  group('createProduct / updatePrice / updateStock', () {
    test('proizvođač pravi proizvod', () {
      final r = createProduct(
        id: const ProductId('p9'),
        actor: producer,
        name: 'Domaći med',
        description: ' Bagremov ',
        category: ProductCategory.honey,
        unit: ProductUnit.jar,
        priceDinars: 900,
        stockUnits: 20,
      );
      final product = r.valueOrNull!;
      expect(product.producerId, producer.id);
      expect(product.description, 'Bagremov');
      expect(product.isAvailable, isTrue);
    });

    test('kupac ne može da napravi proizvod', () {
      final r = createProduct(
        id: const ProductId('p9'),
        actor: buyer,
        name: 'Domaći med',
        description: '',
        category: ProductCategory.honey,
        unit: ProductUnit.jar,
        priceDinars: 900,
        stockUnits: 20,
      );
      expect(r.errorOrNull, isA<NotAuthorized>());
    });

    test('nevalidna cena i zaliha se odbijaju', () {
      Result<Product> make({required int price, required int stock}) =>
          createProduct(
            id: const ProductId('p9'),
            actor: producer,
            name: 'Domaći med',
            description: '',
            category: ProductCategory.honey,
            unit: ProductUnit.jar,
            priceDinars: price,
            stockUnits: stock,
          );
      expect(make(price: 0, stock: 5).errorOrNull, isA<PriceOutOfRange>());
      expect(make(price: 100, stock: -1).errorOrNull, isA<StockOutOfRange>());
    });

    test('tuđi proizvod ne može da se menja', () {
      final product = makeProduct();
      expect(
        updatePrice(product, 300, actor: otherProducer).errorOrNull,
        isA<NotAuthorized>(),
      );
      expect(
        updateStock(product, 5, actor: otherProducer).errorOrNull,
        isA<NotAuthorized>(),
      );
    });

    test('vlasnik menja cenu i zalihu', () {
      final product = makeProduct();
      expect(
        updatePrice(product, 300, actor: producer).valueOrNull?.price.dinars,
        300,
      );
      expect(
        updateStock(product, 0, actor: producer).valueOrNull?.isAvailable,
        isFalse,
      );
    });
  });
}
