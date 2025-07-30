import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:nepika/core/widgets/back_button.dart';
import '../../../core/widgets/custom_button.dart';
// import '../questions/menstrual_cycle_tracking_page.dart';
import 'face_scan_result_page.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _currentStep = 1;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Navigate to result page after scan
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FaceScanResultPage(
            skinScore: 80,
            faceImagePath: 'assets/images/face_scan_girl_image.png',
            acnePercent: 30,
            issues: const ['Acne', 'Open Pors', 'Dark Spot'],
            onIssueTap: (issue) {},
          ),
        ),
      );
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
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
        return 'Start Scan';
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
return Scaffold(
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
            child: Column(
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
                          child: Image.asset(
                            _referenceImagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Stack(
                                children: [
                                  if (_isCameraInitialized &&
                                      _cameraController != null)
                                    Positioned.fill(
                                      child:
                                          CameraPreview(_cameraController!),
                                    )
                                  else
                                    Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  if (_currentStep == 3)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: FaceOverlayPainter(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
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
                const Spacer(), // Now works properly
              ],
            ),
          ),
          // Progress bar, button and footer
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
              onPressed: _handleNext,
              icon: const Icon(Icons.arrow_forward),
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
