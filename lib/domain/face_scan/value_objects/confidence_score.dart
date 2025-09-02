import 'package:equatable/equatable.dart';

/// Value object representing a confidence score (0.0 to 1.0).
/// 
/// This ensures type safety and validation for confidence values used
/// throughout the face scanning domain, such as skin condition predictions
/// and face alignment confidence scores.
class ConfidenceScore extends Equatable {
  final double value;

  const ConfidenceScore._(this.value);

  /// Creates a ConfidenceScore from a double value with validation
  factory ConfidenceScore.fromDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      throw ArgumentError('Confidence score must be a valid number');
    }
    
    if (value < 0.0 || value > 1.0) {
      throw ArgumentError('Confidence score must be between 0.0 and 1.0, got: $value');
    }
    
    return ConfidenceScore._(value);
  }

  /// Creates a ConfidenceScore from a percentage (0-100)
  factory ConfidenceScore.fromPercentage(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) {
      throw ArgumentError('Confidence percentage must be a valid number');
    }
    
    if (percentage < 0.0 || percentage > 100.0) {
      throw ArgumentError('Confidence percentage must be between 0 and 100, got: $percentage');
    }
    
    return ConfidenceScore._(percentage / 100.0);
  }

  /// Creates a zero confidence score
  factory ConfidenceScore.zero() => const ConfidenceScore._(0.0);

  /// Creates a maximum confidence score
  factory ConfidenceScore.max() => const ConfidenceScore._(1.0);

  /// Creates a medium confidence score (0.5)
  factory ConfidenceScore.medium() => const ConfidenceScore._(0.5);

  /// Validates if a double is a valid confidence score
  static bool isValidDouble(double value) {
    return !value.isNaN && !value.isInfinite && value >= 0.0 && value <= 1.0;
  }

  /// Validates if a percentage is valid for confidence score
  static bool isValidPercentage(double percentage) {
    return !percentage.isNaN && !percentage.isInfinite && percentage >= 0.0 && percentage <= 100.0;
  }

  /// Gets the confidence as a percentage (0-100)
  double get asPercentage => value * 100.0;

  /// Gets the confidence as an integer percentage (0-100)
  int get asIntPercentage => (value * 100.0).round();

  /// Checks if this is a high confidence score (>= 0.8)
  bool get isHigh => value >= 0.8;

  /// Checks if this is a medium confidence score (0.5 <= score < 0.8)
  bool get isMedium => value >= 0.5 && value < 0.8;

  /// Checks if this is a low confidence score (< 0.5)
  bool get isLow => value < 0.5;

  /// Checks if this confidence meets a minimum threshold
  bool meetsThreshold(double threshold) {
    return value >= threshold;
  }

  /// Combines this confidence with another using multiplication
  /// (commonly used for combining independent probabilities)
  ConfidenceScore combineWith(ConfidenceScore other) {
    return ConfidenceScore._(value * other.value);
  }

  /// Gets the complement of this confidence (1.0 - value)
  ConfidenceScore get complement => ConfidenceScore._(1.0 - value);

  /// Compares this confidence with another
  int compareTo(ConfidenceScore other) {
    return value.compareTo(other.value);
  }

  /// Checks if this confidence is greater than another
  bool isGreaterThan(ConfidenceScore other) => value > other.value;

  /// Checks if this confidence is less than another
  bool isLessThan(ConfidenceScore other) => value < other.value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => '${asIntPercentage}%';

  /// Returns the raw double value
  double get rawValue => value;

  /// Returns a formatted string with specified decimal places
  String toStringWithPrecision(int decimalPlaces) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }
}