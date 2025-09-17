import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class FaceScanResultPage extends StatefulWidget {
  final CameraController? cameraController;
  final List<CameraDescription>? availableCameras;

  const FaceScanResultPage({
    super.key,
    this.cameraController,
    this.availableCameras,
  });

  @override
  State<FaceScanResultPage> createState() => _FaceScanResultPageState();
}

class _FaceScanResultPageState extends State<FaceScanResultPage> 
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isInitializing = false;
  String? _errorMessage;
  String? _token;
  List<Face> _faces = [];
  
  // Animation controller for shimmer effect
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  // Transformation controller for zoom functionality
  late TransformationController _transformationController;

  // Alignment & capture state
  bool _isAligned = false;
  int _countdown = 5;
  Timer? _timer;
  XFile? _capturedImage;
  Dio _dio = Dio();

  // API state - Updated for complete analysis
  bool _isProcessingAPI = false;
  String? _reportImageUrl;
  Map<String, dynamic>? _analysisResults;
  String? _apiError;
  
  // Shimmer effect states
  bool _isLoadingAnnotatedImage = false;
  bool _annotatedImageLoaded = false;
  bool _imagePreloadComplete = false;
  DateTime? _shimmerStartTime;
  
  // Flag to force complete reinitialization
  bool _forceReinitialization = false;

  // Updated API endpoint to use the combined analysis
  static const String _apiEndpoint =
      '${Env.baseUrl}/model/face-scan/analyze_face_complete';

  @override
  void initState() {
    super.initState();
    _initializeDio();
    _initializeFaceDetector();
    _initializeCamera();
    _initializeShimmerAnimation();
    _transformationController = TransformationController();
  }


void _initializeShimmerAnimation() {
  _shimmerController = AnimationController(
    duration: const Duration(milliseconds: 1800), // Faster for more visible effect
    vsync: this,
  );
  _shimmerAnimation = Tween<double>(
    begin: -2.0,
    end: 2.0,
  ).animate(CurvedAnimation(
    parent: _shimmerController,
    curve: Curves.linear,
  ));
}

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'multipart/form-data'},
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  void _initializeFaceDetector() {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    } catch (e) {
      debugPrint('Face detector initialization error: $e');
      if (mounted) {
        setState(
          () => _errorMessage = 'Failed to initialize face detector: $e',
        );
      }
    }
  }

  void _resetAlignment() {
    _isAligned = false;
    if (mounted) {
      _cancelTimer();
    } else {
      _cancelTimer(skipStateUpdate: true);
    }
    _countdown = 5;
  }

  void _resetToDefaultState() {
    if (mounted) {
      setState(() {
        _isAligned = false;
        _countdown = 5;
      });
      _cancelTimer();
    } else {
      _cancelTimer(skipStateUpdate: true);
    }
  }

  Future<bool> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      return status.isGranted;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _isInitializing) return;

    setState(() {
      _isInitializing = true;
      _isInitialized = false;
      _errorMessage = null;
      _capturedImage = null;
      _reportImageUrl = null;
      _analysisResults = null;
      _apiError = null;
      _isLoadingAnnotatedImage = false;
      _annotatedImageLoaded = false;
      _imagePreloadComplete = false;
      _resetAlignment();
    });
    
    // Reset shimmer timing
    _shimmerStartTime = null;

    try {
      // If pre-initialized camera is available and still initialized, use it directly
      // But skip if we're forcing reinitialization
      if (!_forceReinitialization &&
          widget.cameraController != null && 
          widget.cameraController!.value.isInitialized && 
          _controller == null) {
        debugPrint('Using pre-initialized camera controller');
        _controller = widget.cameraController;
        _cameras = widget.availableCameras;

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
            _forceReinitialization = false; // Reset the flag
          });
          await _startImageStream();
          return;
        }
      }

      // Fallback: Initialize camera ourselves (shouldn't happen often now)
      debugPrint('Fallback: Initializing camera on FaceScanResult page');
      
      await _disposeController();

      final hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied.');
      }

      if (widget.availableCameras != null) {
        _cameras = widget.availableCameras;
      } else {
        _cameras = await _getCamerasWithRetry();
      }

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      final selectedCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      await _createController(selectedCamera);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
        _forceReinitialization = false; // Reset the flag after successful initialization
      });

      await _startImageStream();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableError(e.toString());
          _isInitializing = false;
          _isInitialized = false;
          _forceReinitialization = false; // Reset the flag on error too
        });
      }
    }
  }

  Future<List<CameraDescription>> _getCamerasWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final cameras = await availableCameras().timeout(
          const Duration(seconds: 5),
        );
        return cameras;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * retryCount));
      }
    }

    throw Exception('Failed to get cameras after $maxRetries attempts');
  }

  Future<void> _createController(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize().timeout(const Duration(seconds: 10));
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Cannot start image stream: controller not ready');
      return;
    }

    try {
      debugPrint('Starting image stream...');
      await _controller!.startImageStream(_processFrame);
      debugPrint('Image stream started successfully');
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to start camera stream: $e');
      }
    }
  }

  String _getReadableError(String error) {
    if (error.contains('timeout') || error.contains('timed out')) {
      return 'Camera is taking too long to respond. Please try again.';
    } else if (error.contains('permission') || error.contains('denied')) {
      return 'Camera permission is required. Please grant permission in Settings.';
    } else if (error.contains('No cameras available')) {
      return 'No cameras found on this device.';
    } else if (error.contains('already in use') || error.contains('in use')) {
      return 'Camera is being used by another app. Please close other camera apps.';
    } else {
      return 'Failed to initialize camera. Please try again.';
    }
  }

  Future<void> _stopCameraAfterCapture() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
          debugPrint('Camera stream stopped after successful capture');
        }
        // Always dispose the camera to turn off the light after successful capture
        await _controller!.dispose();
        _controller = null;
        debugPrint('Camera fully disposed after successful capture');
      } catch (e) {
        debugPrint('Error stopping camera: $e');
      }
    }
  }

  Future<void> _disposeController() async {
    debugPrint('Face scan: Starting camera disposal...');
    _cancelTimer(skipStateUpdate: true);

    if (_controller != null) {
      try {
        // Check if controller is still initialized before disposing
        if (_controller!.value.isInitialized) {
          debugPrint('Face scan: Camera is initialized, stopping stream and disposing...');
          if (_controller!.value.isStreamingImages) {
            await _controller!.stopImageStream();
            debugPrint('Face scan: Image stream stopped');
          }
          await _controller!.dispose().timeout(
            const Duration(seconds: 3),
            onTimeout: () => debugPrint('Face scan: Camera disposal timed out'),
          );
          debugPrint('Face scan: Camera disposed successfully');
        } else {
          debugPrint('Face scan: Camera was already disposed or not initialized');
        }
      } catch (e) {
        debugPrint('Face scan: Error disposing camera: $e');
      } finally {
        _controller = null;
        debugPrint('Face scan: Camera controller set to null');
      }
    } else {
      debugPrint('Face scan: No camera controller to dispose');
    }
  }

  void _processFrame(CameraImage image) async {
    if (_isDetecting ||
        !mounted ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    _isDetecting = true;

    try {
      final input = _convertCameraImage(image);
      if (input != null) {
        final faces = await _faceDetector.processImage(input);
        if (mounted) {
          setState(() => _faces = faces);
          _evaluateAlignment();
        }
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _controller?.description;
      if (camera == null) return null;

      final rotation = _getImageRotation(camera);
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  InputImageRotation? _getImageRotation(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;

    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }



void _evaluateAlignment() {
  if (_controller?.value.previewSize == null || !mounted) return;

  bool newAlignmentState = false;

  if (_faces.isNotEmpty) {
    final face = _faces.first;

    // 🔹 Relax head rotation tolerance from ±10° → ±15°
    final rotY = face.headEulerAngleY ?? 0;
    final rotZ = face.headEulerAngleZ ?? 0;
    final lookingStraight = rotY.abs() < 15 && rotZ.abs() < 15;

    final preview = _controller!.value.previewSize!;
    final box = face.boundingBox;
    final centerX = box.center.dx;
    final centerY = box.center.dy;

    // Screen center
    final cx = preview.width / 2;
    final cy = preview.height / 2;

    final dx = (centerX - cx).abs();
    final dy = (centerY - cy).abs();

    // 🔹 Make oval larger → rx = 50% width, ry = 65% height
    final rx = preview.width * 0.5;
    final ry = preview.height * 0.65;

    final insideOval = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) < 1;

    newAlignmentState = lookingStraight && insideOval;
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
      try {
        setState(() => _isAligned = true);
        _startCountdown();
      } catch (e) {
        debugPrint('Error in _onAligned setState: $e');
      }
    }
  }

  void _onMisaligned() {
    if (_isAligned && mounted) {
      try {
        setState(() {
          _isAligned = false;
          _countdown = 5; // Reset countdown immediately when misaligned
        });
        _cancelTimer();
      } catch (e) {
        debugPrint('Error in _onMisaligned setState: $e');
        _cancelTimer(skipStateUpdate: true);
      }
    }
  }

  void _startCountdown() {
    _countdown = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      
      // Check alignment before each countdown tick
      _evaluateAlignment();
      
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
          try {
            setState(() => _countdown--);
          } catch (e) {
            debugPrint('Error in countdown setState: $e');
            t.cancel();
          }
        } else {
          t.cancel();
        }
      }
    });
  }

  void _cancelTimer({bool skipStateUpdate = false}) {
    _timer?.cancel();
    _timer = null;
    // Only update state if we're not disposing and mounted
    if (!skipStateUpdate && mounted) {
      try {
        setState(() => _countdown = 5);
      } catch (e) {
        debugPrint('Error in _cancelTimer setState: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (!_isAligned) {
      _cancelTimer();
      return;
    }
    try {
      // Stop image stream to pause camera processing
      await _controller!.stopImageStream();
      final file = await _controller!.takePicture();
      if (mounted) {
        // Process the image first (flip if front camera)
        final processedImageFile = await _processImageForUpload(file);
        
        setState(() {
          _capturedImage = processedImageFile;
          _reportImageUrl = null;
          _analysisResults = null;
          _apiError = null;
        });

        // Automatically send to API after capture
        await _sendImageToAPI(file);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to capture photo: $e');
      }
    }
  }

  Future<XFile> _processImageForUpload(XFile imageFile) async {
    // If it's a front camera, flip the image horizontally
    if (_controller?.description.lensDirection == CameraLensDirection.front) {
      try {
        final bytes = await imageFile.readAsBytes();
        final image = img.decodeImage(bytes);
        
        if (image != null) {
          // Flip horizontally
          final flippedImage = img.flipHorizontal(image);
          
          // Save the flipped image to a temporary file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/flipped_face_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(img.encodeJpg(flippedImage));
          
          return XFile(tempFile.path);
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
      }
    }
    
    // Return original image if not front camera or if processing failed
    return imageFile;
  }

  Future<void> _sendImageToAPI(XFile imageFile) async {
    if (!mounted) return;

    final secureStorage = SecureStorage();
    final userId = await secureStorage.getUserId();
    setState(() {
      _isProcessingAPI = true;
      _apiError = null;
      _reportImageUrl = null;
      _analysisResults = null;
    });

    try {
      // Process the image (flip if front camera)
      final processedImageFile = await _processImageForUpload(imageFile);
      
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          processedImageFile.path,
          filename: 'face_image.jpg',
        ),
        'include_annotated_image': 'true', // Request annotated image
        'user_id': userId, // <-- added here
      });

      debugPrint('Sending image to API: $_apiEndpoint');

      final response = await _dio.post(
        _apiEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json, // Expect JSON response
        ),
      );

      debugPrint('API Response Status: ${response.statusCode}');
      logJson(response.data);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Extract analysis results
          _analysisResults = responseData;

          // Extract report image URL
          final report = responseData['report'] as Map<String, dynamic>?;
          final imageUrl = report?['image_url'] as String?;
          
          if (imageUrl != null) {
            // Construct full URL
            _reportImageUrl = '${Env.backendBase}$imageUrl';
            debugPrint('Report image URL: $_reportImageUrl');
            print(_token);
          }

          if (mounted) {
            setState(() {
              _isProcessingAPI = false;
              // Start shimmer effect when annotated image URL is received
              if (_reportImageUrl != null) {
                debugPrint('Setting shimmer states: _isLoadingAnnotatedImage = true, _annotatedImageLoaded = false');
                _isLoadingAnnotatedImage = true;
                _annotatedImageLoaded = false;
              }
            });
            
            // Start shimmer animation
            if (_reportImageUrl != null) {
              debugPrint('Report image URL received, starting shimmer effect');
              _startShimmerEffect();
            }
            
            // Turn off camera after successful API response
            await _stopCameraAfterCapture();
          }
        } else {
          throw Exception(responseData['error_message'] ?? 'Analysis failed');
        }
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Dio Error: $e');
      String errorMessage = 'Failed to analyze image';

      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Response timeout. Please try again.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage =
            'Server error (${e.response?.statusCode}): ${e.response?.statusMessage}';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Connection error. Please check your internet connection.';
      } else {
        errorMessage = 'Network error: ${e.message}';
      }

      if (mounted) {
        setState(() {
          _apiError = errorMessage;
          _isProcessingAPI = false;
          _reportImageUrl = null;
        });
      }
    } catch (e) {
      debugPrint('API Error: $e');
      if (mounted) {
        setState(() {
          _apiError = 'Failed to analyze image: ${e.toString()}';
          _isProcessingAPI = false;
          _reportImageUrl = null;
        });
      }
    }
  }

  Future<String?> _getAuthToken() async {
    try {
    final sharedPrefs = await SharedPreferences.getInstance();
    final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
    _token = accessToken!;
    return accessToken;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _retryInitialization() async {
    // First dispose any existing controller
    await _disposeController();
    
    setState(() {
      _errorMessage = null;
      _reportImageUrl = null;
      _analysisResults = null;
      _apiError = null;
      _capturedImage = null;
      _isInitialized = false;
      _isInitializing = false;
      _isProcessingAPI = false;
      _isLoadingAnnotatedImage = false;
      _annotatedImageLoaded = false;
      _imagePreloadComplete = false;
      _forceReinitialization = true; // Force complete reinitialization
      _resetAlignment();
    });
    
    // Reset shimmer timing and stop effect
    _shimmerStartTime = null;
    _stopShimmerEffect();
    
    // Reinitialize camera from scratch
    await _initializeCamera();
  }

Widget _buildImageWidget() {
  if (_capturedImage == null) {
    return const SizedBox.shrink();
  }

  return GestureDetector(
    onDoubleTapDown: (TapDownDetails details) {
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      if (currentScale > 1.0) {
        // If zoomed in, reset to default
        _transformationController.value = Matrix4.identity();
      } else {
        // If at default, zoom to 2x at the tap location
        final tapPosition = details.localPosition;
        final zoomScale = 2.0;
        
        // Calculate the transformation matrix to zoom at the tap point
        // First translate so the tap point is at origin, then scale, then translate back
        final matrix = Matrix4.identity()
          ..translate(-tapPosition.dx * (zoomScale - 1), -tapPosition.dy * (zoomScale - 1))
          ..scale(zoomScale);
        
        _transformationController.value = matrix;
      }
    },
    child: InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.9,
      maxScale: 5.0, // Allow up to 5x zoom for detailed analysis
      boundaryMargin: const EdgeInsets.all(20.0),
      panEnabled: true,
      scaleEnabled: true,
      onInteractionEnd: (ScaleEndDetails details) {
        // Auto-snap to default position when zoomed out to 90% or below
        if (details.velocity.pixelsPerSecond.distance < 50) {
          final currentScale = _transformationController.value.getMaxScaleOnAxis();
          if (currentScale <= 1.0) {
            // Animate back to default position and scale
            _transformationController.value = Matrix4.identity();
          }
        }
      },
      child: Stack(
      fit: StackFit.expand,
      children: [
      // Base layer: Captured image
      Image.file(
        File(_capturedImage!.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error displaying captured image: $error');
          return const Center(
            child: Text(
              'Error loading captured image',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
      
      // Shimmer layer: Show when loading annotated image
      if (_isLoadingAnnotatedImage && !_annotatedImageLoaded) ...[
        _buildShimmerOverlay(),
        // Debug indicator - remove this later
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SHIMMER ACTIVE\nPreload: $_imagePreloadComplete',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
      
      // Final layer: Annotated image (when fully loaded)
      if (_reportImageUrl != null && _annotatedImageLoaded)
        FutureBuilder<String?>(
          future: _getAuthToken(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.network(
                _reportImageUrl!,
                fit: BoxFit.cover,
                headers: {
                  'Authorization': 'Bearer ${snapshot.data}',
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error displaying processed image: $error');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _annotatedImageLoaded = false;
                        _isLoadingAnnotatedImage = false;
                      });
                      _stopShimmerEffect();
                    }
                  });
                  return const SizedBox.shrink();
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      
      // Invisible image loader to track when annotated image is ready
      if (_reportImageUrl != null && _isLoadingAnnotatedImage && !_annotatedImageLoaded)
        Positioned(
          left: -1000, // Hide offscreen
          child: FutureBuilder<String?>(
            future: _getAuthToken(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.network(
                  _reportImageUrl!,
                  headers: {
                    'Authorization': 'Bearer ${snapshot.data}',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      debugPrint('Annotated image preloaded successfully');
                      // Mark preload as complete
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _imagePreloadComplete = true;
                          });
                          // Check if minimum time has passed, then stop shimmer
                          _checkAndStopShimmer();
                        }
                      });
                      return child;
                    } else {
                      debugPrint('Annotated image loading progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? 'unknown'}');
                    }
                    return const SizedBox.shrink();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error preloading annotated image: $error');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _annotatedImageLoaded = false;
                          _isLoadingAnnotatedImage = false;
                        });
                        _stopShimmerEffect();
                      }
                    });
                    return const SizedBox.shrink();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    ),
    ),
  );
}
  Widget _buildProcessingOverlay() {
    if (!_isProcessingAPI && _apiError == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isProcessingAPI) ...[
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Analyzing your skin...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'This may take a few seconds',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ] else if (_apiError != null) ...[
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _apiError!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _capturedImage != null
                    ? () => _sendImageToAPI(_capturedImage!)
                    : null,
                child: const Text('Retry Analysis'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    _shimmerController.dispose();
    _disposeController();
    super.dispose();
  }

Widget _buildShimmerOverlay() {
  return AnimatedBuilder(
    animation: _shimmerAnimation,
    builder: (context, child) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1.0, -1.0),
            end: const Alignment(1.0, 1.0),
            stops: [
              (_shimmerAnimation.value - 0.5).clamp(0.0, 1.0),
              (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
              (_shimmerAnimation.value - 0.1).clamp(0.0, 1.0),
              _shimmerAnimation.value.clamp(0.0, 1.0),
              (_shimmerAnimation.value + 0.1).clamp(0.0, 1.0),
              (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              (_shimmerAnimation.value + 0.5).clamp(0.0, 1.0),
            ],
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.05), // Very subtle start
              Colors.white.withOpacity(0.2), // Building up
              Colors.white.withOpacity(0.4), // Bright center
              Colors.white.withOpacity(0.2), // Fading out
              Colors.white.withOpacity(0.05), // Very subtle end
              Colors.transparent,
            ],
          ),
        ),
      );
    },
  );
}

void _startShimmerEffect() {
  debugPrint('_startShimmerEffect called - mounted: $mounted, isAnimating: ${_shimmerController.isAnimating}');
  if (mounted && !_shimmerController.isAnimating) {
    debugPrint('Starting shimmer animation for report image URL: $_reportImageUrl');
    _shimmerStartTime = DateTime.now();
    _shimmerController.repeat();
  } else {
    debugPrint('Shimmer not started - mounted: $mounted, isAnimating: ${_shimmerController.isAnimating}');
  }
}

void _stopShimmerEffect() {
  debugPrint('_stopShimmerEffect called - mounted: $mounted, isAnimating: ${_shimmerController.isAnimating}');
  
  // Ensure minimum shimmer duration of 3 seconds for better UX
  if (_shimmerStartTime != null) {
    final elapsed = DateTime.now().difference(_shimmerStartTime!);
    const minDuration = Duration(seconds: 3);
    
    if (elapsed < minDuration) {
      final remainingTime = minDuration - elapsed;
      debugPrint('Shimmer running for ${elapsed.inMilliseconds}ms, waiting ${remainingTime.inMilliseconds}ms more...');
      
      Timer(remainingTime, () {
        if (mounted && _shimmerController.isAnimating) {
          debugPrint('Minimum duration reached, stopping shimmer...');
          _shimmerController.stop();
          _shimmerController.reset();
          _shimmerStartTime = null;
          // Update state to show final image
          if (mounted) {
            setState(() {
              _annotatedImageLoaded = true;
              _isLoadingAnnotatedImage = false;
            });
          }
        }
      });
      return;
    }
  }
  
  if (mounted && _shimmerController.isAnimating) {
    debugPrint('Stopping shimmer animation immediately...');
    _shimmerController.stop();
    _shimmerController.reset();
    _shimmerStartTime = null;
  } else {
    debugPrint('Shimmer not stopped - mounted: $mounted, isAnimating: ${_shimmerController.isAnimating}');
  }
}

void _checkAndStopShimmer() {
  debugPrint('_checkAndStopShimmer called - imagePreloadComplete: $_imagePreloadComplete');
  
  if (!_imagePreloadComplete) {
    debugPrint('Image not preloaded yet, keeping shimmer running');
    return;
  }
  
  // Check if minimum time has elapsed
  if (_shimmerStartTime != null) {
    final elapsed = DateTime.now().difference(_shimmerStartTime!);
    const minDuration = Duration(seconds: 2); // Reduced to 2 seconds
    
    if (elapsed >= minDuration) {
      debugPrint('Minimum duration passed and image ready, stopping shimmer...');
      _stopShimmerImmediately();
    } else {
      final remainingTime = minDuration - elapsed;
      debugPrint('Image ready but waiting ${remainingTime.inMilliseconds}ms more for minimum duration...');
      
      Timer(remainingTime, () {
        if (mounted) {
          debugPrint('Minimum duration reached, stopping shimmer now...');
          _stopShimmerImmediately();
        }
      });
    }
  } else {
    debugPrint('No shimmer start time, stopping immediately...');
    _stopShimmerImmediately();
  }
}

void _stopShimmerImmediately() {
  if (mounted && _shimmerController.isAnimating) {
    debugPrint('Stopping shimmer animation and showing final image...');
    _shimmerController.stop();
    _shimmerController.reset();
    _shimmerStartTime = null;
    
    setState(() {
      _annotatedImageLoaded = true;
      _isLoadingAnnotatedImage = false;
    });
  }
}

  Widget _buildConditionChip(String label) {
    // Capitalize each word
    final capitalized = toBeginningOfSentenceCase(label.toLowerCase()) ?? label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3), // blue
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        capitalized,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          // Dispose camera before popping
          debugPrint('Face scan page: User navigating back, disposing camera...');
          final navigator = Navigator.of(context);
          await _disposeController();
          debugPrint('Face scan page: Camera disposed, navigating back');
          if (mounted) {
            navigator.pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_capturedImage != null || _reportImageUrl != null || _controller == null)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 28,
                        color: Colors.grey,
                      ),
                      onPressed: _retryInitialization,
                    ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () async {
                      debugPrint('Face scan: Close button pressed, disposing camera...');
                      final navigator = Navigator.of(context);
                      await _disposeController();
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
              ),
              const SizedBox(height: 40),
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Error state
                        if (_errorMessage != null) ...[
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _retryInitialization,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ]
                        // Loading state
                        else if (_isInitializing ||
                            (!_isInitialized && _controller == null)) ...[
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Initializing camera...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                        // Captured/Processed image state
                        else if (_capturedImage != null) ...[
                          _buildImageWidget(),
                          _buildProcessingOverlay(),
                          // Status indicator in top-right
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _analysisResults != null
                                    ? Colors.green.withOpacity(0.8)
                                    : _apiError != null
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.orange.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _analysisResults != null
                                    ? 'Analysis Complete'
                                    : _apiError != null
                                    ? 'Analysis Failed'
                                    : _isProcessingAPI
                                    ? 'Analyzing...'
                                    : 'Captured',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ]
                        // Camera preview state
                        else if (_isInitialized &&
                            _controller != null &&
                            _controller!.value.isInitialized) ...[
                          ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.previewSize!.height,
                                  height: _controller!.value.previewSize!.width,
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                          ),

                          CustomPaint(
                            painter: _OvalPainter(
                              color: _isAligned ? Colors.green : Colors.red,
                            ),
                          ),
                          Center(
                            child: _isAligned
                                ? Text(
                                    '$_countdown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.face,
                                        color: Colors.white70,
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Align your face inside the oval and look straight',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                          ),
                        ]
                        // Fallback loading state
                        else ...[
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_analysisResults != null)
                      ...(_analysisResults!['analysis']?['skin_condition']?['all_predictions']
                              as Map<String, dynamic>)
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildConditionChip(
                                "${entry.key} ${(entry.value as num).toStringAsFixed(0)}%",
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// Oval overlay painter
class _OvalPainter extends CustomPainter {
  final Color color;
  _OvalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.8,
    );
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _OvalPainter old) => old.color != color;
}