import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Model for bounding box coordinates
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
    final x1 = (json['x1'] as num?)?.toDouble() ?? 0.0;
    final y1 = (json['y1'] as num?)?.toDouble() ?? 0.0;
    final x2 = (json['x2'] as num?)?.toDouble() ?? 0.0;
    final y2 = (json['y2'] as num?)?.toDouble() ?? 0.0;
    
    debugPrint('📦 Parsing bbox: x1=$x1, y1=$y1, x2=$x2, y2=$y2');
    
    return BoundingBox(
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
    );
  }

  /// Get the center point of the bounding box
  Offset get center => Offset((x1 + x2) / 2, (y1 + y2) / 2);

  /// Get the width of the bounding box
  double get width => x2 - x1;

  /// Get the height of the bounding box
  double get height => y2 - y1;

  /// Convert to Rect for easier drawing
  Rect toRect() => Rect.fromLTRB(x1, y1, x2, y2);

  /// Scale the bounding box by given factors
  BoundingBox scale(double scaleX, double scaleY) {
    return BoundingBox(
      x1: x1 * scaleX,
      y1: y1 * scaleY,
      x2: x2 * scaleX,
      y2: y2 * scaleY,
    );
  }
}

/// Model for a single detection result
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
    final className = json['class'] as String? ?? 'unknown';
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    final bboxData = json['bbox'] as Map<String, dynamic>? ?? {};
    
    debugPrint('🎯 Parsing detection: class=$className, confidence=$confidence, bbox=$bboxData');
    
    return Detection(
      className: className,
      confidence: confidence,
      bbox: BoundingBox.fromJson(bboxData),
    );
  }

  /// Get display name for the class
  String get displayName {
    switch (className.toLowerCase()) {
      case 'acne':
        return 'Acne';
      case 'dark circles':
      case 'dark_circles':
        return 'Dark Circles';
      case 'pigmentation':
        return 'Pigmentation';
      case 'wrinkle':
      case 'wrinkles':
        return 'Wrinkles';
      case 'dry':
      case 'dryness':
      case 'dry-skin':
        return 'Dry Skin';
      case 'skin-redness':
        return 'Skin Redness';
      case 'oily-skin':
        return 'Oily Skin';
      case 'blackheads':
        return 'Blackheads';
      case 'whiteheads':
        return 'Whiteheads';
      case 'dark-spots':
        return 'Dark Spots';
      case 'englarged-pores':
      case 'enlarged-pores':
        return 'Enlarged Pores';
      case 'eyebags':
        return 'Eye Bags';
      default:
        return className.replaceAll('_', ' ').replaceAll('-', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }

  /// Get confidence percentage as string
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Model for detection results with grouped data
class DetectionResults {
  final List<Detection> detections;
  final List<String> classesFound;
  final Map<String, int> classCounts;

  const DetectionResults({
    required this.detections,
    required this.classesFound,
    required this.classCounts,
  });

  factory DetectionResults.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 Parsing DetectionResults from: ${json.keys}');
    
    // Safely parse detections list
    final detectionsData = json['detections'];
    final List<Detection> detectionsList = [];
    
    if (detectionsData is List) {
      debugPrint('✅ Found ${detectionsData.length} detections in API response');
      for (final item in detectionsData) {
        if (item is Map<String, dynamic>) {
          try {
            detectionsList.add(Detection.fromJson(item));
          } catch (e) {
            debugPrint('❌ Error parsing detection item: $e');
          }
        }
      }
    } else {
      debugPrint('❌ No detections array found in API response');
    }

    // Safely parse classes found
    final classesFoundData = json['classes_found'];
    final List<String> classesFound = [];
    if (classesFoundData is List) {
      for (final item in classesFoundData) {
        if (item is String) {
          classesFound.add(item);
        }
      }
      debugPrint('✅ Classes found: $classesFound');
    }

    // Calculate class counts from detections since API doesn't provide class_counts
    final Map<String, int> classCounts = {};
    for (final detection in detectionsList) {
      classCounts[detection.className] = (classCounts[detection.className] ?? 0) + 1;
    }
    debugPrint('✅ Calculated class counts: $classCounts');

    final result = DetectionResults(
      detections: detectionsList,
      classesFound: classesFound,
      classCounts: classCounts,
    );
    
    debugPrint('🎯 Final DetectionResults: ${detectionsList.length} detections, ${classesFound.length} classes');
    return result;
  }

  /// Get detections filtered by class
  List<Detection> getDetectionsByClass(String className) {
    return detections.where((d) => d.className == className).toList();
  }

  /// Get all unique class names with their display names
  Map<String, String> get classDisplayNames {
    final Map<String, String> names = {'all': 'All'};
    for (final className in classesFound) {
      final detection = detections.firstWhere((d) => d.className == className);
      names[className] = detection.displayName;
    }
    return names;
  }

  /// Get bounding box that encompasses all detections of a specific class
  BoundingBox? getBoundsForClass(String className) {
    final classDetections = className == 'all' 
        ? detections 
        : getDetectionsByClass(className);
    
    if (classDetections.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final detection in classDetections) {
      minX = math.min(minX, detection.bbox.x1);
      minY = math.min(minY, detection.bbox.y1);
      maxX = math.max(maxX, detection.bbox.x2);
      maxY = math.max(maxY, detection.bbox.y2);
    }

    return BoundingBox(x1: minX, y1: minY, x2: maxX, y2: maxY);
  }
}

/// Color mapping for different detection classes
class DetectionColors {
  static const Map<String, Color> _classColors = {
    'acne': Colors.red,
    'dark circles': Colors.blue,
    'dark_circles': Colors.blue,
    'pigmentation': Colors.orange,
    'wrinkle': Colors.purple,
    'wrinkles': Colors.purple,
    'dry': Colors.brown,
    'dryness': Colors.brown,
    'dry-skin': Colors.brown,
    'skin-redness': Colors.redAccent,
    'oily-skin': Colors.yellow,
    'blackheads': Colors.black87,
    'whiteheads': Colors.white70,
    'dark-spots': Colors.deepOrange,
    'englarged-pores': Colors.grey,
    'enlarged-pores': Colors.grey,
    'eyebags': Colors.indigo,
    'normal': Colors.green,
  };

  static Color getColorForClass(String className) {
    return _classColors[className.toLowerCase()] ?? Colors.grey;
  }

  static List<Color> get allColors => _classColors.values.toSet().toList();
}