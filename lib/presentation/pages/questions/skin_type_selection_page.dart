import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/index.dart';
import 'menstrual_cycle_tracking_page.dart';

class SkinTypeSelectionPage extends StatefulWidget {
  const SkinTypeSelectionPage({super.key});

  @override
  State<SkinTypeSelectionPage> createState() => _SkinTypeSelectionPageState();
}

class _SkinTypeSelectionPageState extends State<SkinTypeSelectionPage> {
  final int _currentStep = 4;
  final int _totalSteps = 6;
  bool _isFormValid = false;

  String? _selectedSkinType;

  @override
  void initState() {
    super.initState();
  }

  void _updateFormState() {
    final newFormValid = _selectedSkinType != null;
    
    setState(() {
      _isFormValid = newFormValid;
    });
  }

  void _selectSkinType(String skinType) {
    setState(() {
      _selectedSkinType = skinType;
    });
    _updateFormState();
  }

  void _handleNext() {
    if (_isFormValid) {
      // Navigate to menstrual cycle tracking page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MenstrualCycleTrackingPage(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skin type selected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildSkinTypeCard(String title, String description, String value) {
    final isSelected = _selectedSkinType == value;
    
    // Define custom icons for each skin type based on the design
    IconData getIconForSkinType(String type) {
      switch (type) {
        case 'normal':
          return Icons.face_outlined;
        case 'dry':
          return Icons.spa_outlined;
        case 'oily':
          return Icons.water_drop_outlined;
        case 'sensitive':
          return Icons.healing_outlined;
        case 'combination':
          return Icons.palette_outlined;
        default:
          return Icons.face_outlined;
      }
    }
    
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _selectSkinType(value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon container with circular background like in the design
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.surface.withOpacity(0.2)
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.3)
                      : theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                getIconForSkinType(value),
                color: isSelected ? theme.colorScheme.surface : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.surface : theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected ? theme.colorScheme.surface.withOpacity(0.8) : theme.textTheme.bodyLarge!.secondary(context).color,
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionPage(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: 'What is your skin type?',
      subtitle: 'We\'ll recommend the ingredients your skin will love.',
      content: Column(
        children: [
          _buildSkinTypeCard(
            'Normal',
            'Has barely visible pores, looks hydrated',
            'normal',
          ),
          _buildSkinTypeCard(
            'Dry',
            'Feels tight, might be flaky',
            'dry',
          ),
          _buildSkinTypeCard(
            'Oily',
            'Has large pores and an overall shine',
            'oily',
          ),
          _buildSkinTypeCard(
            'Sensitive',
            'Has an oily T-zone and dry or normal cheeks',
            'sensitive',
          ),
          _buildSkinTypeCard(
            'Combination',
            'Has an oily T-zone and dry or normal cheeks',
            'combination',
          ),
        ],
      ),
      buttonText: 'Next',
      isFormValid: _isFormValid,
      onNext: _handleNext,
      showBackButton: true,
      showSkipButton: true,
    );
  }
}
