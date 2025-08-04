import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
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
        setState(() => _errorMessage = 'Failed to initialize face detector: $e');
      }
    }
  }

  // Reset alignment and countdown
  void _resetAlignment() {
    _isAligned = false;
    _cancelTimer();
    _countdown = 5;
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _isInitializing) return;
    
    setState(() {
      _isInitializing = true;
      _isInitialized = false;
      _errorMessage = null;
      _capturedImage = null;
      _resetAlignment();
    });

    try {
      await _disposeController();

      if (widget.cameraController != null && 
          widget.cameraController!.value.isInitialized) {
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
      });
      
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
          onTimeout: () => throw TimeoutException('Camera fetch timed out', const Duration(seconds: 8)),
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
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Camera initialization timed out', 
        const Duration(seconds: 15)
      ),
    );
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      await _controller!.startImageStream(_processFrame);
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
    } else if (error.contains('permission')) {
      return 'Camera permission is required. Please grant permission and try again.';
    } else if (error.contains('No cameras available')) {
      return 'No cameras found on this device.';
    } else if (error.contains('already in use')) {
      return 'Camera is being used by another app. Please close other camera apps.';
    } else {
      return 'Failed to initialize camera. Please try again.';
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
    if (_isDetecting || !mounted || _controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    _isDetecting = true;

    try {
      final input = _convertCameraImage(image);
      if (input != null) {
        final faces = await _faceDetector.processImage(input);
        if (mounted) {
          setState(() => _faces = faces);
          if (_timer == null) _evaluateAlignment();
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

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: metadata,
      );
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
        setState(() => _capturedImage = file);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to capture photo: $e');
      }
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _errorMessage = null;
    });
    await _initializeCamera();
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
                  if (_capturedImage != null)
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
                      await _disposeController();
                      if (mounted) Navigator.of(context).pop();
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
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
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
                        else if (_isInitializing || (!_isInitialized && _controller == null)) ...[
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
                        // Captured image state
                        else if (_capturedImage != null) ...[
                          Image.file(
                            File(_capturedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ]
                        // Camera preview state
                        else if (_isInitialized && _controller != null && _controller!.value.isInitialized) ...[
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
                          const Center(child: CircularProgressIndicator(color: Colors.white)),
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
      ..color = color.withOpacity(0.5)
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