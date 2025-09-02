import 'package:equatable/equatable.dart';

/// Value object representing a skin health score (0-100).
/// 
/// This ensures type safety and provides validation for skin scores used
/// throughout the face scanning domain, such as overall skin score and
/// area-specific scores.
class SkinScore extends Equatable {
  final double value;

  const SkinScore._(this.value);

  /// Creates a SkinScore from a double value with validation
  factory SkinScore.fromDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      throw ArgumentError('Skin score must be a valid number');
    }
    
    if (value < 0.0 || value > 100.0) {
      throw ArgumentError('Skin score must be between 0.0 and 100.0, got: $value');
    }
    
    return SkinScore._(value);
  }

  /// Creates a SkinScore from an integer value
  factory SkinScore.fromInt(int value) {
    if (value < 0 || value > 100) {
      throw ArgumentError('Skin score must be between 0 and 100, got: $value');
    }
    
    return SkinScore._(value.toDouble());
  }

  /// Creates a zero skin score (worst)
  factory SkinScore.zero() => const SkinScore._(0.0);

  /// Creates a perfect skin score (best)
  factory SkinScore.perfect() => const SkinScore._(100.0);

  /// Creates a good skin score (80)
  factory SkinScore.good() => const SkinScore._(80.0);

  /// Creates a fair skin score (60)
  factory SkinScore.fair() => const SkinScore._(60.0);

  /// Creates a poor skin score (40)
  factory SkinScore.poor() => const SkinScore._(40.0);

  /// Validates if a double is a valid skin score
  static bool isValidDouble(double value) {
    return !value.isNaN && !value.isInfinite && value >= 0.0 && value <= 100.0;
  }

  /// Validates if an integer is a valid skin score
  static bool isValidInt(int value) {
    return value >= 0 && value <= 100;
  }

  /// Gets the score as an integer (0-100)
  int get asInt => value.round();

  /// Gets the score category based on value ranges
  SkinScoreCategory get category {
    if (value >= 90) return SkinScoreCategory.excellent;
    if (value >= 80) return SkinScoreCategory.good;
    if (value >= 60) return SkinScoreCategory.fair;
    if (value >= 40) return SkinScoreCategory.poor;
    return SkinScoreCategory.critical;
  }

  /// Gets a human-readable description of the score
  String get description => category.description;

  /// Checks if this is an excellent score (>= 90)
  bool get isExcellent => value >= 90;

  /// Checks if this is a good score (>= 80)
  bool get isGood => value >= 80;

  /// Checks if this is a fair score (>= 60)
  bool get isFair => value >= 60;

  /// Checks if this is a poor score (>= 40)
  bool get isPoor => value >= 40 && value < 60;

  /// Checks if this is a critical score (< 40)
  bool get isCritical => value < 40;

  /// Checks if this score meets a minimum threshold
  bool meetsThreshold(double threshold) {
    return value >= threshold;
  }

  /// Calculates the improvement from another score
  double improvementFrom(SkinScore other) {
    return value - other.value;
  }

  /// Calculates the percentage improvement from another score
  double percentageImprovementFrom(SkinScore other) {
    if (other.value == 0) return value > 0 ? double.infinity : 0.0;
    return ((value - other.value) / other.value) * 100.0;
  }

  /// Compares this score with another
  int compareTo(SkinScore other) {
    return value.compareTo(other.value);
  }

  /// Checks if this score is better than another
  bool isBetterThan(SkinScore other) => value > other.value;

  /// Checks if this score is worse than another
  bool isWorseThan(SkinScore other) => value < other.value;

  /// Gets the distance from perfect score
  double get distanceFromPerfect => 100.0 - value;

  /// Gets the normalized score (0.0 to 1.0)
  double get normalized => value / 100.0;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => '${asInt}/100';

  /// Returns the raw double value
  double get rawValue => value;

  /// Returns a formatted string with specified decimal places
  String toStringWithPrecision(int decimalPlaces) {
    return '${value.toStringAsFixed(decimalPlaces)}/100';
  }
}

/// Categories for skin scores
enum SkinScoreCategory {
  excellent,
  good,
  fair,
  poor,
  critical;

  /// Gets a human-readable description for each category
  String get description {
    switch (this) {
      case SkinScoreCategory.excellent:
        return 'Excellent skin health';
      case SkinScoreCategory.good:
        return 'Good skin condition';
      case SkinScoreCategory.fair:
        return 'Fair skin condition';
      case SkinScoreCategory.poor:
        return 'Poor skin condition';
      case SkinScoreCategory.critical:
        return 'Critical skin concerns';
    }
  }

  /// Gets the color typically associated with each category
  String get colorHex {
    switch (this) {
      case SkinScoreCategory.excellent:
        return '#4CAF50'; // Green
      case SkinScoreCategory.good:
        return '#8BC34A'; // Light Green
      case SkinScoreCategory.fair:
        return '#FFC107'; // Amber
      case SkinScoreCategory.poor:
        return '#FF9800'; // Orange
      case SkinScoreCategory.critical:
        return '#F44336'; // Red
    }
  }

  /// Gets the minimum score for this category
  int get minScore {
    switch (this) {
      case SkinScoreCategory.excellent:
        return 90;
      case SkinScoreCategory.good:
        return 80;
      case SkinScoreCategory.fair:
        return 60;
      case SkinScoreCategory.poor:
        return 40;
      case SkinScoreCategory.critical:
        return 0;
    }
  }

  /// Gets the maximum score for this category
  int get maxScore {
    switch (this) {
      case SkinScoreCategory.excellent:
        return 100;
      case SkinScoreCategory.good:
        return 89;
      case SkinScoreCategory.fair:
        return 79;
      case SkinScoreCategory.poor:
        return 59;
      case SkinScoreCategory.critical:
        return 39;
    }
  }
}