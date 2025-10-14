# Skin Analysis Reports API Documentation

## Endpoint: Get User Skin Reports

**Base URL:** `http://your-api-domain.com/api/v1/training/reports`

**Method:** `GET`

**Authentication:** Required (Bearer Token)

---

## Description

This endpoint allows authenticated users to retrieve their skin analysis reports. It supports two modes:

1. **List Mode**: Get all reports with pagination (default)
2. **Single Report Mode**: Get a specific report by ID

---

## Request Headers

| Header | Type | Required | Description |
|--------|------|----------|-------------|
| `Authorization` | String | Yes | Bearer token: `Bearer <your_jwt_token>` |

---

## Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `report_id` | String (UUID) | No | null | If provided, returns a specific report. Otherwise, returns all reports |
| `limit` | Integer | No | 10 | Maximum number of reports to return (ignored if `report_id` is provided) |
| `offset` | Integer | No | 0 | Number of reports to skip for pagination (ignored if `report_id` is provided) |

---

## Request Examples

### 1. Get All Reports (Paginated)

```bash
GET /api/training/reports
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**With Pagination:**
```bash
GET /api/training/reports?limit=5&offset=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. Get Specific Report by ID

```bash
GET /api/training/reports?report_id=69920f65-f32f-4fe4-bfde-38ca1f018224
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Response Format

### Success Response - Single Report (when report_id is provided)

**Status Code:** `200 OK`

```json
{
    "success": true,
    "report": {
        "id": "69920f65-f32f-4fe4-bfde-38ca1f018224",
        "scan_datetime": "2025-10-09T10:33:28.813256",
        "skin_score": 82,
        "acne_percentage": 17.949308454990387,
        "pores_percentage": null,
        "dark_spot_percentage": null,
        "condition_result": {
            "Acne": 17.949308454990387,
            "Eyebags": 12.40716427564621,
            "Dry-Skin": 16.25128984451294,
            "Wrinkles": 19.434845447540283,
            "Oily-Skin": 13.313992321491241,
            "Blackheads": 1.013388205319643,
            "Dark-Spots": 14.746685326099396,
            "Whiteheads": 3.882322460412979,
            "Skin-Redness": 0.29378458857536316,
            "Englarged-Pores": 0.7072216831147671
        },
        "skin_type_preds": {},
        "image_path": "face-analysis/a3cfeb1e-b25e-442f-ada4-bf3990925293/1760006007_annotated.png",
        "skin_condition_prediction": "Wrinkles",
        "skin_condition_confidence": 19.434845447540283,
        "skin_type_prediction": null,
        "skin_type_confidence": null,
        "lighting_ok": null,
        "area_detection_summary": {
            "detections": [
                {
                    "bbox": {
                        "x1": 343,
                        "x2": 445,
                        "y1": 118,
                        "y2": 156
                    },
                    "class": "eyebags",
                    "confidence": 0.8869264721870422
                }
            ],
            "class_counts": {
                "acne": 14,
                "eyebags": 2,
                "oily-skin": 1,
                "dark-spots": 35
            },
            "classes_found": [
                "oily-skin",
                "dark-spots",
                "eyebags",
                "acne"
            ],
            "model_threshold": 0.1,
            "confidence_stats": {
                "avg_confidence": 0.26272642598129237,
                "max_confidence": 0.8869264721870422,
                "min_confidence": 0.10179596394300461
            },
            "total_detections": 52,
            "analysis_timestamp": "2025-10-09T10:33:28.612394"
        },
        "processed": true
    }
}
```

### Success Response - List of Reports (without report_id)

**Status Code:** `200 OK`

```json
{
    "success": true,
    "total_count": 25,
    "limit": 10,
    "offset": 0,
    "reports": [
        {
            "id": "69920f65-f32f-4fe4-bfde-38ca1f018224",
            "scan_datetime": "2025-10-09T10:33:28.813256",
            "skin_score": 82,
            "acne_percentage": 17.949308454990387,
            "pores_percentage": null,
            "dark_spot_percentage": null,
            "condition_result": { ... },
            "skin_type_preds": {},
            "image_path": "face-analysis/...",
            "skin_condition_prediction": "Wrinkles",
            "skin_condition_confidence": 19.434845447540283,
            "skin_type_prediction": null,
            "skin_type_confidence": null,
            "lighting_ok": null,
            "area_detection_summary": { ... },
            "processed": true
        },
        // ... more reports
    ]
}
```

---

## Response Fields Description

### Root Level Fields (Single Report Response)

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Indicates if the request was successful |
| `report` | Object | The skin analysis report object |

### Root Level Fields (List Response)

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Indicates if the request was successful |
| `total_count` | Integer | Total number of reports for the user |
| `limit` | Integer | Maximum number of reports returned |
| `offset` | Integer | Number of reports skipped |
| `reports` | Array | Array of report objects |

### Report Object Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | No | Unique identifier for the report |
| `scan_datetime` | String (ISO 8601) | No | Timestamp when the scan was performed |
| `skin_score` | Integer | Yes | Overall skin health score (0-100) |
| `acne_percentage` | Float | Yes | Percentage of acne detected |
| `pores_percentage` | Float | Yes | Percentage of enlarged pores detected |
| `dark_spot_percentage` | Float | Yes | Percentage of dark spots detected |
| `condition_result` | Object | Yes | Detailed skin condition predictions with confidence scores (sorted by highest confidence first) |
| `skin_type_preds` | Object | Yes | Skin type predictions with probabilities |
| `image_path` | String | Yes | S3 path to the analyzed/annotated image |
| `skin_condition_prediction` | String | Yes | Primary predicted skin condition |
| `skin_condition_confidence` | Float | Yes | Confidence score for the primary condition (0-100) |
| `skin_type_prediction` | String | Yes | Predicted skin type (e.g., "Oily", "Dry", "Normal") |
| `skin_type_confidence` | Float | Yes | Confidence score for skin type prediction |
| `lighting_ok` | Boolean | Yes | Indicates if lighting was adequate during analysis |
| `area_detection_summary` | Object | Yes | Detailed area detection results |
| `processed` | Boolean | No | Indicates if the report has been fully processed |

### condition_result Object

A dictionary of skin conditions with their confidence scores (percentage). **Sorted by confidence in descending order** (highest first).

```json
{
    "Wrinkles": 19.434845447540283,
    "Acne": 17.949308454990387,
    "Dry-Skin": 16.25128984451294,
    "Dark-Spots": 14.746685326099396,
    ...
}
```

**Possible Condition Keys:**
- `Acne`
- `Blackheads`
- `Dark-Spots`
- `Dry-Skin`
- `Englarged-Pores`
- `Eyebags`
- `Oily-Skin`
- `Skin-Redness`
- `Whiteheads`
- `Wrinkles`

### area_detection_summary Object

| Field | Type | Description |
|-------|------|-------------|
| `total_detections` | Integer | Total number of problem areas detected |
| `classes_found` | Array[String] | List of unique skin issue classes detected |
| `model_threshold` | Float | Detection threshold used by the model |
| `detections` | Array[Object] | Detailed list of all detections |
| `class_counts` | Object | Count of each detected class |
| `confidence_stats` | Object | Statistics about detection confidence |
| `analysis_timestamp` | String (ISO 8601) | Timestamp of the analysis |

### Detection Object (in detections array)

| Field | Type | Description |
|-------|------|-------------|
| `bbox` | Object | Bounding box coordinates |
| `bbox.x1` | Integer | Top-left x coordinate |
| `bbox.y1` | Integer | Top-left y coordinate |
| `bbox.x2` | Integer | Bottom-right x coordinate |
| `bbox.y2` | Integer | Bottom-right y coordinate |
| `class` | String | Type of skin issue detected |
| `confidence` | Float | Confidence score (0-1) |

### confidence_stats Object

| Field | Type | Description |
|-------|------|-------------|
| `min_confidence` | Float | Minimum confidence score among all detections |
| `max_confidence` | Float | Maximum confidence score among all detections |
| `avg_confidence` | Float | Average confidence score |

---

## Error Responses

### 401 Unauthorized

**Scenario:** Invalid or missing authentication token

```json
{
    "detail": "Could not validate credentials"
}
```

### 404 Not Found

**Scenario:** Report ID provided doesn't exist or doesn't belong to the user

```json
{
    "detail": "Report not found or does not belong to user"
}
```

### 500 Internal Server Error

**Scenario:** Server error occurred

```json
{
    "detail": "Failed to fetch reports: <error_message>"
}
```

---

## Flutter Implementation Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class SkinReportsService {
  final String baseUrl = 'http://your-api-domain.com/api/training';
  final String authToken;

  SkinReportsService(this.authToken);

  // Get all reports with pagination
  Future<Map<String, dynamic>> getAllReports({int limit = 10, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports?limit=$limit&offset=$offset'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else {
      throw Exception('Failed to load reports: ${response.statusCode}');
    }
  }

  // Get specific report by ID
  Future<Map<String, dynamic>> getReportById(String reportId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports?report_id=$reportId'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Report not found');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else {
      throw Exception('Failed to load report: ${response.statusCode}');
    }
  }
}

// Usage Example
void main() async {
  final service = SkinReportsService('your_jwt_token_here');

  // Get all reports
  try {
    final allReports = await service.getAllReports(limit: 5, offset: 0);
    print('Total reports: ${allReports['total_count']}');
    print('Reports: ${allReports['reports']}');
  } catch (e) {
    print('Error: $e');
  }

  // Get specific report
  try {
    final report = await service.getReportById('69920f65-f32f-4fe4-bfde-38ca1f018224');
    print('Report ID: ${report['report']['id']}');
    print('Skin Score: ${report['report']['skin_score']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Model Classes for Flutter

```dart
class SkinReportResponse {
  final bool success;
  final SkinReport? report;
  final int? totalCount;
  final int? limit;
  final int? offset;
  final List<SkinReport>? reports;

  SkinReportResponse({
    required this.success,
    this.report,
    this.totalCount,
    this.limit,
    this.offset,
    this.reports,
  });

  factory SkinReportResponse.fromJson(Map<String, dynamic> json) {
    return SkinReportResponse(
      success: json['success'],
      report: json['report'] != null ? SkinReport.fromJson(json['report']) : null,
      totalCount: json['total_count'],
      limit: json['limit'],
      offset: json['offset'],
      reports: json['reports'] != null
          ? (json['reports'] as List).map((r) => SkinReport.fromJson(r)).toList()
          : null,
    );
  }
}

class SkinReport {
  final String id;
  final String scanDatetime;
  final int? skinScore;
  final double? acnePercentage;
  final double? poresPercentage;
  final double? darkSpotPercentage;
  final Map<String, dynamic>? conditionResult;
  final Map<String, dynamic>? skinTypePreds;
  final String? imagePath;
  final String? skinConditionPrediction;
  final double? skinConditionConfidence;
  final String? skinTypePrediction;
  final double? skinTypeConfidence;
  final bool? lightingOk;
  final AreaDetectionSummary? areaDetectionSummary;
  final bool processed;

  SkinReport({
    required this.id,
    required this.scanDatetime,
    this.skinScore,
    this.acnePercentage,
    this.poresPercentage,
    this.darkSpotPercentage,
    this.conditionResult,
    this.skinTypePreds,
    this.imagePath,
    this.skinConditionPrediction,
    this.skinConditionConfidence,
    this.skinTypePrediction,
    this.skinTypeConfidence,
    this.lightingOk,
    this.areaDetectionSummary,
    required this.processed,
  });

  factory SkinReport.fromJson(Map<String, dynamic> json) {
    return SkinReport(
      id: json['id'],
      scanDatetime: json['scan_datetime'],
      skinScore: json['skin_score'],
      acnePercentage: json['acne_percentage']?.toDouble(),
      poresPercentage: json['pores_percentage']?.toDouble(),
      darkSpotPercentage: json['dark_spot_percentage']?.toDouble(),
      conditionResult: json['condition_result'],
      skinTypePreds: json['skin_type_preds'],
      imagePath: json['image_path'],
      skinConditionPrediction: json['skin_condition_prediction'],
      skinConditionConfidence: json['skin_condition_confidence']?.toDouble(),
      skinTypePrediction: json['skin_type_prediction'],
      skinTypeConfidence: json['skin_type_confidence']?.toDouble(),
      lightingOk: json['lighting_ok'],
      areaDetectionSummary: json['area_detection_summary'] != null
          ? AreaDetectionSummary.fromJson(json['area_detection_summary'])
          : null,
      processed: json['processed'],
    );
  }
}

class AreaDetectionSummary {
  final int totalDetections;
  final List<String> classesFound;
  final double modelThreshold;
  final List<Detection> detections;
  final Map<String, dynamic> classCounts;
  final ConfidenceStats confidenceStats;
  final String analysisTimestamp;

  AreaDetectionSummary({
    required this.totalDetections,
    required this.classesFound,
    required this.modelThreshold,
    required this.detections,
    required this.classCounts,
    required this.confidenceStats,
    required this.analysisTimestamp,
  });

  factory AreaDetectionSummary.fromJson(Map<String, dynamic> json) {
    return AreaDetectionSummary(
      totalDetections: json['total_detections'],
      classesFound: List<String>.from(json['classes_found']),
      modelThreshold: json['model_threshold'].toDouble(),
      detections: (json['detections'] as List)
          .map((d) => Detection.fromJson(d))
          .toList(),
      classCounts: json['class_counts'],
      confidenceStats: ConfidenceStats.fromJson(json['confidence_stats']),
      analysisTimestamp: json['analysis_timestamp'],
    );
  }
}

class Detection {
  final BoundingBox bbox;
  final String className;
  final double confidence;

  Detection({
    required this.bbox,
    required this.className,
    required this.confidence,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      bbox: BoundingBox.fromJson(json['bbox']),
      className: json['class'],
      confidence: json['confidence'].toDouble(),
    );
  }
}

class BoundingBox {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: json['x1'],
      y1: json['y1'],
      x2: json['x2'],
      y2: json['y2'],
    );
  }
}

class ConfidenceStats {
  final double minConfidence;
  final double maxConfidence;
  final double avgConfidence;

  ConfidenceStats({
    required this.minConfidence,
    required this.maxConfidence,
    required this.avgConfidence,
  });

  factory ConfidenceStats.fromJson(Map<String, dynamic> json) {
    return ConfidenceStats(
      minConfidence: json['min_confidence'].toDouble(),
      maxConfidence: json['max_confidence'].toDouble(),
      avgConfidence: json['avg_confidence'].toDouble(),
    );
  }
}
```

---

## Important Notes

1. **Authentication Required**: All requests must include a valid JWT token in the Authorization header
2. **User Isolation**: Users can only access their own reports (enforced by backend)
3. **Sorted Conditions**: The `condition_result` object is **always sorted by confidence in descending order** (highest confidence first)
4. **Pagination**: Use `limit` and `offset` parameters for efficient data loading
5. **Image Path**: The `image_path` is an S3 key. You may need to construct the full URL based on your S3 bucket configuration
6. **Nullable Fields**: Many fields can be `null` if that analysis wasn't performed or data isn't available
7. **Date Format**: All timestamps are in ISO 8601 format

---

## Testing the API

You can test the API using tools like Postman, cURL, or directly in your Flutter app:

### Using cURL:

```bash
# Get all reports
curl -X GET "http://your-api-domain.com/api/training/reports?limit=5&offset=0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get specific report
curl -X GET "http://your-api-domain.com/api/training/reports?report_id=69920f65-f32f-4fe4-bfde-38ca1f018224" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Support

For issues or questions, please contact the backend development team or refer to the main API documentation at `/docs` (Swagger UI).
