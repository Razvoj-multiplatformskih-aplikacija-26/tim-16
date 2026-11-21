import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

UserDto userToDto(User user) =>
    UserDto(id: user.id.value, fullName: user.fullName, role: roleCode(user.role));

User userFromDto(UserDto dto) =>
    User(id: UserId(dto.id), fullName: dto.fullName, role: roleFromCode(dto.role));

String roleCode(UserRole role) => switch (role) {
  UserRole.buyer => UserDto.buyer,
  UserRole.producer => UserDto.producer,
};

UserRole roleFromCode(String code) => switch (code) {
  UserDto.buyer => UserRole.buyer,
  UserDto.producer => UserRole.producer,
  _ => throw WireFormatException('Nepoznata uloga "$code"'),
};