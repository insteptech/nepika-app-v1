// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:camera/camera.dart';
// import '../../bloc/face_scan/face_scan_bloc.dart';
// import '../../bloc/face_scan/face_scan_event.dart';
// import '../../bloc/face_scan/face_scan_state.dart';
// import '../../bloc/face_scan/camera_bloc.dart';
// import '../../bloc/face_scan/camera_state.dart';
// import '../../bloc/face_scan/camera_event.dart';
// import '../../bloc/face_scan/face_alignment_bloc.dart';
// import '../../bloc/face_scan/face_alignment_state.dart' as alignment_states;
// import '../../bloc/face_scan/face_alignment_event.dart';
// import '../../../domain/face_scan/entities/camera_scan_session.dart';
// import 'widgets/face_scan_widgets.dart';

// /// Main face capture page that handles camera preview, face alignment, and image capture
// class FaceCapturePage extends StatefulWidget {
//   const FaceCapturePage({super.key});

//   @override
//   State<FaceCapturePage> createState() => _FaceCapturePageState();
// }

// class _FaceCapturePageState extends State<FaceCapturePage>
//     with WidgetsBindingObserver {
//   final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
//   int _countdown = 5;
//   bool _isCountdownActive = false;
//   bool _canCapture = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeCamera();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.paused:
//         _pauseCamera();
//         break;
//       case AppLifecycleState.resumed:
//         _resumeCamera();
//         break;
//       case AppLifecycleState.detached:
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.hidden:
//         _pauseCamera();
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: MultiBlocListener(
//         listeners: [
//           BlocListener<FaceScanBloc, FaceScanState>(
//             listener: _handleFaceScanStateChange,
//           ),
//           BlocListener<FaceAlignmentBloc, FaceAlignmentState>(
//             listener: _handleAlignmentStateChange,
//           ),
//         ],
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // Camera preview
//               _buildCameraPreview(),
              
//               // Face alignment overlay
//               _buildAlignmentOverlay(),
              
//               // Top UI elements
//               _buildTopUI(),
              
//               // Bottom UI elements
//               _buildBottomUI(),
              
//               // Countdown overlay
//               _buildCountdownOverlay(),
              
//               // Loading overlay
//               _buildLoadingOverlay(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCameraPreview() {
//     return BlocBuilder<CameraBloc, CameraState>(
//       builder: (context, state) {
//         if (state is CameraReady) {
//           return Positioned.fill(
//             child: CameraPreview(state.controller),
//           );
//         }
//         return const Center(
//           child: CircularProgressIndicator(
//             color: Colors.white,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAlignmentOverlay() {
//     return BlocBuilder<CameraBloc, CameraState>(
//       builder: (context, cameraState) {
//         if (cameraState is CameraReady) {
//           return Positioned.fill(
//             child: FaceScanWidgets.alignmentOverlay(
//               previewSize: cameraState.previewSize,
//               context: context,
//             ),
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }

//   Widget _buildTopUI() {
//     return Positioned(
//       top: 16,
//       left: 16,
//       right: 16,
//       child: Column(
//         children: [
//           // Back button and title
//           Row(
//             children: [
//               IconButton(
//                 onPressed: _handleBackPressed,
//                 icon: const Icon(
//                   Icons.arrow_back,
//                   color: Colors.white,
//                   size: 28,
//                 ),
//               ),
//               const Expanded(
//                 child: Text(
//                   'Face Scan',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(width: 48), // Balance for back button
//             ],
//           ),
          
//           const SizedBox(height: 24),
          
//           // Face detection status
//           BlocBuilder<FaceAlignmentBloc, FaceAlignmentState>(
//             builder: (context, state) {
//               return FaceScanWidgets.faceDetectionStatus(
//                 alignmentState: state,
//               );
//             },
//           ),
          
//           const SizedBox(height: 16),
          
//           // Alignment guidance
//           BlocBuilder<FaceAlignmentBloc, FaceAlignmentState>(
//             builder: (context, state) {
//               final issues = <AlignmentIssue>[];
//               if (state is FaceAlignmentDetectedButNotAligned) {
//                 issues.addAll(state.alignmentIssues);
//               }
//               return FaceScanWidgets.alignmentGuidance(issues: issues);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomUI() {
//     return Positioned(
//       bottom: 32,
//       left: 0,
//       right: 0,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Progress indicator (when processing)
//           BlocBuilder<FaceScanBloc, FaceScanState>(
//             builder: (context, state) {
//               if (state is FaceScanProcessing) {
//                 return FaceScanWidgets.scanProgressIndicator(
//                   progress: state.progress,
//                   isScanning: true,
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),
          
//           const SizedBox(height: 24),
          
//           // Capture button
//           BlocBuilder<FaceScanBloc, FaceScanState>(
//             builder: (context, state) {
//               final isCapturing = state is FaceScanCapturing;
//               return FaceScanWidgets.captureButton(
//                 onPressed: _handleCapturePressed,
//                 isEnabled: _canCapture && !_isCountdownActive,
//                 isCapturing: isCapturing,
//               );
//             },
//           ),
          
//           const SizedBox(height: 16),
          
//           // Instructions
//           const Text(
//             'Align your face in the oval and hold still',
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCountdownOverlay() {
//     return Positioned.fill(
//       child: Center(
//         child: FaceScanWidgets.countdownTimer(
//           countdown: _countdown,
//           isVisible: _isCountdownActive,
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingOverlay() {
//     return BlocBuilder<FaceScanBloc, FaceScanState>(
//       builder: (context, state) {
//         String message = '';
//         bool isVisible = false;
        
//         if (state is FaceScanInitializing) {
//           message = 'Initializing camera...';
//           isVisible = true;
//         } else if (state is FaceScanProcessing) {
//           message = 'Analyzing your skin...';
//           isVisible = true;
//         }
        
//         return LoadingOverlay(
//           message: message,
//           isVisible: isVisible,
//         );
//       },
//     );
//   }

//   // Event handlers
//   void _initializeCamera() {
//     context.read<CameraBloc>().add(
//       const CameraInitializationRequested(),
//     );
    
//     context.read<FaceAlignmentBloc>().add(
//       StartFaceAlignmentDetection(
//         sessionId: _sessionId,
//         toleranceSettings: _getDefaultTolerance(),
//       ),
//     );
//   }

//   void _pauseCamera() {
//     context.read<CameraBloc>().add(const CameraStreamStopRequested());
//     context.read<FaceAlignmentBloc>().add(
//       StopFaceAlignmentDetection(sessionId: _sessionId),
//     );
//   }

//   void _resumeCamera() {
//     context.read<CameraBloc>().add(const ResumeCamera());
//     context.read<FaceAlignmentBloc>().add(
//       StartFaceAlignmentDetection(
//         sessionId: _sessionId,
//         toleranceSettings: const FaceAlignmentTolerance(),
//       ),
//     );
//   }

//   void _handleBackPressed() {
//     context.read<FaceScanBloc>().add(
//       const CancelFaceScanSession(),
//     );
//     Navigator.of(context).pop();
//   }

//   void _handleCapturePressed() {
//     if (!_canCapture || _isCountdownActive) return;
    
//     _startCountdown();
//   }

//   void _startCountdown() {
//     if (_isCountdownActive) return;
    
//     setState(() {
//       _isCountdownActive = true;
//       _countdown = 5;
//     });
    
//     _runCountdown();
//   }

//   void _runCountdown() {
//     if (_countdown > 0) {
//       Future.delayed(const Duration(seconds: 1), () {
//         if (mounted && _isCountdownActive) {
//           // Check if still aligned
//           final alignmentState = context.read<FaceAlignmentBloc>().state;
//           if (alignmentState is FaceAlignmentAligned) {
//             setState(() {
//               _countdown--;
//             });
//             _runCountdown();
//           } else {
//             // Face not aligned, reset countdown
//             _resetCountdown();
//           }
//         }
//       });
//     } else {
//       // Countdown finished, capture image
//       _captureImage();
//     }
//   }

//   void _resetCountdown() {
//     setState(() {
//       _isCountdownActive = false;
//       _countdown = 5;
//     });
//   }

//   void _captureImage() {
//     _resetCountdown();
    
//     context.read<FaceScanBloc>().add(
//       const CaptureImageRequested(),
//     );
//   }

//   void _handleFaceScanStateChange(BuildContext context, FaceScanState state) {
//     if (state is FaceScanCompleted) {
//       // Navigate to results page
//       Navigator.of(context).pushReplacementNamed('/face-scan-results');
//     } else if (state is FaceScanErrorState) {
//       _showErrorDialog('Face scan failed. Please try again.');
//     }
//   }

//   void _handleAlignmentStateChange(BuildContext context, FaceAlignmentState state) {
//     setState(() {
//       _canCapture = state is FaceAlignmentAligned;
//     });
    
//     // Reset countdown if face becomes misaligned
//     if (state is! FaceAlignmentAligned && _isCountdownActive) {
//       _resetCountdown();
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper methods
//   FaceAlignmentTolerance _getDefaultTolerance() {
//     return const FaceAlignmentTolerance(
//       maxHeadRotation: 15.0,
//       maxFaceDistance: 200.0,
//       minFaceSize: 100.0,
//       maxFaceSize: 400.0,
//     );
//   }

//   Size _getPreviewSize(CameraController controller) {
//     final size = controller.value.previewSize;
//     return size ?? const Size(400, 600);
//   }
// }