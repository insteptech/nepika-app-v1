import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import '../components/camera_manager.dart';
import '../components/face_detector_service.dart';
import '../components/face_scan_image_processor.dart';
import '../components/face_scan_api_handler.dart';
import '../widgets/face_scan_camera_preview.dart';
import '../widgets/face_alignment_overlay.dart';
import '../widgets/shimmer_overlay.dart';
import '../components/bounding_box_painter.dart';
import '../models/detection_models.dart';
import '../models/scan_analysis_models.dart';
import 'scan_recommendations_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/routes.dart';

/// Main face scan result page with camera, face detection, and analysis
class FaceScanResultScreen extends StatefulWidget {
  final CameraController? cameraController;
  final List<CameraDescription>? availableCameras;

  const FaceScanResultScreen({
    super.key,
    this.cameraController,
    this.availableCameras,
  });

  @override
  State<FaceScanResultScreen> createState() => _FaceScanResultScreenState();
}

class _FaceScanResultScreenState extends State<FaceScanResultScreen> 
    with SingleTickerProviderStateMixin {
  
  // Core services
  final CameraManager _cameraManager = CameraManager();
  final FaceDetectorService _faceDetector = FaceDetectorService();
  final FaceScanApiHandler _apiHandler = FaceScanApiHandler();
  
  // State management
  bool _isAligned = false;
  int _countdown = 3;
  Timer? _timer;
  XFile? _capturedImage;
  
  // Face alignment feedback
  FaceAlignmentResult? _currentAlignmentResult;
  
  // Navigation state
  bool _isNavigatingBack = false;
  bool _isClosingCamera = false;
  
  // Condition filtering state
  String? _selectedCondition;
  
  // Transformation controller for zoom functionality
  late TransformationController _transformationController;
  
  // API state
  bool _isProcessingAPI = false;
  bool _showShimmerCompletion = false;
  String? _reportId;
  Map<String, dynamic>? _analysisResults;
  DetectionResults? _detectionResults;
  ui.Size? _actualImageSize;
  ScanAnalysisResponse? _scanAnalysisResponse;
  
  // Face scan info popup state
  static const String _faceScanInfoShownKey = 'face_scan_info_popup_shown';
  

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeCamera();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _faceDetector.dispose();
    _cameraManager.dispose();
    _apiHandler.cancelRequests();
    _cancelTimer(skipStateUpdate: true);
    super.dispose();
  }

  void _initializeServices() {
    _faceDetector.initialize();
    _apiHandler.initialize();
  }


  Future<void> _initializeCamera() async {
    final success = await _cameraManager.initializeCamera(
      preInitializedController: widget.cameraController,
      availableCameras: widget.availableCameras,
    );

    if (success && mounted) {
      setState(() {});
      await _startImageStream();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startImageStream() async {
    await _cameraManager.startImageStream(_processFrame);
  }

  void _processFrame(CameraImage image) async {
    if (!mounted || _cameraManager.controller == null || _isNavigatingBack) return;

    final camera = _cameraManager.controller!.description;
    final faces = await _faceDetector.processFrame(image, camera);
    
    if (mounted && !_isNavigatingBack) {
      _evaluateAlignment(faces);
    }
  }

  void _evaluateAlignment(List<Face> faces) {
    final previewSize = _cameraManager.controller?.value.previewSize;
    final result = _faceDetector.evaluateAlignment(
      faces, 
      previewSize,
      ovalHeightFactor: 0.55, // Match oval height with overlay
    );
    
    bool newAlignmentState = result.isAligned;

    // Store current alignment result for dynamic feedback
    if (mounted) {
      setState(() {
        _currentAlignmentResult = result;
      });
    }

    // Handle state changes
    if (newAlignmentState && !_isAligned) {
      _onAligned();
    } else if (!newAlignmentState && _isAligned) {
      _onMisaligned();
    }
  }

  void _onAligned() {
    if (!_isAligned && mounted) {
      setState(() => _isAligned = true);
      _startCountdown();
    }
  }

  void _onMisaligned() {
    if (_isAligned && mounted) {
      setState(() {
        _isAligned = false;
        _countdown = 3;
      });
      _cancelTimer();
    }
  }

  void _startCountdown() {
    _countdown = 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      
      // If face is no longer aligned, stop countdown and reset
      if (!_isAligned) {
        t.cancel();
        _resetToDefaultState();
        return;
      }
      
      if (_countdown == 0) {
        t.cancel();
        _capturePhoto();
      } else {
        if (mounted) {
          setState(() => _countdown--);
        } else {
          t.cancel();
        }
      }
    });
  }

  void _resetToDefaultState() {
    if (mounted) {
      setState(() {
        _isAligned = false;
        _countdown = 3;
      });
      _cancelTimer();
    }
  }

  void _cancelTimer({bool skipStateUpdate = false}) {
    _timer?.cancel();
    _timer = null;
    if (!skipStateUpdate && mounted) {
      setState(() => _countdown = 3);
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isAligned) {
      _cancelTimer();
      return;
    }

    final capturedFile = await _cameraManager.capturePhoto();
    if (capturedFile != null && mounted) {
      // Process the image for upload
      final processedFile = await FaceScanImageProcessor.processImageForUpload(
        capturedFile,
        _cameraManager.controller?.description.lensDirection,
      );
      
      setState(() {
        _capturedImage = processedFile;
        _reportId = null;
        _analysisResults = null;
      });

      // Automatically send to API after capture
      await _sendImageToAPI(processedFile);
    }
  }

  Future<void> _sendImageToAPI(XFile imageFile) async {
    if (!mounted) return;

    setState(() {
      _isProcessingAPI = true;
      _reportId = null;
      _analysisResults = null;
    });

    debugPrint('✨ Starting API processing - Shimmer should be visible now');

    final result = await _apiHandler.analyzeImage(imageFile);

    if (!mounted) return;

    if (result.isSuccess) {
      // First, trigger completion animation
      setState(() {
        _analysisResults = result.analysisResults;
        _reportId = result.reportId;
        _showShimmerCompletion = true;
        // Parse detection results from API response
        _detectionResults = _parseDetectionResults(result.analysisResults);
        // Parse complete scan analysis response
        _scanAnalysisResponse = ScanAnalysisResponse.fromJson(result.analysisResults ?? {});
        // Keep _isProcessingAPI = true until completion animation finishes
      });

      debugPrint('✅ API processing complete - Starting completion animation');
      
      // Show one-time face scan info popup
      await _showFaceScanInfoPopupIfNeeded();
      
      // Turn off camera after successful API response
      await _cameraManager.dispose();
    } else {
      debugPrint('🔴 API call failed: ${result.errorMessage}');
      debugPrint('🔍 Is limit error: ${result.isLimitError}');
      debugPrint('🔍 Limit data: ${result.limitData}');
      
      setState(() {
        _isProcessingAPI = false;
        _reportId = null;
        _detectionResults = null;
        _scanAnalysisResponse = null;
      });
      
      // Check if this is a scan limit error and show limit bottom sheet
      if (result.isLimitError && result.limitData != null) {
        debugPrint('🚫 Showing scan limit bottom sheet');
        _showScanLimitBottomSheet(result.errorMessage!, result.limitData!);
      } else {
        // Show general error bottom sheet for all other errors
        debugPrint('⚠️ Showing general error bottom sheet');
        _showErrorBottomSheet(result.errorMessage!);
      }
    }
  }


  /// Show scan limit error bottom sheet
  void _showScanLimitBottomSheet(String message, Map<String, dynamic> limitData) {
    debugPrint('🚫 _showScanLimitBottomSheet called with message: $message');
    debugPrint('🚫 Limit data received: $limitData');
    
    final theme = Theme.of(context);
    
    // Extract limit data
    final scansUsed = limitData['scans_used']?.toString() ?? '0';
    final monthlyLimit = limitData['monthly_limit']?.toString() ?? '1';
    final nextResetDate = limitData['next_reset_date']?.toString() ?? '';
    final plan = limitData['plan']?.toString() ?? 'free';
    
    debugPrint('🚫 Extracted data - Scans: $scansUsed/$monthlyLimit, Plan: $plan, Reset: $nextResetDate');
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Scan Limit Reached',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.brightness == Brightness.dark 
                    ? Colors.grey[300] 
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Limit details
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: theme.brightness == Brightness.dark 
            //         ? Colors.grey[800] 
            //         : Colors.grey[100],
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     children: [
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Text(
            //             'Plan:',
            //             style: theme.textTheme.bodyMedium?.copyWith(
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //           Text(
            //             plan.toUpperCase(),
            //             style: theme.textTheme.bodyMedium?.copyWith(
            //               fontWeight: FontWeight.w600,
            //               color: Colors.orange,
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 8),
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Text(
            //             'Scans used:',
            //             style: theme.textTheme.bodyMedium?.copyWith(
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //           Text(
            //             '$scansUsed / $monthlyLimit',
            //             style: theme.textTheme.bodyMedium?.copyWith(
            //               fontWeight: FontWeight.w600,
            //               color: Colors.red,
            //             ),
            //           ),
            //         ],
            //       ),
            //       if (nextResetDate.isNotEmpty) ...[
            //         const SizedBox(height: 8),
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             Text(
            //               'Next reset:',
            //               style: theme.textTheme.bodyMedium?.copyWith(
            //                 fontWeight: FontWeight.w500,
            //               ),
            //             ),
            //             Text(
            //               _formatResetDate(nextResetDate),
            //               style: theme.textTheme.bodyMedium?.copyWith(
            //                 fontWeight: FontWeight.w600,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 24),
            
            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushNamed(context, '/pricing'); // Navigate to pricing
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Upgrade to Premium',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Go back to previous screen
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            
            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// Show general error bottom sheet
  void _showErrorBottomSheet(String errorMessage) {
    debugPrint('🔴 _showErrorBottomSheet called with message: $errorMessage');
    
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Analysis Failed',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Error message
            Text(
              errorMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.brightness == Brightness.dark 
                    ? Colors.grey[300] 
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  // Retry the analysis if captured image is available
                  if (_capturedImage != null) {
                    _sendImageToAPI(_capturedImage!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Go back to previous screen
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            
            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _retryInitialization() async {
    await _cameraManager.dispose();
    
    setState(() {
      _reportId = null;
      _analysisResults = null;
      _capturedImage = null;
      _isProcessingAPI = false;
      _showShimmerCompletion = false;
      _detectionResults = null;
      _scanAnalysisResponse = null;
      _selectedCondition = null;
      _actualImageSize = null;
      _resetToDefaultState();
    });
    
    
    // Reinitialize camera from scratch
    await _initializeCamera();
  }

  /// Parse detection results from API response
  DetectionResults? _parseDetectionResults(Map<String, dynamic>? analysisResults) {
    try {
      if (analysisResults == null) return null;
      
      // The detection data is in 'area_detection_analysis' based on actual API response
      final areaDetection = analysisResults['area_detection_analysis'] as Map<String, dynamic>?;
      if (areaDetection == null) {
        debugPrint('❌ No area_detection_analysis found in API response');
        return null;
      }

      debugPrint('✅ Found area_detection_analysis: ${areaDetection.keys}');
      debugPrint('✅ Total detections: ${areaDetection['total_detections']}');
      debugPrint('✅ Classes found: ${areaDetection['classes_found']}');

      return DetectionResults.fromJson(areaDetection);
    } catch (e) {
      debugPrint('❌ Error parsing detection results: $e');
      return null;
    }
  }


  /// Calculate the actual display size of the image container
  Size _getDisplayedImageContainerSize() {
    final screenWidth = MediaQuery.of(context).size.width - 32; // Subtract horizontal padding
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    // Reserve space for UI elements
    const topControlsHeight = 40.0;
    const topSpacing = 30.0;
    const bottomButtonHeight = 80.0;
    const analyzingTextHeight = 40.0;
    const paddingAndSpacing = 60.0; // Include vertical padding
    
    // Calculate available height for Expanded area
    final availableHeight = screenHeight - safeAreaTop - safeAreaBottom - 
                           topControlsHeight - topSpacing - bottomButtonHeight - 
                           analyzingTextHeight - paddingAndSpacing;
    
    // For aspect ratio calculation, we need to determine the actual container size
    // This will depend on the image aspect ratio and available space
    if (_capturedImage != null && _actualImageSize != null) {
      final imageAspectRatio = _actualImageSize!.width / _actualImageSize!.height;
      
      // Calculate size constrained by both width and height
      final widthConstrainedHeight = screenWidth / imageAspectRatio;
      final heightConstrainedWidth = availableHeight * imageAspectRatio;
      
      if (widthConstrainedHeight <= availableHeight) {
        // Width constrains the size
        return Size(screenWidth, widthConstrainedHeight);
      } else {
        // Height constrains the size
        return Size(heightConstrainedWidth, availableHeight);
      }
    }
    
    // Default fallback size
    return Size(screenWidth, availableHeight * 0.8);
  }

  /// Get the actual size of the captured image
  Future<ui.Size> _getImageSize() async {
    if (_actualImageSize != null) {
      return _actualImageSize!;
    }

    if (_capturedImage == null) {
      return const ui.Size(1080, 1920); // Default fallback
    }

    try {
      final File imageFile = File(_capturedImage!.path);
      final ui.Image image = await _decodeImageFromFile(imageFile);
      _actualImageSize = ui.Size(image.width.toDouble(), image.height.toDouble());
      debugPrint('📐 Actual image size detected: ${_actualImageSize!.width} x ${_actualImageSize!.height}');
      return _actualImageSize!;
    } catch (e) {
      debugPrint('❌ Error getting image size: $e');
      return const ui.Size(1080, 1920); // Default fallback
    }
  }

  /// Helper method to decode image from file
  Future<ui.Image> _decodeImageFromFile(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          debugPrint('Face scan page: User navigating back, disposing camera...');
          
          // Set navigation state to prevent UI rebuilds during disposal
          setState(() {
            _isNavigatingBack = true;
          });
          
          // Cancel any ongoing timers
          _cancelTimer(skipStateUpdate: true);
          
          try {
            final navigator = Navigator.of(context);
            await _cameraManager.dispose();
            debugPrint('Face scan page: Camera disposed, navigating back');
            
            if (mounted) {
              navigator.pop();
            }
          } catch (e) {
            debugPrint('Error during navigation back: $e');
            if (mounted) {
              setState(() {
                _isNavigatingBack = false;
              });
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isNavigatingBack
            ? SafeArea(child: _buildNavigatingBackView())
            : _capturedImage == null 
                ? _buildFullscreenCameraView() // No SafeArea for camera preview
                : SafeArea(child: _buildCompactResultView()), // SafeArea only for results
      ),
    );
  }

Widget _buildNavigatingBackView() {
  return Container(
    height: double.infinity,
    color: Colors.black,
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // centers vertically
        crossAxisAlignment: CrossAxisAlignment.center, // centers horizontally
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 20),
          Text(
            'Preparing to close camera',
            style: TextStyle(color: Colors.white), // ensure visible on black
          ),
        ],
      ),
    ),
  );
}


  Widget _buildFullscreenCameraView() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen camera preview with no constraints
          _buildMainContent(),
          
          // Face alignment overlay
          if (_cameraManager.isInitialized && _cameraManager.controller != null)
            FaceAlignmentOverlay(
              isAligned: _isAligned,
              ovalHeightFactor: 0.55, // Set height to 55% of screen
            ),
          
          // Countdown timer in center (when aligned)
          if (_isAligned)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '$_countdown',
                  key: ValueKey(_countdown), // Important for AnimatedSwitcher
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Close button positioned at top right with safe area padding
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                if (_isClosingCamera) return; // Prevent multiple taps
                
                debugPrint('Face scan: Close button pressed, disposing camera...');
                setState(() {
                  _isClosingCamera = true;
                });
                
                try {
                  // Cancel any ongoing timers
                  _cancelTimer(skipStateUpdate: true);
                  
                  // Dispose camera
                  await _cameraManager.dispose();
                  debugPrint('Face scan: Camera disposed, navigating back');
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  debugPrint('Error closing camera: $e');
                  if (mounted) {
                    setState(() {
                      _isClosingCamera = false;
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Transform.rotate(
                  angle: 45 * 3.1416 / 180,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          
          // Instruction text positioned at bottom with safe area padding
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 20,
            right: 20,
            child: _buildInstructionText(),
          ),
          
          // Closing camera overlay
          if (_isClosingCamera)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Closing Camera...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactResultView() {
    debugPrint('🏗️ Building compact result view - _scanAnalysisResponse: ${_scanAnalysisResponse != null}');

    return SafeArea(
      child: Column(
        children: [
          // Main scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Top controls (with close button)
                  _buildTopControls(),

                  const SizedBox(height: 20),

                  // Main content area - constrained by aspect ratio
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildMainContentWithAspectRatio(),
                          ),
                        ),

                        // Condition dropdown overlay - positioned outside InteractiveViewer
                        if (_detectionResults != null)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: _buildConditionDropdown(),
                          ),
                      ],
                    ),
                  ),

                  // Analyzing text below image area
                  if (_isProcessingAPI)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: AnalyzingText(
                        isVisible: _isProcessingAPI,
                        text: 'Analyzing Image...',
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom section with analysis results - fixed at bottom, outside scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBottomSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // if (_capturedImage != null || _reportImageUrl != null || _cameraManager.controller == null)
        //   IconButton(
        //     icon: const Icon(
        //       Icons.refresh,
        //       size: 28,
        //       color: Colors.grey,
        //     ),
        //     onPressed: _retryInitialization,
        //   ),
        // const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            debugPrint('Face scan: Close button pressed, disposing camera...');
            final navigator = Navigator.of(context);
            await _cameraManager.dispose();
            if (mounted) navigator.pop();
          },
          child: Transform.rotate(
            angle: 45 * 3.1416 / 180,
            child: Image.asset(
              'assets/icons/add_icon.png',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenCameraPreview() {
    if (_cameraManager.controller == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade900,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final controller = _cameraManager.controller!;
    
    // Check if controller is disposed or not initialized
    if (!controller.value.isInitialized || controller.value.hasError) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade900,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Additional safety check to prevent disposed controller usage
    try {
      // Full screen camera preview with proper aspect ratio
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover, // This maintains aspect ratio and covers the full screen
          child: SizedBox(
            width: controller.value.previewSize!.height, // Swap because camera is rotated
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building camera preview: $e');
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade900,
        child: const Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildMainContentWithAspectRatio() {
    // Captured/Processed image state with aspect ratio
    if (_capturedImage != null) {
      return FutureBuilder<ui.Size>(
        future: _getImageSize(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final imageSize = snapshot.data!;
            final aspectRatio = imageSize.width / imageSize.height;
            
            return AspectRatio(
              aspectRatio: aspectRatio,
              child: _buildImageWidget(),
            );
          }
          // While loading image dimensions, use a reasonable default aspect ratio
          return AspectRatio(
            aspectRatio: 3 / 4, // Common portrait aspect ratio
            child: _buildImageWidget(),
          );
        },
      );
    }
    
    // Camera preview state with aspect ratio
    if (_cameraManager.isInitialized && _cameraManager.controller != null) {
      final controller = _cameraManager.controller!;
      if (controller.value.isInitialized) {
        // Get camera aspect ratio
        final cameraAspectRatio = controller.value.aspectRatio;
        
        return AspectRatio(
          aspectRatio: 1 / cameraAspectRatio, // Invert because camera is typically rotated
          child: FaceScanCameraPreview(
            controller: controller,
            errorMessage: _cameraManager.errorMessage,
            isInitializing: _cameraManager.isInitializing,
            onRetry: _retryInitialization,
          ),
        );
      }
    }
    
    // Error or loading state with default aspect ratio
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: FaceScanCameraPreview(
        controller: null,
        errorMessage: _cameraManager.errorMessage,
        isInitializing: _cameraManager.isInitializing,
        onRetry: _retryInitialization,
      ),
    );
  }

  Widget _buildMainContent() {
    // Captured/Processed image state
    if (_capturedImage != null) {
      return _buildImageWidget();
    }
    
    // Camera preview state - use different preview for fullscreen vs compact
    if (_cameraManager.isInitialized && _cameraManager.controller != null) {
      // For fullscreen mode, use proper aspect ratio handling
      if (_capturedImage == null) {
        return _buildFullscreenCameraPreview();
      } else {
        return FaceScanCameraPreview(
          controller: _cameraManager.controller,
          errorMessage: _cameraManager.errorMessage,
          isInitializing: _cameraManager.isInitializing,
          onRetry: _retryInitialization,
        );
      }
    }
    
    // Error or loading state
    return FaceScanCameraPreview(
      controller: null,
      errorMessage: _cameraManager.errorMessage,
      isInitializing: _cameraManager.isInitializing,
      onRetry: _retryInitialization,
    );
  }

Widget _buildImageWidget() {
  if (_capturedImage == null) {
    return const SizedBox.shrink();
  }

  return InteractiveViewer(
    transformationController: _transformationController,
    minScale: 1.0,
    maxScale: 3.0,
    panEnabled: false, // Disable manual panning
    scaleEnabled: false, // Disable manual scaling
    child: ShimmerOverlay(
      isActive: _isProcessingAPI,
      showCompletion: _showShimmerCompletion,
      onCompletionFinished: () {
        if (mounted) {
          setState(() {
            _isProcessingAPI = false;
            _showShimmerCompletion = false;
          });
          debugPrint('🎉 Shimmer completion finished - Now showing results');
        }
      },
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.3),
        Colors.white.withValues(alpha: 0.7),
        Colors.white.withValues(alpha: 0.3),
        Colors.white.withValues(alpha: 0.1),
        Colors.transparent,
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base layer: Show bounding boxes directly on captured image
          if (_detectionResults != null)
            FutureBuilder<ui.Size>(
              future: _getImageSize(),
              builder: (context, snapshot) {
                final imageSize =
                    snapshot.data ?? const ui.Size(1080, 1920);

                return BoundingBoxOverlay(
                  detections: _detectionResults!.detections,
                  selectedClass: _selectedCondition,
                  showConfidence: false, // Don't show labels on image
                  imageSize: imageSize,
                  child: Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Error loading captured image',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          else
            // Fallback: show image without bounding boxes if no detection results
            Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Error loading captured image',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),

          // Note: Annotated image no longer returned by API v2
          // Detection boxes are now drawn on the captured image using CustomPaint

        ],
      ),
    ),
  );
}



  /// Build the horizontal scrollable condition chips
  Widget _buildConditionDropdown() {
    if (_detectionResults == null) return const SizedBox.shrink();
    
    // Get unique conditions from detection results
    final conditionCounts = <String, int>{};
    for (final detection in _detectionResults!.detections) {
      conditionCounts[detection.className] = (conditionCounts[detection.className] ?? 0) + 1;
    }
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip - shows total number of unique issues/conditions
          _buildConditionChip(
            'All',
            conditionCounts.length,
            Colors.grey,
            _selectedCondition == null,
            () {
              setState(() {
                _selectedCondition = null;
              });
              _autoZoomToCondition(null);
            },
          ),
          const SizedBox(width: 8),
          
          // Individual condition chips
          ...conditionCounts.entries.map((entry) {
            final className = entry.key;
            final count = entry.value;
            final color = DetectionColors.getColorForClass(className);
            final displayName = _getDisplayNameForClass(className);
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildConditionChip(
                displayName,
                count,
                color,
                _selectedCondition == className,
                () {
                  setState(() {
                    _selectedCondition = className;
                  });
                  _autoZoomToCondition(className);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
  
  /// Build individual condition chip
  Widget _buildConditionChip(String name, int count, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Auto-zoom to the selected condition
  void _autoZoomToCondition(String? className) {
    if (_detectionResults == null) return;
    
    if (className == null) {
      // Reset to show full image
      _transformationController.value = Matrix4.identity();
      return;
    }
    
    // Get bounding box for the selected class
    final classDetections = _detectionResults!.detections
        .where((d) => d.className == className)
        .toList();
    
    if (classDetections.isEmpty) return;
    
    // Calculate the encompassing bounding box
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
    
    // Get the actual image size
    _getImageSize().then((imageSize) {
      if (!mounted) return; // Guard against unmounted widget
      
      // Get the actual displayed container size
      final containerSize = _getDisplayedImageContainerSize();
      final widgetSize = MediaQuery.of(context).size;
      final containerHeight = containerSize.height;
      
      // Calculate the actual image bounds within the widget when using BoxFit.contain
      final imageAspectRatio = imageSize.width / imageSize.height;
      final containerAspectRatio = widgetSize.width / containerHeight;
      
      double actualImageWidth, actualImageHeight;
      double imageOffsetX = 0, imageOffsetY = 0;
      
      if (imageAspectRatio > containerAspectRatio) {
        // Image is wider, fit by width
        actualImageWidth = widgetSize.width;
        actualImageHeight = widgetSize.width / imageAspectRatio;
        imageOffsetY = (containerHeight - actualImageHeight) / 2;
      } else {
        // Image is taller, fit by height
        actualImageHeight = containerHeight;
        actualImageWidth = containerHeight * imageAspectRatio;
        imageOffsetX = (widgetSize.width - actualImageWidth) / 2;
      }
      
      // Calculate scale factor based on actual displayed image size
      final scale = actualImageWidth / imageSize.width;
      
      // Scale the bounding box coordinates to displayed image space and add offset
      final scaledMinX = minX * scale + imageOffsetX;
      final scaledMinY = minY * scale + imageOffsetY;
      final scaledMaxX = maxX * scale + imageOffsetX;
      final scaledMaxY = maxY * scale + imageOffsetY;
      
      // Calculate dimensions of the detection area
      final width = scaledMaxX - scaledMinX;
      final height = scaledMaxY - scaledMinY;
      
      // Add padding around the detection area
      const padding = 40.0;
      final paddedWidth = width + (padding * 2);
      final paddedHeight = height + (padding * 2);
      
      // Calculate zoom level to fit the detection area in the widget
      final zoomX = widgetSize.width / paddedWidth;
      final zoomY = containerHeight / paddedHeight;
      final zoom = math.min(zoomX, zoomY).clamp(1.0, 2.5);
      
      // Calculate the center of the detection area
      final centerX = (scaledMinX + scaledMaxX) / 2;
      final centerY = (scaledMinY + scaledMaxY) / 2;
      
      final translateX = (widgetSize.width / 2) - (centerX * zoom);
      final translateY = (containerHeight / 2) - (centerY * zoom);
      
      // Create and apply the transformation matrix
      final matrix = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(zoom);
      
      // Animate to the new transformation
      _animateToTransform(matrix);
    });
  }
  
  /// Animate the transformation controller to a new matrix
  void _animateToTransform(Matrix4 targetMatrix) {
    // You could add animation here if desired, for now just set directly
    if (mounted) {
      _transformationController.value = targetMatrix;
    }
  }
  
  /// Get display name for a detection class
  String _getDisplayNameForClass(String className) {
    if (_detectionResults?.detections.isNotEmpty == true) {
      final detection = _detectionResults!.detections
          .firstWhere((d) => d.className == className, orElse: () => _detectionResults!.detections.first);
      return detection.displayName;
    }
    return className;
  }

  Widget _buildInstructionText() {
    String instructionText = 'Align your face inside the oval and look straight';
    IconData instructionIcon = Icons.face;
    Color textColor = Colors.white70;

    if (_currentAlignmentResult != null) {
      final result = _currentAlignmentResult!;
      
      if (!result.hasDetectedFace) {
        instructionText = 'Position your face in the camera view';
        instructionIcon = Icons.face_retouching_natural;
      } else if (result.alignmentIssues.isNotEmpty) {
        // Use the most specific alignment issue
        instructionText = result.alignmentIssues.first;
        if (instructionText.contains('look straight')) {
          instructionIcon = Icons.visibility;
        } else if (instructionText.contains('inside the oval')) {
          instructionIcon = Icons.center_focus_weak;
        } else {
          instructionIcon = Icons.warning_outlined; // Default for other alignment issues
        }
      } else if (result.isAligned) {
        instructionText = 'Perfect! Hold still...';
        instructionIcon = Icons.check_circle_outline;
        textColor = Colors.greenAccent;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              instructionIcon,
              key: ValueKey('$instructionIcon-$instructionText'),
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                instructionText,
                key: ValueKey(instructionText),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    debugPrint('🔘 _buildBottomSection called - _scanAnalysisResponse: ${_scanAnalysisResponse != null}, _isProcessingAPI: $_isProcessingAPI');

    // Show result button if analysis is available
    if (_scanAnalysisResponse != null) {
      debugPrint('🔘 Rendering Result button');
      return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          width: double.infinity,
          child: CustomButton(
            text: 'View Results',
            onPressed: () {
              // Navigate to recommendations screen with scan analysis data
              debugPrint('📊 Navigating to ScanRecommendationsScreen');
              debugPrint('📊 Report ID: ${_scanAnalysisResponse?.reportId}');
              debugPrint('📊 Primary Condition: ${_scanAnalysisResponse?.primaryCondition}');

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScanRecommendationsScreen(
                    scanResponse: _scanAnalysisResponse!,
                  ),
                ),
              );
            },
          ),
        );
    }

    debugPrint('🔘 Returning SizedBox.shrink - no scan response');
    return const SizedBox.shrink();
  }

  /// Check if face scan info popup should be shown and display it
  Future<void> _showFaceScanInfoPopupIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_faceScanInfoShownKey) ?? false;
      
      if (!hasShown && mounted) {
        // Mark as shown first
        await prefs.setBool(_faceScanInfoShownKey, true);
        
        // Show the popup
        _showFaceScanInfoPopup();
      }
    } catch (e) {
      debugPrint('❌ Error checking face scan info popup state: $e');
    }
  }

  /// Show the face scan info popup
  void _showFaceScanInfoPopup() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'About Face Scan',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Learn how our AI analyzes your skin condition, scoring system, and privacy practices.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Maybe Later',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to face scan info screen
                          Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.faceScanInfo);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Learn More',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}