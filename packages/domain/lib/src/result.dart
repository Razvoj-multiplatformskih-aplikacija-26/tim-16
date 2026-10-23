import 'package:meta/meta.dart';

import 'errors.dart';

sealed class Result<T> {
  const Result();

  T? get valueOrNull;

  DomainError? get errorOrNull;

  bool get isSuccess => this is Success<T>;
}

@immutable
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  T? get valueOrNull => value;

  @override
  DomainError? get errorOrNull => null;

  @override
  bool operator ==(Object other) =>
      other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success($value)';
}

@immutable
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final DomainError error;

  @override
  T? get valueOrNull => null;

  @override
  DomainError? get errorOrNull => error;

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.error == error;

  @override
  int get hashCode => Object.hash(Failure, error);

  @override
  String toString() => 'Failure($error)';
}