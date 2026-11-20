import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

ProducerDto producerToDto(User user) => ProducerDto(id: user.id.value, fullName: user.fullName);

User producerFromDto(ProducerDto dto) =>
    User(id: UserId(dto.id), fullName: dto.fullName, role: UserRole.producer);
