import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/widgets/custom_button.dart';
import 'scan_guidence_page.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleStartScan() async {
    if (_isRequestingPermission) return; // Prevent multiple requests
    
    setState(() {
      _isRequestingPermission = true;
    });

  _navigateToScanScreen();
   setState(() {
      _isRequestingPermission = false;
    });

    try {
      // Check current permission status
      var status = await Permission.camera.status;
      print('Initial camera permission status: $status');

      // If already granted, go to scan screen
      if (status.isGranted) {
        _navigateToScanScreen();
        return;
      }

      // Request permission - this will show the native dialog
      print('Requesting camera permission...');
      final requestResult = await Permission.camera.request();
      print('Permission request result: $requestResult');

      // Handle the result with explicit enum values
      if (requestResult == PermissionStatus.granted) {
        print('Permission granted, navigating to scan screen');
        _navigateToScanScreen();
      } else if (requestResult == PermissionStatus.denied) {
        print('Permission denied');
        _showPermissionDeniedMessage();
      } else if (requestResult == PermissionStatus.permanentlyDenied) {
        print('Permission permanently denied');
        _showSettingsDialog();
      } else if (requestResult == PermissionStatus.restricted) {
        print('Permission restricted');
        _showPermissionRestrictedMessage();
      } else if (requestResult == PermissionStatus.limited) {
        print('Permission limited (iOS 14+)');
        _navigateToScanScreen(); // Limited access might still work
      } else {
        print('Unexpected permission status: $requestResult');
        _showErrorMessage('Unexpected permission status.');
      }

    } catch (e) {
      print('Error handling camera permission: $e');
      _showErrorMessage('Error requesting camera permission: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  void _navigateToScanScreen() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScanGuidenceScreen()),
      );
    }
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
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Camera Permission Required',
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
                // Open app settings
                final opened = await openAppSettings();
                if (!opened) {
                  // Fallback if opening settings failed
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
void _handleSkipForNow() {
  print(AppRoutes.dashboardHome);
  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.dashboardHome,
    (route) => false, // Remove all previous routes
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: Column(
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
                              ?.copyWith(
                                fontSize: 28,
                              ),
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
                                : const Icon(Icons.arrow_forward,color: Colors.white,),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        GestureDetector(
                          onTap: _handleSkipForNow,
                          child: Text(
                            'Skip for now',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium!.secondary(context),

                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image preview takes full width without padding
                  Expanded(child: _buildAssetBasedScanPreview()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetBasedScanPreview() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.6,
      alignment: Alignment.bottomCenter,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Girl image (bottom layer on z-axis) - full width, no spacing
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/face_scan_girl_image.png',
              fit: BoxFit.fill,
              height: screenHeight * 0.58,
              // height: screenHeight * 0.6,
            ),
          ),

          // Mobile phone image (overlapping the girl image)
          Positioned(
            bottom: 10,
            child: Image.asset(
              'assets/images/mobile_phone_image.png',
              fit: BoxFit.contain,
              height: screenHeight * 0.55,
            ),
          ),

          // Sample scan result texts (static, showing what results will look like)
          // Skin age bubble
          Positioned(
            bottom: 430,
            left: 20,
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
                'Skin age: 35',
                style: Theme.of(context).textTheme.bodyMedium
              ),
            ),
          ),

          // Skin health bubble
          Positioned(
            bottom: 190,
            right: 10,
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
                'Skin health: 76%',
                style: Theme.of(context).textTheme.bodyMedium
              ),
            ),
          ),

          // Skin type bubble with subtitle
          Positioned(
            bottom: 120,
            left: 37,
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
                    'Dry skin',
                style: Theme.of(context).textTheme.bodyMedium
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skin type',
                style: Theme.of(context).textTheme.bodySmall!.secondary(context)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}