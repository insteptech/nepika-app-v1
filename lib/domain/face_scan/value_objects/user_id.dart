import 'package:equatable/equatable.dart';

/// Value object representing a user identifier.
/// 
/// This ensures type safety and provides validation for user IDs,
/// preventing accidental misuse of string IDs throughout the application.
class UserId extends Equatable {
  final String value;

  const UserId._(this.value);

  /// Creates a UserId from a string value with validation
  factory UserId.fromString(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    
    // Basic format validation - adjust based on your user ID format
    if (value.trim().length < 3) {
      throw ArgumentError('User ID must be at least 3 characters');
    }
    
    return UserId._(value.trim());
  }

  /// Creates a UserId for testing purposes
  factory UserId.test(String value) {
    return UserId._(value);
  }

  /// Validates if a string is a valid user ID format
  static bool isValid(String value) {
    try {
      UserId.fromString(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;

  /// Returns the raw string value
  String get rawValue => value;

  /// Checks if this user ID equals another user ID
  bool equals(UserId other) => value == other.value;
}