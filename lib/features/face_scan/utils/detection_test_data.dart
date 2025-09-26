import '../models/detection_models.dart';

/// Test data for bounding box visualization development
class DetectionTestData {
  /// Sample API response matching the provided structure
  static const Map<String, dynamic> sampleApiResponse = {
    "success": true,
    "processing_time_seconds": 5.701,
    "timestamp": 1758733464,
    "analysis": {
      "skin_condition": {
        "success": true,
        "prediction": "pigmentation",
        "confidence": 40.95929563045502,
        "all_predictions": {
          "pigmentation": 40.95929563045502,
          "dry ": 23.66415411233902,
          "wrinkle": 15.552780032157898,
          "acne": 11.065106093883514,
          "dark_circles": 7.8986756503582,
          "normal": 0.8599785156548023
        },
        "model_name": "skin_condition"
      },
      "skin_type": {
        "success": false,
        "error_message": "argument of type 'coroutine' is not iterable",
        "model_name": "skin_type"
      },
      "skin_areas": {
        "success": true,
        "detection_results": {
          "detections": [
            {
              "class": "dark circles",
              "confidence": 0.7875675559043884,
              "bbox": {
                "x1": 246,
                "y1": 742,
                "x2": 481,
                "y2": 855
              }
            },
            {
              "class": "dark circles",
              "confidence": 0.7254322171211243,
              "bbox": {
                "x1": 684,
                "y1": 739,
                "x2": 934,
                "y2": 864
              }
            },
            {
              "class": "acne",
              "confidence": 0.12622717022895813,
              "bbox": {
                "x1": 511,
                "y1": 403,
                "x2": 541,
                "y2": 435
              }
            }
          ],
          "issues_found": [
            "acne",
            "dark circles"
          ],
          "total_detections": 3,
          "classes_found": [
            "acne",
            "dark circles"
          ],
          "model_threshold": 0.1,
          "confidence_scores": [
            0.7875675559043884,
            0.7254322171211243,
            0.12622717022895813
          ],
          "class_counts": {
            "acne": 1,
            "dark circles": 2
          }
        },
        "model_name": "skin_area"
      }
    },
    "summary": {
      "overall_success": false,
      "errors": [
        {
          "analysis": "skin_type",
          "error": "argument of type 'coroutine' is not iterable"
        }
      ]
    },
    "report": {
      "id": "63f7fc35-3c7f-43d6-a1b5-b39215c05c44",
      "image_url": null,
      "has_image": false
    }
  };

  /// Create DetectionResults from sample data
  static DetectionResults createSampleDetectionResults() {
    final detectionResultsData = sampleApiResponse['analysis']['skin_areas']['detection_results'] as Map<String, dynamic>;
    return DetectionResults.fromJson(detectionResultsData);
  }

  /// Sample detections for testing
  static List<Detection> get sampleDetections => [
    const Detection(
      className: "dark circles",
      confidence: 0.7875675559043884,
      bbox: BoundingBox(x1: 246, y1: 742, x2: 481, y2: 855),
    ),
    const Detection(
      className: "dark circles", 
      confidence: 0.7254322171211243,
      bbox: BoundingBox(x1: 684, y1: 739, x2: 934, y2: 864),
    ),
    const Detection(
      className: "acne",
      confidence: 0.12622717022895813,
      bbox: BoundingBox(x1: 511, y1: 403, x2: 541, y2: 435),
    ),
  ];

  /// Color demonstration for each class
  static void printColorMapping() {
    print('🎨 Detection Class Colors:');
    print('• Acne: ${DetectionColors.getColorForClass("acne")}');
    print('• Dark Circles: ${DetectionColors.getColorForClass("dark circles")}');
    print('• Pigmentation: ${DetectionColors.getColorForClass("pigmentation")}');
    print('• Wrinkles: ${DetectionColors.getColorForClass("wrinkle")}');
    print('• Dryness: ${DetectionColors.getColorForClass("dry")}');
  }

  /// Expected behavior description
  static String get expectedBehavior => '''
📋 Expected Bounding Box Behavior:

1. **Default View (All Tab)**:
   - Shows all 3 detections: 2 dark circles (blue) + 1 acne (red)
   - Each bounding box has corner markers and confidence labels
   - User can zoom/pan to inspect details

2. **Dark Circles Tab**:
   - Shows only the 2 dark circle detections (blue boxes)
   - Auto-zooms to fit both dark circle areas
   - Count badge shows "2"

3. **Acne Tab**:
   - Shows only the 1 acne detection (red box)
   - Auto-zooms to the single acne area
   - Count badge shows "1"

4. **Interactive Features**:
   - Tap tabs to filter classes
   - Pinch to zoom in/out
   - Pan to move around
   - Double-tap to reset zoom

5. **Visual Elements**:
   - Colored bounding boxes with corner markers
   - Confidence percentages above each box
   - Class name + confidence in labels
   - Detection stats summary
''';
}