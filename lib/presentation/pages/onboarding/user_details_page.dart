import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/index.dart';
import '../../../core/widgets/selection_button.dart';
import 'lifestyle_questionnaire_page.dart';

enum Gender { male, female, other }
enum Unit { cm, feet, kg, pounds, inches }

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _dobController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _cmHeightController = TextEditingController();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _waistCmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Gender? _selectedGender;
  Unit _heightUnit = Unit.feet;
  Unit _weightUnit = Unit.kg;
  Unit _waistUnit = Unit.inches;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _dobController.addListener(_updateFormState);
    _feetController.addListener(_updateFormState);
    _inchesController.addListener(_updateFormState);
    _cmHeightController.addListener(_updateFormState);
    _weightController.addListener(_updateFormState);
    _waistController.addListener(_updateFormState);
    _waistCmController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _dobController.removeListener(_updateFormState);
    _feetController.removeListener(_updateFormState);
    _inchesController.removeListener(_updateFormState);
    _cmHeightController.removeListener(_updateFormState);
    _weightController.removeListener(_updateFormState);
    _waistController.removeListener(_updateFormState);
    _waistCmController.removeListener(_updateFormState);
    _dobController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _cmHeightController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _waistCmController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    final hasDob = _dobController.text.trim().isNotEmpty;
    final hasHeight = _heightUnit == Unit.cm
        ? _cmHeightController.text.trim().isNotEmpty
        : _feetController.text.trim().isNotEmpty && _inchesController.text.trim().isNotEmpty;
    final hasWeight = _weightController.text.trim().isNotEmpty;
    final hasWaist = _waistUnit == Unit.cm
        ? _waistCmController.text.trim().isNotEmpty
        : _waistController.text.trim().isNotEmpty;

    final newFormValid =
        _selectedGender != null && hasDob && hasHeight && hasWeight && hasWaist;

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
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyMedium!.color!,
              surface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.onTertiary,
              headerBackgroundColor: Theme.of(context).colorScheme.primary,
              headerForegroundColor: Colors.white,
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

  Widget _buildGenderButton(String text, Gender gender, IconData? icon, String? asset) {
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

  Widget _buildUnitDropdown<T>(
    T value,
    List<T> options,
    String Function(T) label,
    void Function(T?) onChanged,
  ) {
    return DropdownButton<T>(
      borderRadius: BorderRadius.circular(10),
        value: value,
        items: options
            .map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(label(opt)),
                ))
            .toList(),
        style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
        onChanged: onChanged,
        underline: Container(),
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
            // Gender Selection
            Text('Gender', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderButton('Male', Gender.male, null, 'assets/icons/male_gender_icon.png'),
                const SizedBox(width: 12),
                _buildGenderButton('Female', Gender.female, null, 'assets/icons/female_gender_icon.png'),
                const SizedBox(width: 12),
                _buildGenderButton('Other', Gender.other, null, 'assets/icons/other_gender_icon.png'),
              ],
            ),
            const SizedBox(height: 30),

            // Date of Birth
            Text('Date of Birth', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 3),
            UnderlinedTextField(
              controller: _dobController,
              hint: 'Select date',
              readOnly: true,
              onTap: _selectDateOfBirth,
              validator: (value) => value == null || value.isEmpty ? 'Please select your date of birth' : null,
            ),
            const SizedBox(height: 30),

            // Height with Unit Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Height', style: Theme.of(context).textTheme.headlineMedium),
                _buildUnitDropdown<Unit>(
                  _heightUnit,
                  [Unit.cm, Unit.feet],
                  (u) => u == Unit.cm ? 'cm' : 'ft/in',
                  (val) {
                    setState(() => _heightUnit = val!);
                    _updateFormState();
                  },
                ),
              ],
            ),
            const SizedBox(height: 3),
            if (_heightUnit == Unit.cm)
              UnderlinedTextField(
                controller: _cmHeightController,
                hint: 'Enter height in cm',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: UnderlinedTextField(
                      controller: _feetController,
                      hint: 'Feet',
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Req' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: UnderlinedTextField(
                      controller: _inchesController,
                      hint: 'Inches',
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Req' : null,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),

            // Weight with Unit Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weight', style: Theme.of(context).textTheme.headlineMedium),
                _buildUnitDropdown<Unit>(
                  _weightUnit,
                  [Unit.kg, Unit.pounds],
                  (u) => u == Unit.kg ? 'kg' : 'lbs',
                  (val) {
                    setState(() => _weightUnit = val!);
                    _updateFormState();
                  },
                ),
              ],
            ),
            const SizedBox(height: 3),
            UnderlinedTextField(
              controller: _weightController,
              hint: _weightUnit == Unit.kg ? 'Enter weight in kg' : 'Enter weight in lbs',
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty ? 'Please enter your weight' : null,
            ),
            const SizedBox(height: 30),

            // Waist with Unit Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Waist', style: Theme.of(context).textTheme.headlineMedium),
                _buildUnitDropdown<Unit>(
                  _waistUnit,
                  [Unit.cm, Unit.inches],
                  (u) => u == Unit.cm ? 'cm' : 'in',
                  (val) {
                    setState(() => _waistUnit = val!);
                    _updateFormState();
                  },
                ),
              ],
            ),
            const SizedBox(height: 3),
            if (_waistUnit == Unit.cm)
              UnderlinedTextField(
                controller: _waistCmController,
                hint: 'Enter waist in cm',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your waist measurement' : null,
              )
            else
              UnderlinedTextField(
                controller: _waistController,
                hint: 'Enter waist in inches',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your waist measurement' : null,
              ),
          ],
        ),
      ),
    );
  }
}
