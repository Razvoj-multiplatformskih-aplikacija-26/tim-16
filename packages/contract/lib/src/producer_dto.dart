import 'json.dart';

final class ProducerDto {
  const ProducerDto({required this.id, required this.fullName});

  factory ProducerDto.fromJson(JsonMap json) =>
      ProducerDto(id: json.read<String>('id'), fullName: json.read<String>('fullName'));

  final String id;
  final String fullName;

  JsonMap toJson() => {'id': id, 'fullName': fullName};
}
