import 'json.dart';

final class MoneyDto {
  const MoneyDto(this.amount, {this.currency = rsd});

  factory MoneyDto.fromJson(JsonMap json) =>
      MoneyDto(json.read<int>('amount'), currency: json.read<String>('currency'));

  static const rsd = 'RSD';

  final int amount;
  final String currency;

  JsonMap toJson() => {'amount': amount, 'currency': currency};

  @override
  bool operator ==(Object other) =>
      other is MoneyDto && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => '$amount $currency';
}
