import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Face Alignment Camera Screen
/// Provides a simple camera interface with face alignment guide
class FaceAlignmentCameraScreen extends StatefulWidget {
  const FaceAlignmentCameraScreen({super.key});

  @override
  State<FaceAlignmentCameraScreen> createState() => _FaceAlignmentCameraScreenState();
}

class _FaceAlignmentCameraScreenState extends State<FaceAlignmentCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    // Request camera permission
    final cameraPermission = await Permission.camera.request();
    
    if (cameraPermission.isGranted) {
      try {
        // Get available cameras
        _cameras = await availableCameras();
        
        if (_cameras.isNotEmpty) {
          // Use front camera if available, otherwise use first camera
          final frontCamera = _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          );
          
          // Initialize camera controller
          _cameraController = CameraController(
            frontCamera,
            ResolutionPreset.high,
            enableAudio: false,
          );
          
          await _cameraController!.initialize();
          
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        }
      } catch (e) {
        debugPrint('Error initializing camera: $e');
        if (mounted) {
          _showErrorDialog('Failed to initialize camera: ${e.toString()}');
        }
      }
    } else {
      if (mounted) {
        _showErrorDialog('Camera permission is required to take photos.');
      }
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close camera screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      final XFile image = await _cameraController!.takePicture();
      
      if (mounted) {
        // Return the image path
        Navigator.of(context).pop(image.path);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            
            // Face alignment guide overlay
            if (_isInitialized)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceAlignmentPainter(),
                ),
              ),
            
            // Top controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Align Your Face',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 40), // Spacer to center title
                ],
              ),
            ),
            
            // Instructions
            Positioned(
              bottom: 140,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Position your face within the circle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Make sure your face is well-lit and centered',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom controls
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isCapturing ? Colors.grey : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 32,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for face alignment guide
class FaceAlignmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final center = Offset(size.width / 2, size.height / 2 - 50);
    const radius = 120.0;
    
    // Draw main circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw corner guides
    const guideLength = 20.0;
    const guideOffset = radius * 0.7;
    
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Top-left guide
    canvas.drawLine(
      Offset(center.dx - guideOffset, center.dy - guideOffset),
      Offset(center.dx - guideOffset + guideLength, center.dy - guideOffset),
      guidePaint,
    );
    canvas.drawLine(
      Offset(center.dx - guideOffset, center.dy - guideOffset),
      Offset(center.dx - guideOffset, center.dy - guideOffset + guideLength),
      guidePaint,
    );
    
    // Top-right guide
    canvas.drawLine(
      Offset(center.dx + guideOffset, center.dy - guideOffset),
      Offset(center.dx + guideOffset - guideLength, center.dy - guideOffset),
      guidePaint,
    );
    canvas.drawLine(
      Offset(center.dx + guideOffset, center.dy - guideOffset),
      Offset(center.dx + guideOffset, center.dy - guideOffset + guideLength),
      guidePaint,
    );
    
    // Bottom-left guide
    canvas.drawLine(
      Offset(center.dx - guideOffset, center.dy + guideOffset),
      Offset(center.dx - guideOffset + guideLength, center.dy + guideOffset),
      guidePaint,
    );
    canvas.drawLine(
      Offset(center.dx - guideOffset, center.dy + guideOffset),
      Offset(center.dx - guideOffset, center.dy + guideOffset - guideLength),
      guidePaint,
    );
    
    // Bottom-right guide
    canvas.drawLine(
      Offset(center.dx + guideOffset, center.dy + guideOffset),
      Offset(center.dx + guideOffset - guideLength, center.dy + guideOffset),
      guidePaint,
    );
    canvas.drawLine(
      Offset(center.dx + guideOffset, center.dy + guideOffset),
      Offset(center.dx + guideOffset, center.dy + guideOffset - guideLength),
      guidePaint,
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}