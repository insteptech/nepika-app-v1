import 'dart:math';
import 'package:equatable/equatable.dart';

/// Value object representing a unique scan session identifier.
/// 
/// This ensures type safety and provides validation for session IDs,
/// preventing accidental misuse of string IDs throughout the application.
class ScanSessionId extends Equatable {
  final String value;

  const ScanSessionId._(this.value);

  /// Creates a ScanSessionId from a string value with validation
  factory ScanSessionId.fromString(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Session ID cannot be empty');
    }
    
    if (value.length < 8) {
      throw ArgumentError('Session ID must be at least 8 characters');
    }
    
    return ScanSessionId._(value.trim());
  }

  /// Generates a new unique session ID
  factory ScanSessionId.generate() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999).toString().padLeft(6, '0');
    final sessionId = 'scan_${timestamp}_$randomSuffix';
    return ScanSessionId._(sessionId);
  }

  /// Creates a ScanSessionId for testing purposes
  factory ScanSessionId.test(String value) {
    return ScanSessionId._(value);
  }

  /// Validates if a string is a valid session ID format
  static bool isValid(String value) {
    try {
      ScanSessionId.fromString(value);
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

  /// Checks if this session ID equals another session ID
  bool equals(ScanSessionId other) => value == other.value;
}