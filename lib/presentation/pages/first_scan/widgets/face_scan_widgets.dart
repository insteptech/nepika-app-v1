// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../bloc/face_scan/face_alignment_bloc.dart';
// import '../../../bloc/face_scan/face_alignment_state.dart';
// import '../../../bloc/face_scan/face_alignment_event.dart';

// /// Reusable widgets for face scanning feature
// class FaceScanWidgets {
//   FaceScanWidgets._();

//   /// Creates a face alignment overlay widget
//   static Widget alignmentOverlay({
//     required Size previewSize,
//     required BuildContext context,
//   }) {
//     return BlocBuilder<FaceAlignmentBloc, FaceAlignmentState>(
//       builder: (context, state) {
//         return CustomPaint(
//           size: previewSize,
//           painter: FaceAlignmentOverlayPainter(
//             alignmentState: state,
//             previewSize: previewSize,
//           ),
//         );
//       },
//     );
//   }

//   /// Creates the countdown timer widget
//   static Widget countdownTimer({
//     required int countdown,
//     required bool isVisible,
//   }) {
//     return AnimatedOpacity(
//       opacity: isVisible ? 1.0 : 0.0,
//       duration: const Duration(milliseconds: 300),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.7),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Text(
//           countdown.toString(),
//           style: const TextStyle(
//             fontSize: 48,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }

//   /// Creates the face detection status indicator
//   static Widget faceDetectionStatus({
//     required FaceAlignmentState alignmentState,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: _getStatusColor(alignmentState).withOpacity(0.9),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         _getStatusMessage(alignmentState),
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   /// Creates alignment guidance messages
//   static Widget alignmentGuidance({
//     required List<AlignmentIssue> issues,
//   }) {
//     if (issues.isEmpty) return const SizedBox.shrink();

//     final primaryIssue = issues.first;
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.orange.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.info_outline,
//             color: Colors.white,
//             size: 20,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               primaryIssue.guidanceMessage,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Creates the scan progress indicator
//   static Widget scanProgressIndicator({
//     required double progress,
//     required bool isScanning,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircularProgressIndicator(
//             value: isScanning ? progress : null,
//             strokeWidth: 4,
//             valueColor: AlwaysStoppedAnimation<Color>(
//               isScanning ? Colors.green : Colors.blue,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             isScanning ? 'Scanning...' : 'Preparing...',
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Creates capture button with animation
//   static Widget captureButton({
//     required VoidCallback onPressed,
//     required bool isEnabled,
//     required bool isCapturing,
//   }) {
//     return GestureDetector(
//       onTap: isEnabled ? onPressed : null,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 80,
//         height: 80,
//         decoration: BoxDecoration(
//           color: isCapturing ? Colors.red : Colors.white,
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: Colors.white,
//             width: 4,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Icon(
//           isCapturing ? Icons.stop : Icons.camera_alt,
//           color: isCapturing ? Colors.white : Colors.black87,
//           size: 32,
//         ),
//       ),
//     );
//   }

//   /// Helper method to get status color
//   static Color _getStatusColor(FaceAlignmentState state) {
//     if (state is FaceAlignmentInitial) return Colors.grey;
//     if (state is FaceAlignmentDetectionActive) return Colors.orange;
//     if (state is FaceAlignmentAligned) return Colors.green;
//     if (state is FaceAlignmentDetectedButNotAligned) return Colors.red;
//     if (state is FaceAlignmentNoFaceDetected) return Colors.red;
//     if (state is FaceAlignmentDetectionFailed) return Colors.red;
//     if (state is FaceAlignmentTimeout) return Colors.orange;
//     if (state is FaceAlignmentMultipleFacesDetected) return Colors.red;
//     return Colors.grey;
//   }

//   /// Helper method to get status message
//   static String _getStatusMessage(FaceAlignmentState state) {
//     if (state is FaceAlignmentInitial) {
//       return 'Position your face in the oval';
//     }
//     if (state is FaceAlignmentDetectionActive) {
//       return 'Detecting face...';
//     }
//     if (state is FaceAlignmentAligned) {
//       return 'Face aligned - Hold still';
//     }
//     if (state is FaceAlignmentDetectedButNotAligned) {
//       return state.primaryGuidanceMessage;
//     }
//     if (state is FaceAlignmentNoFaceDetected) {
//       return 'No face detected';
//     }
//     if (state is FaceAlignmentDetectionFailed) {
//       return 'Error: ${state.errorMessage}';
//     }
//     if (state is FaceAlignmentTimeout) {
//       return 'Detection timeout - Please try again';
//     }
//     if (state is FaceAlignmentMultipleFacesDetected) {
//       return 'Multiple faces detected - ensure only one person is visible';
//     }
//     return 'Unknown state';
//   }
// }

// /// Custom painter for face alignment overlay
// class FaceAlignmentOverlayPainter extends CustomPainter {
//   final FaceAlignmentState alignmentState;
//   final Size previewSize;

//   FaceAlignmentOverlayPainter({
//     required this.alignmentState,
//     required this.previewSize,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0;

//     // Draw face oval
//     final center = Offset(size.width / 2, size.height / 2);
//     final ovalRect = Rect.fromCenter(
//       center: center,
//       width: size.width * 0.7,
//       height: size.height * 0.5,
//     );

//     // Set color based on alignment state
//     paint.color = _getOverlayColor(alignmentState);

//     canvas.drawOval(ovalRect, paint);

//     // Draw face detection rectangle if available
//     _drawFaceBoxIfNeeded(canvas, size, alignmentState);
//   }

//   Color _getOverlayColor(FaceAlignmentState state) {
//     if (state is FaceAlignmentInitial) return Colors.white.withValues(alpha: 0.8);
//     if (state is FaceAlignmentDetectionActive) return Colors.orange;
//     if (state is FaceAlignmentAligned) return Colors.green;
//     if (state is FaceAlignmentDetectedButNotAligned) return Colors.red;
//     if (state is FaceAlignmentNoFaceDetected) return Colors.red;
//     if (state is FaceAlignmentDetectionFailed) return Colors.red;
//     if (state is FaceAlignmentTimeout) return Colors.orange;
//     if (state is FaceAlignmentMultipleFacesDetected) return Colors.red;
//     return Colors.white.withValues(alpha: 0.8);
//   }

//   void _drawFaceBoxIfNeeded(Canvas canvas, Size size, FaceAlignmentState state) {
//     if (state is FaceAlignmentAligned) {
//       _drawFaceBox(canvas, size, null, Colors.green);
//     } else if (state is FaceAlignmentDetectedButNotAligned) {
//       _drawFaceBox(canvas, size, null, Colors.red);
//     }
//   }

//   void _drawFaceBox(Canvas canvas, Size size, dynamic position, Color color) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;

//     // This would need to be implemented based on the actual FacePosition structure
//     // For now, just draw a placeholder rectangle
//     final rect = Rect.fromCenter(
//       center: Offset(size.width / 2, size.height / 2),
//       width: size.width * 0.6,
//       height: size.height * 0.4,
//     );
    
//     canvas.drawRect(rect, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// /// Loading overlay widget
// class LoadingOverlay extends StatelessWidget {
//   final String message;
//   final bool isVisible;

//   const LoadingOverlay({
//     super.key,
//     required this.message,
//     required this.isVisible,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (!isVisible) return const SizedBox.shrink();

//     return Container(
//       color: Colors.black.withValues(alpha: 0.7),
//       child: Center(
//         child: Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Error display widget
// class ErrorDisplay extends StatelessWidget {
//   final String error;
//   final VoidCallback? onRetry;

//   const ErrorDisplay({
//     super.key,
//     required this.error,
//     this.onRetry,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.error_outline,
//             size: 64,
//             color: Colors.red,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Error',
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             error,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 16),
//           ),
//           if (onRetry != null) ...[
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: onRetry,
//               child: const Text('Try Again'),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }