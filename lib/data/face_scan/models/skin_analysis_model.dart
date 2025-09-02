import '../../../domain/face_scan/entities/skin_analysis.dart';

/// Data model for skin analysis results from the API.
/// Handles conversion between API JSON structure and domain entities.
class SkinAnalysisModel {
  /// Raw API response data for skin condition analysis
  final Map<String, dynamic> skinConditionData;
  
  /// Raw API response data for skin areas analysis
  final Map<String, dynamic> skinAreasData;
  
  /// Overall confidence scores for all predictions
  final Map<String, dynamic> allPredictions;
  
  /// Primary skin condition identified
  final String? primaryCondition;
  
  /// Confidence for the primary condition
  final double? primaryConfidence;

  const SkinAnalysisModel({
    required this.skinConditionData,
    required this.skinAreasData,
    required this.allPredictions,
    this.primaryCondition,
    this.primaryConfidence,
  });

  /// Creates a SkinAnalysisModel from API analysis JSON
  factory SkinAnalysisModel.fromJson(Map<String, dynamic> json) {
    final skinCondition = json['skin_condition'] as Map<String, dynamic>? ?? {};
    final skinAreas = json['skin_areas'] as Map<String, dynamic>? ?? {};
    final allPredictions = skinCondition['all_predictions'] as Map<String, dynamic>? ?? {};
    
    // Find the primary condition (highest confidence)
    String? primaryCondition;
    double? primaryConfidence;
    
    if (allPredictions.isNotEmpty) {
      double maxConfidence = 0.0;
      for (final entry in allPredictions.entries) {
        final confidence = (entry.value as num).toDouble();
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          primaryCondition = entry.key;
          primaryConfidence = confidence / 100.0; // Convert percentage to 0-1
        }
      }
    }

    return SkinAnalysisModel(
      skinConditionData: skinCondition,
      skinAreasData: skinAreas,
      allPredictions: allPredictions,
      primaryCondition: primaryCondition,
      primaryConfidence: primaryConfidence,
    );
  }

  /// Creates empty model for failed analysis
  factory SkinAnalysisModel.empty() {
    return const SkinAnalysisModel(
      skinConditionData: {},
      skinAreasData: {},
      allPredictions: {},
    );
  }

  /// Converts to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'skin_condition': skinConditionData,
      'skin_areas': skinAreasData,
      'all_predictions': allPredictions,
      'primary_condition': primaryCondition,
      'primary_confidence': primaryConfidence,
    };
  }

  /// Converts to domain entity
  SkinAnalysis toEntity() {
    if (allPredictions.isEmpty) {
      return SkinAnalysis.empty();
    }

    // Convert all predictions to confidence map (0-1 scale)
    final skinConditionPredictions = <String, double>{};
    for (final entry in allPredictions.entries) {
      skinConditionPredictions[entry.key] = (entry.value as num).toDouble() / 100.0;
    }

    // Calculate overall skin score (inverse of highest issue confidence)
    double overallScore = 100.0;
    if (primaryConfidence != null) {
      // Higher confidence in skin issues means lower overall score
      overallScore = (1.0 - primaryConfidence!) * 100.0;
    }

    // Parse skin areas (for now, create empty areas since API structure varies)
    final skinAreas = <String, SkinAreaAnalysis>{};
    
    // Extract insights from the analysis
    final insights = _extractInsights();

    return SkinAnalysis(
      skinAreas: skinAreas,
      skinConditionPredictions: skinConditionPredictions,
      overallSkinScore: overallScore,
      dominantCondition: primaryCondition ?? '',
      dominantConditionConfidence: primaryConfidence ?? 0.0,
      insights: insights,
    );
  }

  /// Extracts insights and recommendations from the analysis data
  List<String> _extractInsights() {
    final insights = <String>[];
    
    // Add insights based on predictions
    if (primaryCondition != null && primaryConfidence != null) {
      if (primaryConfidence! > 0.7) {
        insights.add('High confidence detection of $primaryCondition');
      } else if (primaryConfidence! > 0.4) {
        insights.add('Moderate signs of $primaryCondition detected');
      }
    }
    
    // Add general recommendations based on top conditions
    final sortedPredictions = allPredictions.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    
    for (final entry in sortedPredictions.take(3)) {
      final condition = entry.key.toLowerCase();
      final confidence = (entry.value as num).toDouble();
      
      if (confidence > 30) { // Only include significant predictions
        if (condition.contains('acne')) {
          insights.add('Consider using non-comedogenic skincare products');
        } else if (condition.contains('dark')) {
          insights.add('Sun protection and brightening serums may help');
        } else if (condition.contains('wrinkle') || condition.contains('aging')) {
          insights.add('Anti-aging ingredients like retinoids may be beneficial');
        } else if (condition.contains('dry')) {
          insights.add('Focus on moisturizing and hydrating products');
        } else if (condition.contains('oil')) {
          insights.add('Oil-control products and regular cleansing recommended');
        }
      }
    }
    
    // Ensure we have at least one insight
    if (insights.isEmpty) {
      insights.add('Maintain a consistent skincare routine for optimal skin health');
    }
    
    return insights;
  }

  /// Gets all skin conditions sorted by confidence
  List<MapEntry<String, double>> getSortedPredictions() {
    final predictions = allPredictions.entries
        .map((entry) => MapEntry(entry.key, (entry.value as num).toDouble()))
        .toList();
    
    predictions.sort((a, b) => b.value.compareTo(a.value));
    return predictions;
  }

  /// Checks if the analysis indicates healthy skin
  bool get isHealthySkin {
    return primaryConfidence == null || primaryConfidence! < 0.3;
  }

  /// Gets the annotated image base64 string if available
  String? get annotatedImageBase64 {
    return skinAreasData['annotated_image'] as String?;
  }

  /// Creates a copy with updated fields
  SkinAnalysisModel copyWith({
    Map<String, dynamic>? skinConditionData,
    Map<String, dynamic>? skinAreasData,
    Map<String, dynamic>? allPredictions,
    String? primaryCondition,
    double? primaryConfidence,
  }) {
    return SkinAnalysisModel(
      skinConditionData: skinConditionData ?? this.skinConditionData,
      skinAreasData: skinAreasData ?? this.skinAreasData,
      allPredictions: allPredictions ?? this.allPredictions,
      primaryCondition: primaryCondition ?? this.primaryCondition,
      primaryConfidence: primaryConfidence ?? this.primaryConfidence,
    );
  }

  @override
  String toString() {
    return 'SkinAnalysisModel('
        'primaryCondition: $primaryCondition, '
        'primaryConfidence: $primaryConfidence, '
        'predictionsCount: ${allPredictions.length}, '
        'hasAnnotatedImage: ${annotatedImageBase64 != null}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkinAnalysisModel &&
        other.skinConditionData == skinConditionData &&
        other.skinAreasData == skinAreasData &&
        other.allPredictions == allPredictions &&
        other.primaryCondition == primaryCondition &&
        other.primaryConfidence == primaryConfidence;
  }

  @override
  int get hashCode {
    return skinConditionData.hashCode ^
        skinAreasData.hashCode ^
        allPredictions.hashCode ^
        primaryCondition.hashCode ^
        primaryConfidence.hashCode;
  }
}