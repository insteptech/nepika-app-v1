import 'package:flutter/material.dart';

enum SeverityLevel {
  clear,
  mild,
  moderate,
  high,
  severe,
}

class SeverityAnalyzer {
  // Configurable thresholds for smoothing and variance
  static const double emaAlpha = 0.25;
  static const double hysteresisBuffer = 3.0;
  static const double varianceLowConfidenceThreshold = 15.0;
  static const double ttaVarianceThreshold = 8.0;

  /// Determines the severity level based on a raw score (0-100).
  ///
  /// Bands:
  /// - Clear: 0 - 15
  /// - Mild: 16 - 35
  /// - Moderate: 36 - 60
  /// - High: 61 - 80
  /// - Severe: 81 - 100
  static SeverityLevel getSeverity(double score) {
    if (score <= 15) return SeverityLevel.clear;
    if (score <= 35) return SeverityLevel.mild;
    if (score <= 60) return SeverityLevel.moderate;
    if (score <= 80) return SeverityLevel.high;
    return SeverityLevel.severe;
  }

  /// Calculates Exponential Moving Average (EMA) smoothed score
  static double calculateSmoothedScore(double currentScore, double? previousSmoothedScore) {
    if (previousSmoothedScore == null) return currentScore;
    return (currentScore * emaAlpha) + (previousSmoothedScore * (1.0 - emaAlpha));
  }

  /// Determines severity level applying a hysteresis buffer 
  /// to prevent flip-flopping near threshold boundaries
  static SeverityLevel getSeverityWithHysteresis(double currentScore, SeverityLevel? previousLevel) {
    if (previousLevel == null) return getSeverity(currentScore);

    double lowerBound = 0.0;
    double upperBound = 100.0;

    switch (previousLevel) {
      case SeverityLevel.clear:
        upperBound = 15.0;
        break;
      case SeverityLevel.mild:
        lowerBound = 16.0;
        upperBound = 35.0;
        break;
      case SeverityLevel.moderate:
        lowerBound = 36.0;
        upperBound = 60.0;
        break;
      case SeverityLevel.high:
        lowerBound = 61.0;
        upperBound = 80.0;
        break;
      case SeverityLevel.severe:
        lowerBound = 81.0;
        break;
    }

    // Moving to a better (lower) score
    if (currentScore < lowerBound && currentScore <= lowerBound - hysteresisBuffer) {
      return getSeverity(currentScore);
    }
    
    // Moving to a worse (higher) score
    if (currentScore > upperBound && currentScore >= upperBound + hysteresisBuffer) {
      return getSeverity(currentScore);
    }

    return previousLevel;
  }

  /// Returns the display label for the severity level.
  static String getLabel(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.clear:
        return 'Clear';
      case SeverityLevel.mild:
        return 'Mild';
      case SeverityLevel.moderate:
        return 'Moderate';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.severe:
        return 'Severe';
    }
  }

  /// Returns the icon associated with the severity level.
  static String getIcon(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.clear:
        return '😊';
      case SeverityLevel.mild:
        return '🙂';
      case SeverityLevel.moderate:
        return '😐';
      case SeverityLevel.high:
        return '😟';
      case SeverityLevel.severe:
        return '😰';
    }
  }

  /// Returns the color associated with the severity level.
  static Color getColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.clear:
        return const Color(0xFF4CAF50); // Green
      case SeverityLevel.mild:
        return const Color(0xFFFFEB3B); // Yellow
      case SeverityLevel.moderate:
        return const Color(0xFFFF9800); // Orange
      case SeverityLevel.high:
        return const Color(0xFFFF5722); // Deep Orange
      case SeverityLevel.severe:
        return const Color(0xFFD32F2F); // Red
    }
  }

  /// Helper to get label directly from score
  static String getLabelFromScore(double score) {
    return getLabel(getSeverity(score));
  }

  /// Helper to get color directly from score
  static Color getColorFromScore(double score) {
    return getColor(getSeverity(score));
  }

  /// Helper to get icon directly from score
  static String getIconFromScore(double score) {
    return getIcon(getSeverity(score));
  }
}
