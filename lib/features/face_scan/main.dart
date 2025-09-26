/// Face Scan Feature - Main Entry Point
/// 
/// This file serves as the main entry point for the face scan feature.
/// It provides the complete feature with all its dependencies and screens.
/// 
/// Usage:
/// ```dart
/// // Use the main face scan screen (original scan_onboarding_page equivalent)
/// import 'package:nepika/features/face_scan/main.dart';
/// 
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => FaceScanMainScreen(),
/// ));
/// ```

export 'screens/face_scan_onboarding_screen.dart';
export 'screens/face_scan_guidance_screen.dart';
export 'screens/face_scan_main_screen.dart';
export 'screens/face_scan_result_screen.dart';

export 'widgets/face_alignment_overlay.dart';
export 'widgets/face_scan_camera_preview.dart';
export 'widgets/face_scan_controls.dart';
export 'widgets/face_scan_status_indicator.dart';

export 'components/face_scan_image_processor.dart';
export 'components/face_scan_api_handler.dart';
export 'components/camera_manager.dart';
export 'components/face_detector_service.dart';