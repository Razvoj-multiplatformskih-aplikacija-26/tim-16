import 'json.dart';
import 'wire_time.dart';


final class LoginDto {
  const LoginDto({required this.username, required this.password, this.cookie = false});

  factory LoginDto.fromJson(JsonMap json) => LoginDto(
    username: json.read<String>('username'),
    password: json.read<String>('password'),
    cookie: json['cookie'] == true,
  );

  final String username;
  final String password;
  final bool cookie;

  JsonMap toJson() => {'username': username, 'password': password, 'cookie': cookie};

  @override
  String toString() => 'LoginDto($username)';
}

final class UserDto {
  const UserDto({required this.id, required this.fullName, required this.role});

  factory UserDto.fromJson(JsonMap json) => UserDto(
    id: json.read<String>('id'),
    fullName: json.read<String>('fullName'),
    role: json.read<String>('role'),
  );

  static const buyer = 'buyer';
  static const producer = 'producer';

  final String id;
  final String fullName;
  final String role;

  JsonMap toJson() => {'id': id, 'fullName': fullName, 'role': role};
}


final class SessionDto {
  const SessionDto({required this.user, required this.expiresAt, this.token});

  factory SessionDto.fromJson(JsonMap json) => SessionDto(
    user: UserDto.fromJson(json.readObject('user')),
    expiresAt: json.readTime('expiresAt'),
    token: json.readOptional<String>('token'),
  );

  final UserDto user;
  final DateTime expiresAt;
  final String? token;

  JsonMap toJson() => {
    'user': user.toJson(),
    'expiresAt': encodeTime(expiresAt),
    'token': ?token,
  };
}