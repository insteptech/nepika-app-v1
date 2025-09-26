import 'dart:typed_data';

import '../../../core/utils/either.dart';
import '../entities/face_scan_result.dart';
import '../entities/camera_scan_session.dart';
import '../entities/scan_image.dart';

/// Abstract repository interface for face scanning operations.
/// 
/// This interface defines the contract for data operations related to face scanning,
/// following the dependency inversion principle. Concrete implementations will handle
/// the actual data source interactions (API calls, local storage, etc.).
/// 
/// The repository abstracts away all external dependencies and data source specifics,
/// ensuring the domain layer remains pure and testable.
abstract class FaceScanRepository {
  /// Analyzes a face image using AI models.
  /// 
  /// Takes image data and processes it through the analysis pipeline.
  /// Returns either a failure or a complete FaceScanResult with analysis data.
  /// 
  /// Parameters:
  /// - [imageBytes]: Raw image data to analyze
  /// - [userId]: ID of the user requesting analysis
  /// - [sessionId]: Unique session identifier for tracking
  /// - [accessToken]: Authentication token for API access
  /// - [includeAnnotatedImage]: Whether to include processed/annotated image
  /// 
  /// Returns:
  /// - Success: Complete FaceScanResult with analysis and images
  /// - Failure: Network, processing, or validation errors
  Future<Result<FaceScanResult>> analyzeFaceImage({
    required Uint8List imageBytes,
    required String userId,
    required String sessionId,
    required String accessToken,
    bool includeAnnotatedImage = true,
  });

  /// Initializes a new camera scanning session.
  /// 
  /// Sets up the camera resources and creates a session state for tracking
  /// the scanning process. This includes camera permission checks, initialization,
  /// and session configuration.
  /// 
  /// Parameters:
  /// - [userId]: ID of the user requesting the session
  /// - [sessionConfig]: Optional configuration for the session
  /// 
  /// Returns:
  /// - Success: Initialized CameraScanSession ready for use
  /// - Failure: Camera permissions, initialization, or configuration errors
  Future<Result<CameraScanSession>> initializeCameraSession({
    required String userId,
    CameraSessionConfig? sessionConfig,
  });

  /// Captures a face image during an active scanning session.
  /// 
  /// Takes a photo using the camera and validates it for quality and alignment.
  /// This method should only be called when a session is properly initialized
  /// and face alignment is validated.
  /// 
  /// Parameters:
  /// - [sessionId]: Active session identifier
  /// - [userId]: ID of the user requesting capture
  /// 
  /// Returns:
  /// - Success: ScanImage with captured photo and metadata
  /// - Failure: Capture, validation, or session state errors
  Future<Result<ScanImage>> captureFaceImage({
    required String sessionId,
    required String userId,
  });

  /// Updates the state of an active camera session.
  /// 
  /// Manages session state transitions, face alignment updates, and error handling.
  /// This method is called frequently during active scanning to maintain session state.
  /// 
  /// Parameters:
  /// - [sessionId]: Session to update
  /// - [newState]: New session state
  /// - [alignmentState]: Updated face alignment information (optional)
  /// - [error]: Session error information (optional)
  /// 
  /// Returns:
  /// - Success: Updated CameraScanSession
  /// - Failure: Session not found or state transition errors
  Future<Result<CameraScanSession>> updateSessionState({
    required String sessionId,
    required CameraSessionState newState,
    FaceAlignmentState? alignmentState,
    SessionError? error,
  });

  /// Retrieves the current state of a camera session.
  /// 
  /// Gets the latest session information including state, alignment, timing,
  /// and any errors. Useful for resuming sessions or checking session status.
  /// 
  /// Parameters:
  /// - [sessionId]: Session identifier to retrieve
  /// 
  /// Returns:
  /// - Success: Current CameraScanSession state
  /// - Failure: Session not found or access errors
  Future<Result<CameraScanSession>> getSessionState({
    required String sessionId,
  });

  /// Terminates an active camera session and cleans up resources.
  /// 
  /// Properly disposes of camera resources, saves session data if needed,
  /// and marks the session as completed or cancelled.
  /// 
  /// Parameters:
  /// - [sessionId]: Session to terminate
  /// - [userId]: User ID for authorization
  /// - [reason]: Reason for termination (optional)
  /// 
  /// Returns:
  /// - Success: Final session state
  /// - Failure: Session not found or cleanup errors
  Future<Result<CameraScanSession>> terminateSession({
    required String sessionId,
    required String userId,
    String? reason,
  });

  /// Saves a completed scan result for future reference.
  /// 
  /// Persists the scan result data for user history, trend analysis,
  /// and comparison with future scans. This may involve local storage,
  /// cloud synchronization, or both.
  /// 
  /// Parameters:
  /// - [scanResult]: Complete scan result to save
  /// - [userId]: User ID for data association
  /// 
  /// Returns:
  /// - Success: Saved scan result with any additional metadata
  /// - Failure: Storage, network, or validation errors
  Future<Result<FaceScanResult>> saveScanResult({
    required FaceScanResult scanResult,
    required String userId,
  });

  /// Retrieves historical scan results for a user.
  /// 
  /// Gets previously saved scan results for trend analysis, comparison,
  /// and user progress tracking. Results can be filtered and paginated.
  /// 
  /// Parameters:
  /// - [userId]: User ID to retrieve results for
  /// - [limit]: Maximum number of results to return (optional)
  /// - [offset]: Number of results to skip (optional)
  /// - [startDate]: Filter results from this date (optional)
  /// - [endDate]: Filter results until this date (optional)
  /// 
  /// Returns:
  /// - Success: List of historical FaceScanResult objects
  /// - Failure: Storage, network, or access errors
  Future<Result<List<FaceScanResult>>> getHistoricalResults({
    required String userId,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Retrieves the most recent scan result for a user.
  /// 
  /// Gets the latest successful scan result for comparison with new scans
  /// or to resume analysis. Useful for improvement tracking.
  /// 
  /// Parameters:
  /// - [userId]: User ID to retrieve result for
  /// 
  /// Returns:
  /// - Success: Most recent FaceScanResult or null if none exists
  /// - Failure: Storage, network, or access errors
  Future<Result<FaceScanResult?>> getLatestScanResult({
    required String userId,
  });

  /// Deletes scan result data.
  /// 
  /// Removes scan results from storage, typically for privacy reasons
  /// or user data management. This operation should be irreversible.
  /// 
  /// Parameters:
  /// - [scanId]: Specific scan ID to delete, or null for all user data
  /// - [userId]: User ID for authorization
  /// 
  /// Returns:
  /// - Success: Boolean indicating deletion success
  /// - Failure: Storage, network, or authorization errors
  Future<Result<bool>> deleteScanData({
    String? scanId,
    required String userId,
  });

  /// Validates image quality and suitability for analysis.
  /// 
  /// Checks image properties like resolution, format, file size, and basic
  /// quality metrics before sending to AI analysis. This can prevent
  /// unnecessary API calls and provide early feedback.
  /// 
  /// Parameters:
  /// - [imageBytes]: Image data to validate
  /// - [qualityRequirements]: Validation criteria (optional)
  /// 
  /// Returns:
  /// - Success: ImageValidationResult with quality metrics
  /// - Failure: Validation errors or processing issues
  Future<Result<ImageValidationResult>> validateImageQuality({
    required Uint8List imageBytes,
    ImageQualityRequirements? qualityRequirements,
  });

  /// Retrieves available camera devices and their capabilities.
  /// 
  /// Gets information about available cameras (front/back), their resolutions,
  /// and features. Used for camera selection and capability detection.
  /// 
  /// Returns:
  /// - Success: List of available camera devices
  /// - Failure: Camera access or enumeration errors
  Future<Result<List<CameraDeviceInfo>>> getAvailableCameras();

  /// Checks camera permissions and requests them if needed.
  /// 
  /// Verifies that the app has necessary camera permissions and handles
  /// permission requests. Essential for camera functionality.
  /// 
  /// Returns:
  /// - Success: Boolean indicating permission status
  /// - Failure: Permission denied or system errors
  Future<Result<bool>> checkCameraPermissions();
}

/// Result of image quality validation
class ImageValidationResult {
  /// Whether the image passes validation
  final bool isValid;
  
  /// Quality metrics for the image
  final ImageQuality qualityMetrics;
  
  /// Validation issues found (if any)
  final List<String> validationIssues;
  
  /// Recommendations for improving image quality
  final List<String> qualityRecommendations;

  const ImageValidationResult({
    required this.isValid,
    required this.qualityMetrics,
    required this.validationIssues,
    required this.qualityRecommendations,
  });

  @override
  String toString() {
    return 'ImageValidationResult('
        'isValid: $isValid, '
        'qualityMetrics: $qualityMetrics, '
        'validationIssues: ${validationIssues.length} issues, '
        'qualityRecommendations: ${qualityRecommendations.length} recommendations'
        ')';
  }
}

/// Information about an available camera device
class CameraDeviceInfo {
  /// Device identifier
  final String deviceId;
  
  /// Human-readable device name
  final String deviceName;
  
  /// Camera lens direction (front/back)
  final String lensDirection;
  
  /// Supported resolutions
  final List<String> supportedResolutions;
  
  /// Whether this camera supports flash
  final bool hasFlash;
  
  /// Whether this camera supports auto-focus
  final bool hasAutoFocus;
  
  /// Camera sensor orientation in degrees
  final int sensorOrientation;

  const CameraDeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.lensDirection,
    required this.supportedResolutions,
    required this.hasFlash,
    required this.hasAutoFocus,
    required this.sensorOrientation,
  });

  @override
  String toString() {
    return 'CameraDeviceInfo('
        'deviceId: $deviceId, '
        'deviceName: $deviceName, '
        'lensDirection: $lensDirection, '
        'supportedResolutions: $supportedResolutions, '
        'hasFlash: $hasFlash, '
        'hasAutoFocus: $hasAutoFocus, '
        'sensorOrientation: $sensorOrientation'
        ')';
  }
}