import 'package:equatable/equatable.dart';

/// Entity representing the skin condition analysis results from the AI model.
/// Contains both individual skin area analysis and overall skin condition predictions.
class SkinAnalysis extends Equatable {
  /// Analysis of different skin areas (e.g., forehead, cheeks, nose, chin)
  final Map<String, SkinAreaAnalysis> skinAreas;
  
  /// Overall skin condition predictions with confidence percentages
  final Map<String, double> skinConditionPredictions;
  
  /// Overall skin score (0-100)
  final double overallSkinScore;
  
  /// Dominant skin condition identified by the AI
  final String dominantCondition;
  
  /// Confidence level for the dominant condition (0-1)
  final double dominantConditionConfidence;
  
  /// Additional insights or recommendations
  final List<String> insights;

  const SkinAnalysis({
    required this.skinAreas,
    required this.skinConditionPredictions,
    required this.overallSkinScore,
    required this.dominantCondition,
    required this.dominantConditionConfidence,
    required this.insights,
  });

  /// Creates a copy of this SkinAnalysis with the given fields replaced with new values
  SkinAnalysis copyWith({
    Map<String, SkinAreaAnalysis>? skinAreas,
    Map<String, double>? skinConditionPredictions,
    double? overallSkinScore,
    String? dominantCondition,
    double? dominantConditionConfidence,
    List<String>? insights,
  }) {
    return SkinAnalysis(
      skinAreas: skinAreas ?? this.skinAreas,
      skinConditionPredictions: skinConditionPredictions ?? this.skinConditionPredictions,
      overallSkinScore: overallSkinScore ?? this.overallSkinScore,
      dominantCondition: dominantCondition ?? this.dominantCondition,
      dominantConditionConfidence: dominantConditionConfidence ?? this.dominantConditionConfidence,
      insights: insights ?? this.insights,
    );
  }

  /// Creates an empty SkinAnalysis for failed scans
  factory SkinAnalysis.empty() {
    return const SkinAnalysis(
      skinAreas: {},
      skinConditionPredictions: {},
      overallSkinScore: 0.0,
      dominantCondition: '',
      dominantConditionConfidence: 0.0,
      insights: [],
    );
  }

  /// Gets the top N skin conditions sorted by confidence
  List<SkinConditionPrediction> getTopConditions([int limit = 3]) {
    final sorted = skinConditionPredictions.entries
        .map((e) => SkinConditionPrediction(
              condition: e.key,
              confidence: e.value,
            ))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return sorted.take(limit).toList();
  }

  /// Checks if the analysis indicates healthy skin (score > 80 and no major issues)
  bool get isHealthySkin {
    return overallSkinScore > 80 && 
           dominantConditionConfidence < 0.5;
  }

  /// Gets all skin areas with issues (confidence > 0.3)
  List<SkinAreaAnalysis> get problemAreas {
    return skinAreas.values
        .where((area) => area.hasSignificantIssues)
        .toList();
  }

  @override
  List<Object?> get props => [
        skinAreas,
        skinConditionPredictions,
        overallSkinScore,
        dominantCondition,
        dominantConditionConfidence,
        insights,
      ];

  @override
  String toString() {
    return 'SkinAnalysis('
        'skinAreas: ${skinAreas.length} areas, '
        'skinConditionPredictions: ${skinConditionPredictions.length} conditions, '
        'overallSkinScore: $overallSkinScore, '
        'dominantCondition: $dominantCondition, '
        'dominantConditionConfidence: $dominantConditionConfidence, '
        'insights: ${insights.length} insights'
        ')';
  }
}

/// Represents analysis results for a specific skin area
class SkinAreaAnalysis extends Equatable {
  /// Name of the skin area (e.g., "forehead", "left_cheek", "nose")
  final String areaName;
  
  /// Bounding box coordinates for this area in the image
  final SkinAreaBounds bounds;
  
  /// Specific issues detected in this area with confidence scores
  final Map<String, double> detectedIssues;
  
  /// Overall condition score for this area (0-100)
  final double areaScore;
  
  /// Primary issue in this area
  final String? primaryIssue;
  
  /// Severity level: low, medium, high
  final SkinIssueSeverity severity;

  const SkinAreaAnalysis({
    required this.areaName,
    required this.bounds,
    required this.detectedIssues,
    required this.areaScore,
    this.primaryIssue,
    required this.severity,
  });

  /// Creates a copy of this SkinAreaAnalysis with the given fields replaced with new values
  SkinAreaAnalysis copyWith({
    String? areaName,
    SkinAreaBounds? bounds,
    Map<String, double>? detectedIssues,
    double? areaScore,
    String? primaryIssue,
    SkinIssueSeverity? severity,
  }) {
    return SkinAreaAnalysis(
      areaName: areaName ?? this.areaName,
      bounds: bounds ?? this.bounds,
      detectedIssues: detectedIssues ?? this.detectedIssues,
      areaScore: areaScore ?? this.areaScore,
      primaryIssue: primaryIssue ?? this.primaryIssue,
      severity: severity ?? this.severity,
    );
  }

  /// Checks if this area has significant issues (any issue with confidence > 0.3)
  bool get hasSignificantIssues {
    return detectedIssues.values.any((confidence) => confidence > 0.3);
  }

  @override
  List<Object?> get props => [
        areaName,
        bounds,
        detectedIssues,
        areaScore,
        primaryIssue,
        severity,
      ];

  @override
  String toString() {
    return 'SkinAreaAnalysis('
        'areaName: $areaName, '
        'bounds: $bounds, '
        'detectedIssues: ${detectedIssues.length} issues, '
        'areaScore: $areaScore, '
        'primaryIssue: $primaryIssue, '
        'severity: $severity'
        ')';
  }
}

/// Represents bounding box coordinates for a skin area
class SkinAreaBounds extends Equatable {
  final double x;
  final double y;
  final double width;
  final double height;

  const SkinAreaBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Creates a copy of this SkinAreaBounds with the given fields replaced with new values
  SkinAreaBounds copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return SkinAreaBounds(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [x, y, width, height];

  @override
  String toString() {
    return 'SkinAreaBounds(x: $x, y: $y, width: $width, height: $height)';
  }
}

/// Represents a skin condition prediction with confidence score
class SkinConditionPrediction extends Equatable {
  final String condition;
  final double confidence;

  const SkinConditionPrediction({
    required this.condition,
    required this.confidence,
  });

  /// Gets the confidence as a percentage (0-100)
  int get confidencePercentage => (confidence * 100).round();

  @override
  List<Object?> get props => [condition, confidence];

  @override
  String toString() {
    return 'SkinConditionPrediction(condition: $condition, confidence: $confidence)';
  }
}

/// Enum representing the severity levels of skin issues
enum SkinIssueSeverity {
  low,
  medium,
  high;

  /// Gets a human-readable description of the severity
  String get description {
    switch (this) {
      case SkinIssueSeverity.low:
        return 'Low';
      case SkinIssueSeverity.medium:
        return 'Medium';
      case SkinIssueSeverity.high:
        return 'High';
    }
  }

  /// Creates severity from a confidence score
  static SkinIssueSeverity fromConfidence(double confidence) {
    if (confidence >= 0.7) return SkinIssueSeverity.high;
    if (confidence >= 0.4) return SkinIssueSeverity.medium;
    return SkinIssueSeverity.low;
  }
}