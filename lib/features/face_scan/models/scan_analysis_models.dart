import 'package:flutter/foundation.dart';

/// Main model for the complete face scan API response
class ScanAnalysisResponse {
  final bool success;
  final String timestamp;
  final double processingTimeSeconds;
  final ConditionAnalysis conditionAnalysis;
  final SkinTypeAnalysis skinTypeAnalysis;
  final AreaDetectionAnalysis areaDetectionAnalysis;
  final List<RecommendationGroup> recommendations;
  final bool imageUploaded;
  final String? reportId; // Report ID for fetching detailed recommendations

  const ScanAnalysisResponse({
    required this.success,
    required this.timestamp,
    required this.processingTimeSeconds,
    required this.conditionAnalysis,
    required this.skinTypeAnalysis,
    required this.areaDetectionAnalysis,
    required this.recommendations,
    required this.imageUploaded,
    this.reportId,
  });

  factory ScanAnalysisResponse.fromJson(Map<String, dynamic> json) {
    try {
      final recommendationsData = json['recommendations'] as List<dynamic>? ?? [];
      final recommendations = recommendationsData
          .map((item) => RecommendationGroup.fromJson(item as Map<String, dynamic>))
          .toList();

      // Extract report_id directly from root level of response
      final reportId = json['report_id'] as String?;
      debugPrint('📝 Parsed report_id from API response: $reportId');

      return ScanAnalysisResponse(
        success: json['success'] as bool? ?? false,
        timestamp: json['timestamp'] as String? ?? '',
        processingTimeSeconds: (json['processing_time_seconds'] as num?)?.toDouble() ?? 0.0,
        conditionAnalysis: ConditionAnalysis.fromJson(
          json['condition_analysis'] as Map<String, dynamic>? ?? {},
        ),
        skinTypeAnalysis: SkinTypeAnalysis.fromJson(
          json['skin_type_analysis'] as Map<String, dynamic>? ?? {},
        ),
        areaDetectionAnalysis: AreaDetectionAnalysis.fromJson(
          json['area_detection_analysis'] as Map<String, dynamic>? ?? {},
        ),
        recommendations: recommendations,
        imageUploaded: json['image_uploaded'] as bool? ?? false,
        reportId: reportId,
      );
    } catch (e) {
      debugPrint('❌ Error parsing ScanAnalysisResponse: $e');
      rethrow;
    }
  }

  /// Get the primary detected condition
  String get primaryCondition => conditionAnalysis.prediction;

  /// Get confidence percentage for primary condition
  double get primaryConditionConfidence {
    if (conditionAnalysis.sortedPredictions.isNotEmpty) {
      return conditionAnalysis.sortedPredictions.first.confidence;
    }
    return 0.0;
  }

  /// Get all detected skin issues from recommendations
  List<String> get detectedSkinIssues {
    return recommendations.map((group) => group.skinIssue).toList();
  }
}

/// Model for condition analysis predictions
class ConditionAnalysis {
  final String prediction;
  final List<ConditionPrediction> sortedPredictions;

  const ConditionAnalysis({
    required this.prediction,
    required this.sortedPredictions,
  });

  factory ConditionAnalysis.fromJson(Map<String, dynamic> json) {
    final predictionsData = json['sorted_predictions'] as List<dynamic>? ?? [];
    final predictions = predictionsData
        .map((item) => ConditionPrediction.fromJson(item as List<dynamic>))
        .toList();

    return ConditionAnalysis(
      prediction: json['prediction'] as String? ?? '',
      sortedPredictions: predictions,
    );
  }

  /// Get top N predictions
  List<ConditionPrediction> getTopPredictions(int count) {
    return sortedPredictions.take(count).toList();
  }
}

/// Model for individual condition prediction
class ConditionPrediction {
  final String name;
  final double confidence;

  const ConditionPrediction({
    required this.name,
    required this.confidence,
  });

  factory ConditionPrediction.fromJson(List<dynamic> json) {
    if (json.length >= 2) {
      return ConditionPrediction(
        name: json[0] as String? ?? '',
        confidence: (json[1] as num?)?.toDouble() ?? 0.0,
      );
    }
    return const ConditionPrediction(name: '', confidence: 0.0);
  }

  /// Get confidence as percentage string
  String get confidencePercentage => '${confidence.toStringAsFixed(1)}%';

  /// Get display name for the condition
  String get displayName {
    switch (name.toLowerCase()) {
      case 'wrinkles':
        return 'Wrinkles';
      case 'eyebags':
        return 'Eye Bags';
      case 'oily-skin':
        return 'Oily Skin';
      case 'acne':
        return 'Acne';
      case 'blackheads':
        return 'Blackheads';
      case 'skin-redness':
        return 'Skin Redness';
      case 'dry-skin':
        return 'Dry Skin';
      case 'whiteheads':
        return 'Whiteheads';
      case 'dark-spots':
        return 'Dark Spots';
      case 'englarged-pores':
        return 'Enlarged Pores';
      default:
        return name.replaceAll('-', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }
}

/// Model for skin type analysis
class SkinTypeAnalysis {
  final String? error;
  final bool success;

  const SkinTypeAnalysis({
    this.error,
    required this.success,
  });

  factory SkinTypeAnalysis.fromJson(Map<String, dynamic> json) {
    return SkinTypeAnalysis(
      error: json['error'] as String?,
      success: json['success'] as bool? ?? false,
    );
  }
}

/// Model for area detection analysis (using existing DetectionResults)
class AreaDetectionAnalysis {
  final int totalDetections;
  final List<Detection> detections;
  final List<String> classesFound;
  final double modelThreshold;

  const AreaDetectionAnalysis({
    required this.totalDetections,
    required this.detections,
    required this.classesFound,
    required this.modelThreshold,
  });

  factory AreaDetectionAnalysis.fromJson(Map<String, dynamic> json) {
    final detectionsData = json['detections'] as List<dynamic>? ?? [];
    final detections = detectionsData
        .map((item) => Detection.fromJson(item as Map<String, dynamic>))
        .toList();

    final classesFoundData = json['classes_found'] as List<dynamic>? ?? [];
    final classesFound = classesFoundData
        .map((item) => item as String)
        .toList();

    return AreaDetectionAnalysis(
      totalDetections: json['total_detections'] as int? ?? 0,
      detections: detections,
      classesFound: classesFound,
      modelThreshold: (json['model_threshold'] as num?)?.toDouble() ?? 0.1,
    );
  }

  /// Get detections grouped by class
  Map<String, List<Detection>> get detectionsByClass {
    final Map<String, List<Detection>> grouped = {};
    for (final detection in detections) {
      grouped.putIfAbsent(detection.className, () => []).add(detection);
    }
    return grouped;
  }

  /// Get class counts
  Map<String, int> get classCounts {
    final Map<String, int> counts = {};
    for (final detection in detections) {
      counts[detection.className] = (counts[detection.className] ?? 0) + 1;
    }
    return counts;
  }
}

/// Model for recommendation groups
class RecommendationGroup {
  final String skinIssue;
  final List<ProductRecommendation> recommendations;

  const RecommendationGroup({
    required this.skinIssue,
    required this.recommendations,
  });

  factory RecommendationGroup.fromJson(Map<String, dynamic> json) {
    final recommendationsData = json['recommendations'] as List<dynamic>? ?? [];
    final recommendations = recommendationsData
        .map((item) => ProductRecommendation.fromJson(item as Map<String, dynamic>))
        .toList();

    return RecommendationGroup(
      skinIssue: json['skin_issue'] as String? ?? '',
      recommendations: recommendations,
    );
  }

  /// Get display name for skin issue matching Figma design
  String get displayName {
    switch (skinIssue.toLowerCase()) {
      case 'wrinkles':
        return 'Anti-aging + Fine Lines';
      case 'skin redness':
        return 'Redness & Irritation';
      case 'acne':
        return 'Acne & Breakouts';
      case 'dark spots':
      case 'hyperpigmentation':
        return 'Hyperpigmentation & Dark Spots';
      case 'dry skin':
      case 'dryness':
        return 'Dryness & Dehydration';
      case 'sensitivity':
      case 'reactive skin':
        return 'Sensitivity (Reactive skin)';
      case 'oily skin':
        return 'Oily Skin';
      case 'enlarged pores':
        return 'Enlarged Pores';
      case 'blackheads':
        return 'Blackheads';
      case 'whiteheads':
        return 'Whiteheads';
      default:
        // Fallback to capitalizing the skin issue name
        return skinIssue.split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }
}

/// Model for individual product recommendations
class ProductRecommendation {
  final String product;
  final String description;

  const ProductRecommendation({
    required this.product,
    required this.description,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      product: json['product'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// Get effectiveness level based on product name (mock data for UI)
  String get effectivenessLevel {
    // This is mock data for UI purposes - in real app this would come from API
    final productLower = product.toLowerCase();
    if (productLower.contains('retinol') || 
        productLower.contains('hyaluronic') ||
        productLower.contains('vitamin c')) {
      return 'Clinically Proven';
    }
    return 'Generally Effective';
  }

  /// Get effectiveness percentage (mock data for UI)
  int get effectivenessPercentage {
    // This is mock data for UI purposes - in real app this would come from API
    final productLower = product.toLowerCase();
    if (productLower.contains('hyaluronic') || productLower.contains('retinol')) {
      return 82;
    } else if (productLower.contains('glycerin') || productLower.contains('squalane')) {
      return 66;
    }
    return 70; // Default
  }

  /// Check if this is a clinically proven product
  bool get isClinicallyProven => effectivenessLevel == 'Clinically Proven';
}

// Import the existing Detection model from detection_models.dart
class Detection {
  final String className;
  final double confidence;
  final BoundingBox bbox;

  const Detection({
    required this.className,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['class'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      bbox: BoundingBox.fromJson(json['bbox'] as Map<String, dynamic>? ?? {}),
    );
  }

  String get displayName {
    switch (className.toLowerCase()) {
      case 'skin-redness':
        return 'Skin Redness';
      case 'wrinkles':
        return 'Wrinkles';
      default:
        return className.replaceAll('-', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}

class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: (json['x1'] as num?)?.toDouble() ?? 0.0,
      y1: (json['y1'] as num?)?.toDouble() ?? 0.0,
      x2: (json['x2'] as num?)?.toDouble() ?? 0.0,
      y2: (json['y2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}