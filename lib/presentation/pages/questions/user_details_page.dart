import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/index.dart';
import '../../../core/widgets/selection_button.dart';
import 'lifestyle_questionnaire_page.dart';

enum Gender { male, female, other }

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _dobController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Gender? _selectedGender;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _dobController.addListener(_updateFormState);
    _feetController.addListener(_updateFormState);
    _inchesController.addListener(_updateFormState);
    _weightController.addListener(_updateFormState);
    _waistController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _dobController.removeListener(_updateFormState);
    _feetController.removeListener(_updateFormState);
    _inchesController.removeListener(_updateFormState);
    _weightController.removeListener(_updateFormState);
    _waistController.removeListener(_updateFormState);
    _dobController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    final newFormValid =
        _selectedGender != null &&
        _dobController.text.trim().isNotEmpty &&
        _feetController.text.trim().isNotEmpty &&
        _inchesController.text.trim().isNotEmpty &&
        _weightController.text.trim().isNotEmpty &&
        _waistController.text.trim().isNotEmpty;

    setState(() {
      _isFormValid = newFormValid;
    });
  }

  void _selectGender(Gender gender) {
    setState(() {
      _selectedGender = gender;
    });
    _updateFormState();
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      // Navigate to lifestyle questionnaire screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LifestyleQuestionnairePage(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
      _updateFormState();
    }
  }

  Widget _buildGenderButton(
    String text,
    Gender gender,
    IconData? icon,
    String? asset,
  ) {
    final isSelected = _selectedGender == gender;

    return Expanded(
      child: SelectionButton(
        text: text,
        prefixIcon: icon,
        isSelected: isSelected,
        prefixIconAsset: asset,
        onPressed: () => _selectGender(gender),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionPage(
      currentStep: 2,
      totalSteps: 6,
      title: 'Let\'s Get to Know You',
      subtitle: 'Just the basics — we promise it\'s quick',
      buttonText: 'Next',
      isFormValid: _isFormValid,
      onNext: _handleNext,
      showBackButton: false,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gender', style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildGenderButton(
                  'Male',
                  Gender.male,
                  null,
                  'assets/icons/male_gender_icon.png',
                ),
                const SizedBox(width: 12),
                _buildGenderButton(
                  'Female',
                  Gender.female,
                  null,
                  'assets/icons/female_gender_icon.png',
                ),
                const SizedBox(width: 12),
                _buildGenderButton(
                  'Other',
                  Gender.other,
                  null,
                  'assets/icons/other_gender_icon.png',
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Date of Birth
            Text(
              'Date of Birth',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 3),

            UnderlinedTextField(
              controller: _dobController,
              hint: '',
              readOnly: true,
              onTap: _selectDateOfBirth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your date of birth';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // Height
            Text(
              'Height (ft/inches)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 3),

            Row(
              children: [
                Expanded(
                  child: UnderlinedTextField(
                    controller: _feetController,
                    hint: 'Enter feet',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: UnderlinedTextField(
                    controller: _inchesController,
                    hint: 'Enter inches',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Weight
            Text('Weight', style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 3),

            UnderlinedTextField(
              controller: _weightController,
              hint: '',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // Waist
            Text(
              'Waist (inches)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 3),

            UnderlinedTextField(
              controller: _waistController,
              hint: '',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your waist measurement';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
