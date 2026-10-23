import 'package:equatable/equatable.dart';

import 'identifiers.dart';

enum UserRole {buyer,producer}

final class User extends Equatable{
  const User({required this.id,required this.fullName,required this.role});
  final UserId id;
  final String fullName;
  final UserRole role;


  @override
  List<Object?> get props => [id, fullName, role];
}