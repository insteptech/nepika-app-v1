import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/presentation/pages/first_scan/face_scan.dart';
import '../../../core/widgets/custom_button.dart';

class ScanGuidenceScreen extends StatefulWidget {
  const ScanGuidenceScreen({super.key});

  @override
  State<ScanGuidenceScreen> createState() => _ScanGuidenceScreenState();
}

class _ScanGuidenceScreenState extends State<ScanGuidenceScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  List<CameraDescription>? _cameras;
  String? _cameraError;
  int _currentStep = 1;
  final int _totalSteps = 3;

  late PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep - 1);
    // Start camera initialization immediately when guidance screen loads
    _initializeCameraEarly();
  }

  Future<void> _initializeCameraEarly() async {
    if (_isInitializingCamera) return;
    
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    try {
      // Get available cameras with retry logic
      _cameras = await _getCamerasWithRetry();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Find front camera or use first available
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Create and initialize controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isInitializingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _cameraError = _getReadableError(e.toString());
          _isInitializingCamera = false;
          _isCameraInitialized = false;
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
          onTimeout: () => throw TimeoutException(
            'Camera fetch timed out',
            const Duration(seconds: 5),
          ),
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

  String _getReadableError(String error) {
    if (error.contains('timeout') || error.contains('timed out')) {
      return 'Camera initialization timed out. Please try again.';
    } else if (error.contains('permission') || error.contains('denied')) {
      return 'Camera permission required. Check settings and restart.';
    } else if (error.contains('No cameras available')) {
      return 'No cameras found on this device.';
    } else if (error.contains('already in use') || error.contains('in use')) {
      return 'Camera in use by another app. Close other camera apps.';
    } else {
      return 'Camera initialization failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Don't dispose camera here - pass it to next screen
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep < _totalSteps) {
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On step 3, check camera status before navigating
      if (!_isCameraInitialized && !_isInitializingCamera && _cameraError != null) {
        // Retry camera initialization
        _retryCameraInit();
        return;
      }
      
      if (_isInitializingCamera) {
        // Still initializing, wait a bit more
        return;
      }

      // Navigate to scan screen
      if (_isCameraInitialized && _cameraController != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FaceScanResultPage(
              cameraController: _cameraController,
              availableCameras: _cameras,
            ),
          ),
        );
      } else {
        // Fallback: go without pre-initialized camera
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const FaceScanResultPage(),
          ),
        );
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      _pageController.animateToPage(
        _currentStep - 2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Dispose camera when going back to previous screen
      debugPrint('Guidance page: Going back, disposing camera...');
      _cameraController?.dispose();
      debugPrint('Guidance page: Camera disposed, navigating back');
      Navigator.of(context).pop();
    }
  }

  void _retryCameraInit() {
    _cameraController?.dispose();
    _cameraController = null;
    _initializeCameraEarly();
  }

  String get _instructionText {
    switch (_currentStep) {
      case 1:
        return 'Hold phone in front\nof your face';
      case 2:
        return 'Remove glasses';
      case 3:
        return 'Fit your face in\nthe oval';
      default:
        return 'Hold phone in front\nof your face';
    }
  }

  String get _buttonText {
    switch (_currentStep) {
      case 1:
        return 'Next';
      case 2:
        return 'Next';
      case 3:
        return _isCameraInitialized ? 'Start Scan' : 'Initializing...';
      default:
        return 'Next';
    }
  }

  String get _referenceImagePath {
    switch (_currentStep) {
      case 1:
        return 'assets/images/camera_guide_1_image.png';
      case 2:
        return 'assets/images/camera_guide_2_image.png';
      case 3:
        return 'assets/images/camera_guide_3_image.png';
      default:
        return 'assets/images/camera_guide_1_image.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          debugPrint('Guidance page: Back gesture detected, disposing camera...');
          _cameraController?.dispose();
          debugPrint('Guidance page: Camera disposed via back gesture');
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomBackButton(onPressed: _handleBack, label: 'Back'),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index + 1;
                    });
                  },
                  itemCount: _totalSteps,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final squareSize = constraints.maxWidth;
                            return Container(
                              width: squareSize,
                              height: squareSize,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _buildStepContent(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _instructionText,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),
              
              // Camera status indicator
              if (_currentStep == 3) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCameraInitialized 
                        ? Colors.green.withOpacity(0.1)
                        : _cameraError != null 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCameraInitialized 
                          ? Colors.green
                          : _cameraError != null 
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInitializingCamera)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _isCameraInitialized 
                              ? Icons.check_circle 
                              : _cameraError != null
                                  ? Icons.error
                                  : Icons.camera_alt,
                          size: 16,
                          color: _isCameraInitialized 
                              ? Colors.green
                              : _cameraError != null 
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _isCameraInitialized 
                            ? 'Camera Ready'
                            : _cameraError != null 
                                ? 'Camera Error'
                                : 'Preparing Camera...',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isCameraInitialized 
                              ? Colors.green
                              : _cameraError != null 
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                      if (_cameraError != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _retryCameraInit,
                          child: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Progress bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 70),
                child: Row(
                  children: List.generate(_totalSteps, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index < _totalSteps - 1 ? 8 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: index < _currentStep
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0x3898EDFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _buttonText,
                  onPressed: (_currentStep == 3 && !_isCameraInitialized && _cameraError == null) 
                      ? null 
                      : _handleNext,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  iconOnLeft: false,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Secure Photo | Privacy Protected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStepContent() {
    // Always show reference image for all steps, including step 3
    // Don't show camera preview on guidance screen
    
    // Show error state for step 3 if camera failed
    if (_currentStep == 3 && _cameraError != null && !_isInitializingCamera) {
      return Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: _retryCameraInit,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Always show reference image (including step 3)
    return Image.asset(
      _referenceImagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Custom painter for face detection overlay (only used for step 3)
class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw face outline (oval) - centered and properly sized
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final faceRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.65,
      height: size.height * 0.5,
    );

    canvas.drawOval(faceRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}