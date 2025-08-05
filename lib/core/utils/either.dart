import '../error/failures.dart';

/// Represents a value that can be either a failure or a success
abstract class Either<L, R> {
  const Either();

  /// Returns true if this is a Left (failure)
  bool get isLeft;
  
  /// Returns true if this is a Right (success)
  bool get isRight => !isLeft;

  /// Returns the left value or null
  L? get left;
  
  /// Returns the right value or null
  R? get right;

  /// Transforms the right value
  Either<L, U> map<U>(U Function(R) mapper);

  /// Transforms the left value
  Either<U, R> mapLeft<U>(U Function(L) mapper);

  /// Executes a function based on the value type
  T fold<T>(T Function(L) onLeft, T Function(R) onRight);
}

class Left<L, R> extends Either<L, R> {
  final L _value;

  const Left(this._value);

  @override
  bool get isLeft => true;

  @override
  L get left => _value;

  @override
  R? get right => null;

  @override
  Either<L, U> map<U>(U Function(R) mapper) => Left(_value);

  @override
  Either<U, R> mapLeft<U>(U Function(L) mapper) => Left(mapper(_value));

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onLeft(_value);

  @override
  String toString() => 'Left($_value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

class Right<L, R> extends Either<L, R> {
  final R _value;

  const Right(this._value);

  @override
  bool get isLeft => false;

  @override
  L? get left => null;

  @override
  R get right => _value;

  @override
  Either<L, U> map<U>(U Function(R) mapper) => Right(mapper(_value));

  @override
  Either<U, R> mapLeft<U>(U Function(L) mapper) => Right(_value);

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onRight(_value);

  @override
  String toString() => 'Right($_value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

/// Type alias for cleaner syntax
typedef Result<T> = Either<Failure, T>;

/// Helper functions for creating Either instances
Either<L, R> left<L, R>(L value) => Left(value);
Either<L, R> right<L, R>(R value) => Right(value);

/// Helper functions for creating Result instances
Result<T> failure<T>(Failure f) => Left(f);
Result<T> success<T>(T value) => Right(value);
