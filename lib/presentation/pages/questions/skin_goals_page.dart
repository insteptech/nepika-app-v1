import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/index.dart';
import '../../../core/widgets/selection_button.dart';
import '../first_scan/face_scan_page.dart';


class SkinGoalsPage extends StatefulWidget {
  const SkinGoalsPage({super.key});

  @override
  State<SkinGoalsPage> createState() => _SkinGoalsPageState();
}

class _SkinGoalsPageState extends State<SkinGoalsPage> {
  bool _isFormValid = false;
  final _formKey = GlobalKey<FormState>();

  // Selected goals - can select multiple
  final Set<String> _selectedGoals = {};

  @override
  void initState() {
    super.initState();
  }

  void _updateFormState() {
    // Check if "Recommend for Me" is selected
    final isRecommendForMeSelected = _selectedGoals.contains('recommend_for_me');
    
    if (isRecommendForMeSelected) {
      // If "Recommend for Me" is selected, form is valid
      setState(() {
        _isFormValid = true;
      });
      return;
    }
    
    // Check if at least one goal from each category is selected
    final hasAcneSelection = _selectedGoals.any((goal) => 
        ['reduce_acne', 'prevent_breakouts', 'fade_acne_scars', 'clear_blackheads'].contains(goal));
    
    final hasGlowSelection = _selectedGoals.any((goal) => 
        ['achieve_glowing_skin', 'brighten_dull_skin', 'boost_skin_radiance', 'even_out_skin_tone'].contains(goal));
    
    final hasHydrationSelection = _selectedGoals.any((goal) => 
        ['hydrate_dry_skin', 'smooth_rough_texture', 'minimize_pores', 'balance_oily_skin'].contains(goal));
    
    final newFormValid = hasAcneSelection && hasGlowSelection && hasHydrationSelection;
    
    setState(() {
      _isFormValid = newFormValid;
    });
  }

  void _toggleGoal(String goal) {
    setState(() {
      if (goal == 'recommend_for_me') {
        // If selecting "Recommend for Me", clear all other selections
        if (_selectedGoals.contains(goal)) {
          _selectedGoals.remove(goal);
        } else {
          _selectedGoals.clear();
          _selectedGoals.add(goal);
        }
      } else {
        // If selecting any other goal, remove "Recommend for Me" if it's selected
        if (_selectedGoals.contains('recommend_for_me')) {
          _selectedGoals.remove('recommend_for_me');
        }
        
        // Toggle the selected goal
        if (_selectedGoals.contains(goal)) {
          _selectedGoals.remove(goal);
        } else {
          _selectedGoals.add(goal);
        }
      }
    });
    _updateFormState();
  }

  void _handleNext() {
    if (_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skin goals saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500), // show snack for 0.5 seconds
        ),
      );

      // Navigate after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FaceScanPage()),
          );
        }
      });
    }
  }

  Widget _buildGoalButton(String text, String value) {
    final isSelected = _selectedGoals.contains(value);
    
    return Expanded(
      child: SelectionButton(
        text: text,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        isSelected: isSelected,
        onPressed: () => _toggleGoal(value),
      ),
    );
  }

  Widget _buildGoalSection(String title, List<Map<String, String>> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        // First row with 2 goals
    Wrap(
  spacing: 10,
  runSpacing: 12,
  children: goals.map((goal) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 2, 
      child: _buildGoalButton(goal['text']!, goal['value']!),
    );
  }).toList(),
),
      ],
    );
  }

  Widget _buildSingleGoalSection(String title, Map<String, String> goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SelectionButton(
            text: goal['text']!,
            isSelected: _selectedGoals.contains(goal['value']!),
            onPressed: () => _toggleGoal(goal['value']!),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionPage(
      currentStep: 6,
      totalSteps: 6,
      title: 'Set Your Skin Goals',
      subtitle: 'Glow-up time! Pick what you want to work on',
      buttonText: 'Next',
      isFormValid: _isFormValid,
      onNext: _handleNext,
      showBackButton: true,
      showSkipButton: false,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Acne & Blemishes Section
                _buildGoalSection('Acne & Blemishes', [
                  {'text': 'Reduce Acne', 'value': 'reduce_acne'},
                  {'text': 'Prevent Breakouts', 'value': 'prevent_breakouts'},
                  {'text': 'Fade Acne Scars', 'value': 'fade_acne_scars'},
                  {'text': 'Clear Blackheads', 'value': 'clear_blackheads'},
                ]),
                
                const SizedBox(height: 30),
                
                // Glow & Radiance Section
                _buildGoalSection('Glow & Radiance', [
                  {'text': 'Achieve Glowing Skin', 'value': 'achieve_glowing_skin'},
                  {'text': 'Brighten Dull Skin', 'value': 'brighten_dull_skin'},
                  {'text': 'Boost Skin Radiance', 'value': 'boost_skin_radiance'},
                  {'text': 'Even Out Skin Tone', 'value': 'even_out_skin_tone'},
                ]),
                
                const SizedBox(height: 30),
                
                // Hydration & Texture Section
                _buildGoalSection('Hydration & Texture', [
                  {'text': 'Hydrate Dry Skin', 'value': 'hydrate_dry_skin'},
                  {'text': 'Smooth Rough Texture', 'value': 'smooth_rough_texture'},
                  {'text': 'Minimize Pores', 'value': 'minimize_pores'},
                  {'text': 'Balance Oily Skin', 'value': 'balance_oily_skin'},
                ]),
                
                const SizedBox(height: 30),
                
                // Not Sure Yet Section
                _buildSingleGoalSection('Not Sure Yet', {
                  'text': 'Recommend for Me',
                  'value': 'recommend_for_me'
                }),
              ],
            ),
          ),
        );
  }
}
