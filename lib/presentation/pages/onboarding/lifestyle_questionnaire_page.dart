import 'package:flutter/material.dart';
import '../../../core/widgets/base_question_page.dart';
import '../../../core/widgets/option_selector.dart';
import 'skin_type_selection_page.dart';

class LifestyleQuestionnairePage extends StatefulWidget {
  const LifestyleQuestionnairePage({super.key});

  @override
  State<LifestyleQuestionnairePage> createState() => _LifestyleQuestionnairePageState();
}

class _LifestyleQuestionnairePageState extends State<LifestyleQuestionnairePage> {
  final QuestionnaireState _questionnaireState = QuestionnaireState();
  
  String? _selectedJobType;
  String? _selectedWorkEnvironment;
  String? _selectedStressLevel;
  String? _selectedActivityLevel;
  String? _selectedHydrationEntry;

  bool get _isFormValid {
    return _selectedJobType != null &&
           _selectedWorkEnvironment != null &&
           _selectedStressLevel != null &&
           _selectedActivityLevel != null &&
           _selectedHydrationEntry != null;
  }

  void _handleNext() {
    if (_isFormValid) {
      // Update the global state with lifestyle data
      final updatedData = _questionnaireState.data.copyWith(
        jobType: _selectedJobType,
        workEnvironment: _selectedWorkEnvironment,
        stressLevel: _selectedStressLevel,
        activityLevel: _selectedActivityLevel,
        hydrationLevel: _selectedHydrationEntry,
      );
      
      _questionnaireState.updateData(updatedData);
      
      // Navigate to skin type selection screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SkinTypeSelectionPage(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lifestyle data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _selectOption(String category, OptionItem option) {
    setState(() {
      switch (category) {
        case 'jobType':
          _selectedJobType = option.id;
          break;
        case 'workEnvironment':
          _selectedWorkEnvironment = option.id;
          break;
        case 'stressLevel':
          _selectedStressLevel = option.id;
          break;
        case 'activityLevel':
          _selectedActivityLevel = option.id;
          break;
        case 'hydrationEntry':
          _selectedHydrationEntry = option.id;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionPage(
      currentStep: 3,
      totalSteps: 6,
      title: 'Tell us about your lifestyle',
      subtitle: 'Your lifestyle helps us analyze your skin.',
      buttonText: 'Next',
      isFormValid: _isFormValid,
      onNext: _handleNext,
      content: Column(
        children: [
          // Job Type Section
          OptionSelector(
            title: 'Job Type',
            options: const [
              OptionItem(label: 'Office Job', id: 'office_job'),
              OptionItem(label: 'Field Job', id: 'field_job'),
              OptionItem(label: 'Student', id: 'student'),
              OptionItem(label: 'Homemaker', id: 'homemaker'),
              OptionItem(label: 'Night Shift', id: 'night_shift'),
            ],
            selectedValue: _selectedJobType,
            onOptionSelected: (option) => _selectOption('jobType', option),
          ),
          
          const SizedBox(height: 32),
          
          // Work Environment Section
          OptionSelector(
            title: 'Work Environment',
            options: const [
              OptionItem(label: 'Indoors', id: 'indoors'),
              OptionItem(label: 'Outdoors', id: 'outdoors'),
              OptionItem(label: 'Polluted Area', id: 'polluted_area'),
              OptionItem(label: 'Air-conditioned', id: 'air_conditioned'),
              OptionItem(label: 'Factory', id: 'factory'),
            ],
            selectedValue: _selectedWorkEnvironment,
            onOptionSelected: (option) => _selectOption('workEnvironment', option),
          ),
          
          const SizedBox(height: 32),
          
          // Stress Levels Section
          OptionSelector(
            title: 'Stress Levels',
            options: const [
              OptionItem(label: 'Low', id: 'low'),
              OptionItem(label: 'Moderate', id: 'moderate'),
              OptionItem(label: 'High', id: 'high'),
            ],
            selectedValue: _selectedStressLevel,
            onOptionSelected: (option) => _selectOption('stressLevel', option),
          ),
          
          const SizedBox(height: 32),
          
          // Physical Activity Level Section
          OptionSelector(
            title: 'Physical Activity Level',
            options: const [
              OptionItem(label: 'Sedentary', id: 'sedentary'),
              OptionItem(label: 'Lightly Active', id: 'lightly_active'),
              OptionItem(label: 'Very Active', id: 'very_active'),
            ],
            selectedValue: _selectedActivityLevel,
            onOptionSelected: (option) => _selectOption('activityLevel', option),
          ),
          
          const SizedBox(height: 32),
          
          // Hydration Entry Section
          OptionSelector(
            title: 'Hydration Entry',
            options: const [
              OptionItem(label: '1L - 2L', id: '1l_2l'),
              OptionItem(label: '2L - 4L', id: '2l_4l'),
              OptionItem(label: '4L - 6L', id: '4l_6l'),
            ],
            selectedValue: _selectedHydrationEntry,
            onOptionSelected: (option) => _selectOption('hydrationEntry', option),
          ),
        ],
      ),
    );
  }
}
