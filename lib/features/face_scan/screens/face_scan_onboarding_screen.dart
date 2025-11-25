import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'face_scan_guidance_screen.dart';

/// Initial onboarding screen for face scan feature
class FaceScanOnboardingScreen extends StatefulWidget {
  const FaceScanOnboardingScreen({super.key});

  @override
  State<FaceScanOnboardingScreen> createState() => _FaceScanOnboardingScreenState();
}

class _FaceScanOnboardingScreenState extends State<FaceScanOnboardingScreen> {
  bool _isRequestingPermission = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Column(
                children: [
                  // Top section with padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          'Condition of your skin',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          'Take a quick scan of your skin to assess its health and needs.',
                          style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        // Start Scan button with loading state
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: _isRequestingPermission ? 'Requesting Permission...' : 'Start Scan',
                            onPressed: _isRequestingPermission ? null : _handleStartScan,
                            icon: _isRequestingPermission 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        GestureDetector(
                          onTap: _handleSkipForNow,
                          child: Text(
                            'Skip for now',
                            style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

_buildAssetBasedScanPreview()
                  // Image preview takes full width without padding
                  // Expanded(child: ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartScan() async {
    if (_isRequestingPermission) return;
    
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      // Check current permission status
      final status = await Permission.camera.status;
      debugPrint('Initial camera permission status: $status');

      // If already granted, go to scan screen
      if (status.isGranted) {
        _navigateToGuidanceScreen();
        return;
      }

      // Request permission
      debugPrint('Requesting camera permission...');
      final requestResult = await Permission.camera.request();
      debugPrint('Permission request result: $requestResult');

      // Handle the result
      if (requestResult == PermissionStatus.granted) {
        debugPrint('Permission granted, navigating to guidance screen');
        _navigateToGuidanceScreen();
      } else if (requestResult == PermissionStatus.denied) {
        debugPrint('Permission denied');
        _showPermissionDeniedMessage();
      } else if (requestResult == PermissionStatus.permanentlyDenied) {
        debugPrint('Permission permanently denied');
        _showSettingsDialog();
      } else if (requestResult == PermissionStatus.restricted) {
        debugPrint('Permission restricted');
        _showPermissionRestrictedMessage();
      } else if (requestResult == PermissionStatus.limited) {
        debugPrint('Permission limited (iOS 14+)');
        _navigateToGuidanceScreen(); // Limited access might still work
      } else {
        debugPrint('Unexpected permission status: $requestResult');
        _showErrorMessage('Unexpected permission status.');
      }

    } catch (e) {
      debugPrint('Error handling camera permission: $e');
      _showErrorMessage('Error requesting camera permission: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  void _navigateToGuidanceScreen() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FaceScanGuidanceScreen()),
      );
    }
  }

  void _handleSkipForNow() {
    debugPrint(AppRoutes.dashboardHome);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboardHome,
      (route) => false,
    );
  }

  void _showPermissionDeniedMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Camera permission is required for face scan. Please grant permission to continue.",
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Try Again',
            onPressed: _handleStartScan,
          ),
        ),
      );
    }
  }

  void _showPermissionRestrictedMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Camera access is restricted on this device. Please check your device restrictions.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showErrorMessage([String? message]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? "An error occurred while requesting camera permission."),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Camera Permission Required',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          content: Text(
            'Camera access is required for the face scan feature. Please enable camera permission in your device settings.',
            style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final opened = await openAppSettings();
                if (!opened) {
                  _showErrorMessage();
                }
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetBasedScanPreview() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.7,
      alignment: Alignment.bottomCenter,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Girl image (bottom layer)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/face_scan_girl_image.png',
              fit: BoxFit.fill,
              height: screenHeight * 0.58,
            ),
          ),

          // Mobile phone image
          Positioned(
            bottom: 10,
            child: Image.asset(
              'assets/images/mobile_phone_image.png',
              fit: BoxFit.contain,
              height: screenHeight * 0.55,
            ),
          ),

          // Sample results bubbles
          _buildResultBubble(
            bottom: 430,
            left: 20,
            text: 'Skin age: 35',
          ),
          _buildResultBubble(
            bottom: 190,
            right: 10,
            text: 'Skin health: 76%',
          ),
          _buildResultBubbleWithSubtitle(
            bottom: 120,
            left: 37,
            title: 'Dry skin',
            subtitle: 'Skin type',
          ),
        ],
      ),
    );
  }

  Widget _buildResultBubble({
    required double bottom,
    double? left,
    double? right,
    required String text,
  }) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onTertiary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildResultBubbleWithSubtitle({
    required double bottom,
    double? left,
    double? right,
    required String title,
    required String subtitle,
  }) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onTertiary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall!.secondary(context),
            ),
          ],
        ),
      ),
    );
  }
}