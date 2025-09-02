import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/face_scan/face_scan_bloc.dart';
import '../../bloc/face_scan/face_scan_event.dart';
import '../../bloc/face_scan/face_scan_state.dart';

/// Onboarding page that guides users through face scanning preparation
class FaceScanOnboardingPage extends StatefulWidget {
  const FaceScanOnboardingPage({super.key});

  @override
  State<FaceScanOnboardingPage> createState() => _FaceScanOnboardingPageState();
}

class _FaceScanOnboardingPageState extends State<FaceScanOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Get Ready for Your Face Scan',
      description: 'We\'ll analyze your skin to provide personalized recommendations',
      icon: Icons.face,
      tips: [
        'Find a well-lit area',
        'Remove glasses or accessories',
        'Keep your face clean and dry',
      ],
    ),
    OnboardingStep(
      title: 'Position Your Face',
      description: 'Align your face within the oval for the best results',
      icon: Icons.center_focus_strong,
      tips: [
        'Look directly at the camera',
        'Keep your head straight',
        'Stay within the oval guide',
      ],
    ),
    OnboardingStep(
      title: 'Hold Still',
      description: 'Once aligned, hold still while we capture and analyze',
      icon: Icons.timer,
      tips: [
        'Don\'t move during capture',
        'Maintain good lighting',
        'Keep a neutral expression',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Face Scan Setup',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: BlocListener<FaceScanBloc, FaceScanState>(
        listener: (context, state) {
          if (state is FaceScanErrorState) {
            _showErrorDialog(context, 'Face scan error occurred');
          } else if (state is FaceScanCameraReady) {
            // Navigate to face capture page
            Navigator.of(context).pushReplacementNamed('/face-capture');
          }
        },
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(
                  _steps.length,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < _steps.length - 1 ? 8 : 0,
                      ),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Onboarding content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingStep(_steps[index]);
                },
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _currentPage == _steps.length - 1
                        ? _startFaceScan
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1 
                          ? 'Start Scan' 
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  Widget _buildOnboardingStep(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Tips
          ...step.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startFaceScan() {
    // Initialize camera and start face scan
    context.read<FaceScanBloc>().add(
      const InitializeFaceScanSession(
        userId: 'current-user', // This should come from auth context
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Model class for onboarding steps
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final List<String> tips;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.tips,
  });
}