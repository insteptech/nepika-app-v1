import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:nepika/core/config/env.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

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

class _FaceScanResultPageState extends State<FaceScanResultPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isInitializing = false;
  String? _errorMessage;
  List<Face> _faces = [];

  // Alignment & capture state
  bool _isAligned = false;
  int _countdown = 5;
  Timer? _timer;
  XFile? _capturedImage;
  Dio _dio = Dio();

  // API state - Updated for complete analysis
  bool _isProcessingAPI = false;
  Uint8List? _apiResponseImageBytes;
  Map<String, dynamic>? _analysisResults;
  String? _apiError;

  // Updated API endpoint to use the combined analysis
  static const String _apiEndpoint =
      '${Env.baseUrl}/model/face-scan/analyze_face_complete';

  @override
  void initState() {
    super.initState();
    _initializeDio();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'multipart/form-data'},
        // Change response type to JSON since we're getting analysis data + base64 image
        responseType: ResponseType.json,
      ),
    );

    // Add interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false, // Keep false as response might be large
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

  // Reset alignment and countdown
  void _resetAlignment() {
    _isAligned = false;
    _cancelTimer();
    _countdown = 5;
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
      _apiResponseImageBytes = null;
      _analysisResults = null;
      _apiError = null;
      _resetAlignment();
    });

    try {
      await _disposeController();

      // First check camera permissions
      debugPrint('Checking camera permissions...');
      final hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        throw Exception(
          'Camera permission denied. Please grant camera permission in Settings.',
        );
      }

      if (widget.cameraController != null &&
          widget.cameraController!.value.isInitialized) {
        debugPrint('Using provided camera controller');
        _controller = widget.cameraController;
        _cameras = widget.availableCameras;

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
          });
          await _startImageStream();
          return;
        }
      }

      debugPrint('Getting available cameras...');
      if (widget.availableCameras != null) {
        _cameras = widget.availableCameras;
      } else {
        _cameras = await _getCamerasWithRetry();
      }

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      debugPrint('Found ${_cameras!.length} cameras');
      final selectedCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      debugPrint(
        'Selected camera: ${selectedCamera.name} (${selectedCamera.lensDirection})',
      );
      await _createController(selectedCamera);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });

      debugPrint('Camera initialized successfully, starting image stream...');
      await _startImageStream();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableError(e.toString());
          _isInitializing = false;
          _isInitialized = false;
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
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException(
            'Camera fetch timed out',
            const Duration(seconds: 8),
          ),
        );
        return cameras;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;

        debugPrint('Camera fetch attempt $retryCount failed: $e');
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    throw Exception('Failed to get cameras after $maxRetries attempts');
  }

  Future<void> _createController(CameraDescription camera) async {
    debugPrint('Creating camera controller for: ${camera.name}');

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    debugPrint('Initializing camera controller...');
    await _controller!.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Camera initialization timed out',
        const Duration(seconds: 15),
      ),
    );

    debugPrint('Camera controller initialized successfully');
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
      return 'Camera permission is required. Please grant permission in Settings and restart the app.';
    } else if (error.contains('No cameras available')) {
      return 'No cameras found on this device.';
    } else if (error.contains('already in use') || error.contains('in use')) {
      return 'Camera is being used by another app. Please close other camera apps and try again.';
    } else if (error.contains('Cannot get cameras')) {
      return 'Unable to access device cameras. Please check permissions and try again.';
    } else {
      return 'Failed to initialize camera. Please try again.\nError: ${error.length > 100 ? error.substring(0, 100) + "..." : error}';
    }
  }

  Future<void> _disposeController() async {
    _cancelTimer();

    if (_controller != null) {
      try {
        if (widget.cameraController == null) {
          if (_controller!.value.isStreamingImages) {
            await _controller!.stopImageStream();
          }

          await _controller!.dispose().timeout(
            const Duration(seconds: 3),
            onTimeout: () => debugPrint('Camera disposal timed out'),
          );
        }
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      } finally {
        _controller = null;
      }
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
          debugPrint('Detected ${faces.length} faces');
          if (_timer == null) _evaluateAlignment();
        }
      } else {
        debugPrint('Failed to convert camera image to InputImage');
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
      // Don't set error message here as it would be too frequent
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

    if (_faces.isEmpty) {
      _onMisaligned();
      return;
    }

    final face = _faces.first;
    final rotY = face.headEulerAngleY ?? 0;
    final rotZ = face.headEulerAngleZ ?? 0;
    final lookingStraight = rotY.abs() < 10 && rotZ.abs() < 10;

    final preview = _controller!.value.previewSize!;
    final box = face.boundingBox;
    final centerX = box.center.dx;
    final centerY = box.center.dy;
    final cx = preview.width / 2;
    final cy = preview.height / 2;
    final dx = (centerX - cx).abs();
    final dy = (centerY - cy).abs();
    final rx = preview.width * 0.4;
    final ry = preview.height * 0.5;
    final insideOval = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) < 1;

    (lookingStraight && insideOval) ? _onAligned() : _onMisaligned();
  }

  void _onAligned() {
    if (!_isAligned) {
      setState(() => _isAligned = true);
      _startCountdown();
    }
  }

  void _onMisaligned() {
    if (_isAligned || _timer != null) {
      setState(() => _isAligned = false);
      _cancelTimer();
    }
  }

  void _startCountdown() {
    _countdown = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      _evaluateAlignment();

      if (!_isAligned) {
        t.cancel();
        return;
      }

      if (_countdown == 0) {
        t.cancel();
        _capturePhoto();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _countdown = 5);
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.stopImageStream();
      final file = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _capturedImage = file;
          _apiResponseImageBytes = null;
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

  Future<void> _sendImageToAPI(XFile imageFile) async {
    if (!mounted) return;

    setState(() {
      _isProcessingAPI = true;
      _apiError = null;
      _apiResponseImageBytes = null;
      _analysisResults = null;
    });

    try {
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'face_image.jpg',
        ),
        'include_annotated_image': 'true', // Request annotated image
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
      debugPrint('API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          // Extract analysis results
          _analysisResults = responseData;
          
          // Extract and decode annotated image if available
          final analysis = responseData['analysis'] as Map<String, dynamic>?;
          final skinAreas = analysis?['skin_areas'] as Map<String, dynamic>?;
          final annotatedImageBase64 = skinAreas?['annotated_image'] as String?;
          
          if (annotatedImageBase64 != null) {
            // Remove data URL prefix if present
            String base64String = annotatedImageBase64;
            if (base64String.startsWith('data:image')) {
              base64String = base64String.split(',')[1];
            }
            
            try {
              final imageBytes = base64Decode(base64String);
              _apiResponseImageBytes = imageBytes;
            } catch (e) {
              debugPrint('Error decoding base64 image: $e');
            }
          }
          
          if (mounted) {
            setState(() {
              _isProcessingAPI = false;
            });
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
        });
      }
    } catch (e) {
      debugPrint('API Error: $e');
      if (mounted) {
        setState(() {
          _apiError = 'Failed to analyze image: ${e.toString()}';
          _isProcessingAPI = false;
        });
      }
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _errorMessage = null;
      _apiResponseImageBytes = null;
      _analysisResults = null;
      _apiError = null;
    });
    await _initializeCamera();
  }

  Widget _buildImageWidget() {
    // Always prioritize showing the API processed image
    if (_apiResponseImageBytes != null) {
      // Display the processed/annotated image
      return Image.memory(
        _apiResponseImageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error displaying processed image: $error');
          return const Center(
            child: Text(
              'Error loading processed image',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    }
    // Only show captured image while processing or if API failed
    else if (_capturedImage != null && (_isProcessingAPI || _apiError != null)) {
      // Display the original captured image as placeholder
      return Image.file(
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAnalysisOverlay() {
    if (_analysisResults == null || _isProcessingAPI) return const SizedBox.shrink();

    final quickSummary = _analysisResults!['quick_summary'] as Map<String, dynamic>?;
    
    if (quickSummary == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Analysis Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_analysisResults!['processing_time_seconds']}s',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisItem(
                    'Condition',
                    quickSummary['condition'] ?? 'Unknown',
                    '${((quickSummary['condition_confidence'] ?? 0) * 100).round()}%',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalysisItem(
                    'Skin Type',
                    quickSummary['skin_type'] ?? 'Unknown',
                    '${((quickSummary['type_confidence'] ?? 0) * 100).round()}%',
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (quickSummary['areas_detected'] != null && quickSummary['areas_detected'] > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${quickSummary['areas_detected']} areas detected',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, String confidence, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            confidence,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
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
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  if (_capturedImage != null || _apiResponseImageBytes != null)
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
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          _buildAnalysisOverlay(),

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
                          CameraPreview(_controller!),
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
            ],
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