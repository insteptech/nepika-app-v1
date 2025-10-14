import 'package:flutter/material.dart';
import '../../../core/mixins/guided_tour_mixin.dart';
import '../../../core/widgets/guided_tour_overlay.dart';

/// Example implementation of a face scan result screen with guided tour
/// Replace this with your actual face scan result screen implementation
class FaceScanResultWithTourScreen extends StatefulWidget {
  const FaceScanResultWithTourScreen({super.key});

  @override
  State<FaceScanResultWithTourScreen> createState() => _FaceScanResultWithTourScreenState();
}

class _FaceScanResultWithTourScreenState extends State<FaceScanResultWithTourScreen> 
    with GuidedTourMixin {
  
  // Global keys for tour targets
  final GlobalKey _conditionFilterKey = GlobalKey();
  final GlobalKey _resultButtonKey = GlobalKey();
  final GlobalKey _skinScoreKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();

  // Dummy data - replace with your actual data
  final List<String> _detectedConditions = ['Dry Skin', 'Fine Lines', 'Dark Spots'];
  String? _selectedCondition = 'Dry Skin';
  final int _skinScore = 75;

  @override
  void initState() {
    super.initState();
    // Start the tour after the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFaceScanTour();
    });
  }

  /// Initialize and start the guided tour for face scan results
  Future<void> _startFaceScanTour() async {
    final tourSteps = [
      createTourStep(
        title: 'Skin Score Overview',
        description: 'This is your overall skin health score based on our AI analysis. Higher scores indicate healthier skin.',
        targetKey: _skinScoreKey,
        tooltipOffset: const EdgeInsets.only(top: 16),
      ),
      createTourStep(
        title: 'Condition Filters',
        description: 'Tap on different conditions to filter and view specific analysis results. Each condition shows detailed insights.',
        targetKey: _conditionFilterKey,
        tooltipOffset: const EdgeInsets.only(top: 16),
      ),
      createTourStep(
        title: 'Personalized Recommendations',
        description: 'Based on your skin analysis, we provide tailored skincare recommendations and product suggestions.',
        targetKey: _recommendationsKey,
        tooltipOffset: const EdgeInsets.only(bottom: 16),
      ),
      createTourStep(
        title: 'Detailed Results',
        description: 'Tap here to view your complete skin analysis report with detailed breakdowns and treatment suggestions.',
        targetKey: _resultButtonKey,
        tooltipOffset: const EdgeInsets.only(bottom: 16),
      ),
    ];

    await startTourIfNeeded(
      steps: tourSteps,
      hasSeenTour: TourPreferences.hasSeenFaceScanTour,
      markTourAsSeen: TourPreferences.markFaceScanTourAsSeen,
      onComplete: () {
        debugPrint('Face scan tour completed!');
        // You can add additional logic here, like analytics tracking
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scan Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skin Score Section
            _buildSkinScoreCard(),
            
            const SizedBox(height: 24),
            
            // Condition Filters Section
            _buildConditionFilters(),
            
            const SizedBox(height: 24),
            
            // Analysis Results Section
            _buildAnalysisResults(),
            
            const SizedBox(height: 24),
            
            // Recommendations Section
            _buildRecommendations(),
            
            const SizedBox(height: 32),
            
            // Result Button
            _buildResultButton(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinScoreCard() {
    return Container(
      key: _skinScoreKey,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Your Skin Score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_skinScore',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Good skin health',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Conditions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          key: _conditionFilterKey,
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _detectedConditions.map((condition) {
              final isSelected = condition == _selectedCondition;
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCondition = selected ? condition : null;
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis for ${_selectedCondition ?? 'All Conditions'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on your skin scan, we detected signs of ${_selectedCondition?.toLowerCase() ?? 'various conditions'}. Our AI analysis shows specific areas that need attention.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      key: _recommendationsKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem('Use a gentle moisturizer daily'),
          _buildRecommendationItem('Apply sunscreen with SPF 30+'),
          _buildRecommendationItem('Consider using a vitamin C serum'),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultButton() {
    return Container(
      key: _resultButtonKey,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to detailed results
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening detailed results...'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'View Detailed Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Debug helper class for tour testing
class FaceScanTourDebugHelper {
  static Future<void> resetTour(BuildContext context) async {
    await TourPreferences.resetFaceScanTour();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tour reset! Restart the screen to see the tour again.'),
        ),
      );
    }
  }
}