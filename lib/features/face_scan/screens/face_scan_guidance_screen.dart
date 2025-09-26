import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/camera_manager.dart';
import 'face_scan_result_screen.dart';

/// Guidance screen that walks users through face scan preparation steps
class FaceScanGuidanceScreen extends StatefulWidget {
  const FaceScanGuidanceScreen({super.key});

  @override
  State<FaceScanGuidanceScreen> createState() => _FaceScanGuidanceScreenState();
}

class _FaceScanGuidanceScreenState extends State<FaceScanGuidanceScreen>
    with WidgetsBindingObserver {
  final CameraManager _cameraManager = CameraManager();
  int _currentStep = 1;
  final int _totalSteps = 3;
  late PageController _pageController;
  bool _hasShownPermissionDialog = false;
  bool _isRequestingPermission = false;
  int _totalRetryAttempts = 0;
  DateTime? _lastPermissionRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentStep - 1);
    // Start camera initialization immediately when guidance screen loads
    _initializeCameraEarly();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    // Don't dispose camera here - pass it to next screen
    super.dispose();
  }

  void _resetPermissionTracking() {
    debugPrint('🔄 Resetting permission tracking');
    _hasShownPermissionDialog = false;
    _isRequestingPermission = false;
    _totalRetryAttempts = 0;
    _lastPermissionRequest = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes from settings, retry camera initialization
      if (_cameraManager.errorMessage != null &&
          !_cameraManager.isInitialized) {
        debugPrint('📱 App resumed, retrying camera initialization...');
        _resetPermissionTracking(); // Reset all tracking on resume

        // Add delay to ensure the app is fully resumed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _initializeCameraEarly();
          }
        });
      }
    }
  }

  Future<void> _initializeCameraEarly() async {
    try {
      debugPrint('🔍 Starting camera initialization...');

      // Pre-check: Verify permission status before attempting camera access
      final permissionStatus = await Permission.camera.status;
      debugPrint('📋 Pre-init permission status: $permissionStatus');

      if (permissionStatus.isPermanentlyDenied) {
        debugPrint('❌ Permission permanently denied during init, aborting');
        throw Exception('Camera permission permanently denied');
      }

      if (permissionStatus.isDenied) {
        debugPrint('🚫 Permission denied during init, aborting');
        throw Exception('Camera permission denied');
      }

      // Get available cameras with retry logic
      final cameras = await availableCameras();
      debugPrint('📸 Available cameras: ${cameras.length}');

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Find front camera or use first available
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      debugPrint('🎯 Selected camera: ${frontCamera.name}');

      // Create and initialize controller
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      debugPrint('⚡ Initializing camera controller...');
      await controller.initialize();

      // Initialize camera manager with pre-initialized controller
      debugPrint('🔧 Setting up camera manager...');
      await _cameraManager.initializeCamera(
        preInitializedController: controller,
        availableCameras: cameras,
      );

      if (_cameraManager.isInitialized) {
        debugPrint('✅ Camera initialization completed successfully');
      } else {
        debugPrint('⚠️ Camera manager reports not initialized despite success');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');

      // Additional permission check on error
      if (e.toString().toLowerCase().contains('permission')) {
        final status = await Permission.camera.status;
        debugPrint('📋 Permission status after error: $status');

        if (status.isPermanentlyDenied && _totalRetryAttempts == 0) {
          // First time encountering permanently denied, trigger settings dialog
          debugPrint(
            '🚨 Detected permanently denied permission, will show settings on retry',
          );
        }
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handleNext() {
    // Check camera initialization before allowing ANY navigation
    if (!_cameraManager.isInitialized) {
      // If camera has error or not initializing, retry
      if (_cameraManager.errorMessage != null &&
          !_cameraManager.isInitializing) {
        _retryCameraInit();
        return;
      }

      // If still initializing, don't allow navigation
      if (_cameraManager.isInitializing) {
        return;
      }

      // If no error but not initialized, start initialization
      _retryCameraInit();
      return;
    }

    // Camera is initialized, allow normal navigation
    if (_currentStep < _totalSteps) {
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to scan screen (camera is guaranteed to be ready)
      _navigateToFaceScan();
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
      _cameraManager.dispose();
      debugPrint('Guidance page: Camera disposed, navigating back');
      Navigator.of(context).pop();
    }
  }

  Future<void> _retryCameraInit() async {
    if (_isRequestingPermission) {
      debugPrint('Permission request already in progress, skipping...');
      return;
    }

    _isRequestingPermission = true;
    _totalRetryAttempts++;

    try {
      debugPrint('🔄 Retry attempt #$_totalRetryAttempts');

      // Step 1: Check current permission status
      final initialStatus = await Permission.camera.status;
      debugPrint('📋 Initial permission status: $initialStatus');

      if (initialStatus.isPermanentlyDenied) {
        debugPrint('❌ Permission is permanently denied, going to settings');
        _showSettingsDialog();
        return;
      }

      // Step 2: If denied, try to request permission with timeout detection
      if (initialStatus.isDenied) {
        debugPrint('🔐 Permission denied, requesting...');
        _lastPermissionRequest = DateTime.now();

        // Request with timeout to detect if dialog doesn't appear
        final requestFuture = Permission.camera.request();
        final timeoutFuture = Future.delayed(const Duration(seconds: 1));

        final result = await Future.any([requestFuture, timeoutFuture]);
        final requestDuration = DateTime.now().difference(
          _lastPermissionRequest!,
        );

        debugPrint(
          '⏱️ Permission request took: ${requestDuration.inMilliseconds}ms',
        );

        if (result is PermissionStatus) {
          debugPrint('✅ Got permission result: $result');

          if (result.isPermanentlyDenied) {
            debugPrint('❌ Result: permanently denied, going to settings');
            _showSettingsDialog();
            return;
          }

          if (result.isDenied) {
            // Check if this was too fast (indicating dialog didn't show)
            if (requestDuration.inMilliseconds < 500) {
              debugPrint(
                '⚡ Request was too fast (${requestDuration.inMilliseconds}ms), dialog likely didn\'t show',
              );
              _showSettingsDialog();
              return;
            }

            // Check if we've tried multiple times
            if (_hasShownPermissionDialog && _totalRetryAttempts >= 2) {
              debugPrint('🚫 Multiple denials detected, going to settings');
              _showSettingsDialog();
              return;
            }

            _hasShownPermissionDialog = true;
          }
        } else {
          // Timeout occurred - dialog likely didn't appear
          debugPrint(
            '⏰ Permission request timed out, dialog likely didn\'t appear',
          );

          // Wait for actual result
          try {
            final actualResult = await requestFuture.timeout(
              const Duration(seconds: 5),
            );
            debugPrint('📝 Delayed permission result: $actualResult');

            if (actualResult.isDenied && !actualResult.isPermanentlyDenied) {
              _hasShownPermissionDialog = true;
            } else if (actualResult.isPermanentlyDenied) {
              _showSettingsDialog();
              return;
            }
          } catch (timeoutError) {
            debugPrint(
              '❌ Permission request completely timed out, going to settings',
            );
            _showSettingsDialog();
            return;
          }
        }
      }

      // Step 3: Check final status before attempting camera init
      final finalStatus = await Permission.camera.status;
      debugPrint('🎯 Final permission status before camera init: $finalStatus');

      if (finalStatus.isPermanentlyDenied) {
        debugPrint('❌ Final status: permanently denied, going to settings');
        _showSettingsDialog();
        return;
      }

      if (finalStatus.isDenied && _totalRetryAttempts >= 3) {
        debugPrint(
          '🛑 Still denied after $_totalRetryAttempts attempts, going to settings',
        );
        _showSettingsDialog();
        return;
      }

      // Step 4: Attempt camera initialization
      debugPrint('📷 Attempting camera initialization...');
      await _initializeCameraEarly();

      // Step 5: Verify success and fallback if needed
      if (!_cameraManager.isInitialized &&
          _cameraManager.errorMessage != null) {
        debugPrint('⚠️ Camera init failed: ${_cameraManager.errorMessage}');

        if (_cameraManager.errorMessage!.toLowerCase().contains('permission') &&
            _totalRetryAttempts >= 2) {
          debugPrint('🚨 Permission error persists, going to settings');
          _showSettingsDialog();
          return;
        }
      } else if (_cameraManager.isInitialized) {
        debugPrint('🎉 Camera initialization successful!');
        // Reset on success
        _totalRetryAttempts = 0;
        _hasShownPermissionDialog = false;
      }
    } catch (e) {
      debugPrint('❌ Retry camera initialization failed with exception: $e');

      // Fallback: if we have errors and have tried multiple times, go to settings
      if (_totalRetryAttempts >= 2 ||
          e.toString().toLowerCase().contains('permission')) {
        debugPrint(
          '🚨 Exception indicates permission issues, going to settings',
        );
        _showSettingsDialog();
      }
    } finally {
      _isRequestingPermission = false;
    }
  }

  void _showSettingsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'Camera access is required for face scanning. You\'ve denied permission multiple times. '
            'Please grant camera permission in Settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // Reset all tracking when user goes to settings
                _resetPermissionTracking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToFaceScan() {
    if (_cameraManager.isInitialized && _cameraManager.controller != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FaceScanResultScreen(
            cameraController: _cameraManager.controller,
            availableCameras: _cameraManager.cameras,
          ),
        ),
      );
    } else {
      // Fallback: go without pre-initialized camera
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const FaceScanResultScreen()),
      );
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
    // If camera is not initialized, always show 'Retry' regardless of step
    if (!_cameraManager.isInitialized) {
      return 'Retry';
    }

    // If camera is initializing, show loading state
    if (_cameraManager.isInitializing) {
      return 'Initializing...';
    }

    // Normal button text when camera is ready
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
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, dynamic result) async {
      if (!didPop) {
        debugPrint('Guidance page: Back gesture detected, disposing camera...');
        await _cameraManager.dispose();
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

              // 👇 Put PageView and status indicator in one Stack
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
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
                                return SizedBox(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(fontSize: 28),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                          ],
                        );
                      },
                    ),

                    // 👇 Status indicator fixed on top-right, not per page
                    if (_cameraManager.errorMessage != null ||
                        _cameraManager.isInitializing ||
                        !_cameraManager.isInitialized)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildCameraStatusIndicatorBadge(),
                      ),
                  ],
                ),
              ),

              // Progress bar
              _buildProgressBar(),
              const SizedBox(height: 60),

              // Next/Start button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _buttonText,
                  onPressed: _cameraManager.isInitializing ? null : _handleNext,
                  icon: _cameraManager.isInitializing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white),
                  iconOnLeft: false,
                ),
              ),

              const SizedBox(height: 20),

              // Security info
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
    // Show error state on any step if camera failed and not initializing
    if (_cameraManager.errorMessage != null && !_cameraManager.isInitializing) {
      return Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Camera Access Required',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cameraManager.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryCameraInit,
              icon: const Icon(Icons.refresh),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Always show reference image when camera is OK or initializing
    return Image.asset(
      _referenceImagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildCameraStatusIndicatorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cameraManager.isInitialized
            ? Colors.green.withValues(alpha: 0.9)
            : _cameraManager.errorMessage != null
            ? Colors.red.withValues(alpha: 0.9)
            : Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_cameraManager.isInitializing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              _cameraManager.isInitialized
                  ? Icons.check_circle
                  : _cameraManager.errorMessage != null
                  ? Icons.error
                  : Icons.camera_alt,
              size: 14,
              color: Colors.white,
            ),
          const SizedBox(width: 4),
          Text(
            _cameraManager.isInitialized
                ? 'Ready'
                : _cameraManager.errorMessage != null
                ? 'Error'
                : 'Loading...',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (_cameraManager.errorMessage != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _retryCameraInit,
              child: const Icon(Icons.refresh, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 70),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
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
    );
  }
}
