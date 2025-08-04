import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/index.dart';
import '../../../core/widgets/selection_button.dart';
import 'skin_goals_page.dart';

class MenstrualCycleTrackingPage extends StatefulWidget {
  const MenstrualCycleTrackingPage({super.key});

  @override
  State<MenstrualCycleTrackingPage> createState() =>
      _MenstrualCycleTrackingPageState();
}

class _MenstrualCycleTrackingPageState
    extends State<MenstrualCycleTrackingPage> {
  final int _currentStep = 5;
  final int _totalSteps = 6;
  bool _isFormValid = false;

  // Sub-step tracking (0: menstruate question, 1: cycle details, 2: cycle data, 3: menopause)
  int _currentSubStep = 0;

  // Form controllers
  final _startDateController = TextEditingController();
  final _cycleLengthController = TextEditingController();
  final _currentDayController = TextEditingController();
  final _lastPeriodController = TextEditingController();

  // Form data
  bool? _doesMenstruate;
  String? _currentPhase;
  String? _cycleRegularity;
  final Set<String> _pmsSymptoms = {};
  String? _menopauseStatus;
  final Set<String> _menopauseSymptoms = {};
  bool? _usesHRT;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _cycleLengthController.dispose();
    _currentDayController.dispose();
    _lastPeriodController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    bool newFormValid = false;

    switch (_currentSubStep) {
      case 0: // Menstruation question
        newFormValid = _doesMenstruate != null;
        break;
      case 1: // Current phase, regularity, PMS symptoms
        if (_doesMenstruate == true) {
          newFormValid =
              _currentPhase != null &&
              _cycleRegularity != null &&
              _pmsSymptoms.isNotEmpty;
        }
        break;
      case 2: // Cycle data (dates, length)
        newFormValid =
            _startDateController.text.isNotEmpty &&
            _cycleLengthController.text.isNotEmpty &&
            _currentDayController.text.isNotEmpty;
        break;
      case 3: // Menopause screen
        newFormValid = _menopauseStatus != null && _usesHRT != null;
        break;
    }

    setState(() {
      _isFormValid = newFormValid;
    });
  }

  void _handleNext() {
    if (!_isFormValid) return;

    if (_currentSubStep == 0) {
      // After menstruation question
      if (_doesMenstruate == false) {
        // Skip to menopause screen
        setState(() {
          _currentSubStep = 3;
        });
      } else {
        // Go to cycle details
        setState(() {
          _currentSubStep = 1;
        });
      }
    } else if (_currentSubStep == 1) {
      // Go to cycle data entry
      setState(() {
        _currentSubStep = 2;
      });
    } else if (_currentSubStep == 2) {
      // From cycle data, go to menopause screen
      setState(() {
        _currentSubStep = 3;
      });
    } else if (_currentSubStep == 3) {
      // Complete flow and navigate to skin goals
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SkinGoalsPage()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menstrual cycle data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _updateFormState();
  }

  void _handleBack() {
    if (_currentSubStep > 0) {
      if (_currentSubStep == 3 && _doesMenstruate == false) {
        // If in menopause and came from "No" answer, go back to step 0
        setState(() {
          _currentSubStep = 0;
        });
      } else {
        setState(() {
          _currentSubStep--;
        });
      }
      _updateFormState();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getStepTitle() {
    switch (_currentSubStep) {
      case 0:
        return 'Your Natural Rhythm Matters';
      case 1:
        return 'Your Natural Rhythm Matters';
      case 2:
        return 'Enter Cycle Info';
      case 3:
        return 'Menopause';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentSubStep) {
      case 0:
      case 1:
        return 'Periods change skin. Let\'s track it';
      case 2:
        return 'Provide details about your menstrual cycle';
      case 3:
        return 'Menopause status';
      default:
        return '';
    }
  }

  String _getButtonText() {
    switch (_currentSubStep) {
      case 0:
        // Dynamic text based on selection
        if (_doesMenstruate == true) {
          return 'Continue';
        } else {
          return 'Next';
        }
      case 1:
        return 'Continue';
      case 2:
        return 'Continue';
      case 3:
        return 'Next';
      default:
        return 'Next';
    }
  }

  void _toggleMenstruation(bool value) {
    setState(() {
      _doesMenstruate = value;
      // Clear other selections when changing menstruation status
      if (!value) {
        _currentPhase = null;
        _cycleRegularity = null;
        _pmsSymptoms.clear();
      }
    });
    _updateFormState();
  }

  void _selectCurrentPhase(String phase) {
    setState(() {
      _currentPhase = phase;
    });
    _updateFormState();
  }

  void _selectCycleRegularity(String regularity) {
    setState(() {
      _cycleRegularity = regularity;
    });
    _updateFormState();
  }

  void _togglePMSSymptom(String symptom) {
    setState(() {
      if (symptom == 'none') {
        // If "None" is selected, clear all other symptoms
        if (_pmsSymptoms.contains('none')) {
          _pmsSymptoms.remove('none');
        } else {
          _pmsSymptoms.clear();
          _pmsSymptoms.add('none');
        }
      } else {
        // If any other symptom is selected, remove "None"
        if (_pmsSymptoms.contains('none')) {
          _pmsSymptoms.remove('none');
        }

        if (_pmsSymptoms.contains(symptom)) {
          _pmsSymptoms.remove(symptom);
        } else {
          _pmsSymptoms.add(symptom);
        }
      }
    });
    _updateFormState();
  }

  void _selectMenopauseStatus(String? status) {
    setState(() {
      _menopauseStatus = status;
    });
    _updateFormState();
  }

  void _toggleMenopauseSymptom(String symptom) {
    setState(() {
      if (_menopauseSymptoms.contains(symptom)) {
        _menopauseSymptoms.remove(symptom);
      } else {
        _menopauseSymptoms.add(symptom);
      }
    });
    _updateFormState();
  }

  void _toggleHRT(bool value) {
    setState(() {
      _usesHRT = value;
    });
    _updateFormState();
  }

  Future<void> _selectDate(
    TextEditingController controller,
    String title,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyMedium!.color!,
              surface: Colors.white,
              onSurfaceVariant: Theme.of(
                context,
              ).textTheme.bodyMedium!.secondary(context).color,
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

    // Handle the selected date after the picker closes
    if (picked != null) {
      setState(() {
        controller.text = '${picked.day}/${picked.month}/${picked.year}';
      });
      _updateFormState();
    }
  }

  Widget _buildYesNoButtons() {
    return Row(
      children: [
        Expanded(
          child: SelectionButton(
            text: 'Yes',
            isSelected: _doesMenstruate == true,
            onPressed: () => _toggleMenstruation(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectionButton(
            text: 'No',
            isSelected: _doesMenstruate == false,
            onPressed: () => _toggleMenstruation(false),
          ),
        ),
      ],
    );
  }

  // Sub-step 0: Menstruation Question
  Widget _buildMenstruationQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you menstruate?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        _buildYesNoButtons(),
      ],
    );
  }

  // Sub-step 1: Current Phase, Regularity, PMS Symptoms
  Widget _buildCycleDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Phase Section
        Text(
          'Current Phase',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 60) / 3,
                child: SelectionButton(
                  text: 'Menstrual',
                  isSelected: _currentPhase == 'menstrual',
                  onPressed: () => _selectCurrentPhase('menstrual'),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 60) / 3,
                child: SelectionButton(
                  text: 'Follicular',
                  isSelected: _currentPhase == 'follicular',
                  onPressed: () => _selectCurrentPhase('follicular'),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 60) / 3,
                child: SelectionButton(
                  text: 'Ovulation',
                  isSelected: _currentPhase == 'ovulation',
                  onPressed: () => _selectCurrentPhase('ovulation'),
                ),
              ),
              SizedBox(
                child: SelectionButton(
                  text: 'Luteal',
                  isSelected: _currentPhase == 'luteal',
                  onPressed: () => _selectCurrentPhase('luteal'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Cycle Regularity Section
        Text(
          'Cycle Regularity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Regular',
                isSelected: _cycleRegularity == 'regular',
                onPressed: () => _selectCycleRegularity('regular'),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Irregular',
                isSelected: _cycleRegularity == 'irregular',
                onPressed: () => _selectCycleRegularity('irregular'),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Not Sure',
                isSelected: _cycleRegularity == 'not_sure',
                onPressed: () => _selectCycleRegularity('not_sure'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // PMS Symptoms Section
        Text('PMS Symptoms', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 3.4,
              child: SelectionButton(
                text: 'Acne',
                isSelected: _pmsSymptoms.contains('acne'),
                onPressed: () => _togglePMSSymptom('acne'),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Bloating',
                isSelected: _pmsSymptoms.contains('bloating'),
                onPressed: () => _togglePMSSymptom('bloating'),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 2.7,
              child: SelectionButton(
                text: 'Mood Swings',
                isSelected: _pmsSymptoms.contains('mood_swings'),
                onPressed: () => _togglePMSSymptom('mood_swings'),
              ),
            ),
            SizedBox(
              // width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Oily Skin',
                isSelected: _pmsSymptoms.contains('oily_skin'),
                onPressed: () => _togglePMSSymptom('oily_skin'),
              ),
            ),
            SizedBox(
              // width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Dry Skin',
                isSelected: _pmsSymptoms.contains('dry_skin'),
                onPressed: () => _togglePMSSymptom('dry_skin'),
              ),
            ),
            SizedBox(
              // width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Headaches',
                isSelected: _pmsSymptoms.contains('headaches'),
                onPressed: () => _togglePMSSymptom('headaches'),
              ),
            ),
            SizedBox(
              // width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'Cramps',
                isSelected: _pmsSymptoms.contains('cramps'),
                onPressed: () => _togglePMSSymptom('cramps'),
              ),
            ),
            SizedBox(
              // width: (MediaQuery.of(context).size.width - 60) / 3,
              child: SelectionButton(
                text: 'None',
                isSelected: _pmsSymptoms.contains('none'),
                onPressed: () => _togglePMSSymptom('none'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Sub-step 2: Cycle Data Entry
  Widget _buildCycleDataForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Date
        Text('Start Date', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 3),
        GestureDetector(
          onTap: () => _selectDate(_startDateController, 'Start Date'),
          child: UnderlinedTextField(
            controller: _startDateController,
            hint: 'Enter date',
            readOnly: true,
            onTap: () => _selectDate(_startDateController, 'Start Date'),
            suffixIcon: Align(
              widthFactor: 10,
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 16,
                width: 16,
                child: Image.asset(
                  'assets/icons/input_calender_icon.png',
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your start date';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 32),

        // Cycle Length
        Text(
          'Cycle Length (days)',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 3),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: UnderlinedTextField(
            controller: _cycleLengthController,
            keyboardType: TextInputType.number,
            hint: 'Enter value',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 32),

        // Current Day in Cycle
        Text(
          'Current Day in Cycle',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 3),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: UnderlinedTextField(
            controller: _currentDayController,
            keyboardType: TextInputType.number,
            hint: 'Enter value',
          ),
        ),
      ],
    );
  }

  // Sub-step 3: Menopause Information
  Widget _buildMenopauseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menopause Status
        Text(
          'Menopause status',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 3),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: DropdownButtonFormField<String>(
            value: _menopauseStatus,
            decoration: InputDecoration(
              hintText: 'Enter Value',
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyLarge!.secondary(context),

              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x663898ED), width: 1),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyLarge!.secondary(context).color ??
                      Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 0,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            items: ['Pre-menopause', 'Peri-menopause', 'Post-menopause']
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: _selectMenopauseStatus,
          ),
        ),

        const SizedBox(height: 30),

        // Last Period Date
        Text(
          'Last Period date',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 3),
        // GestureDetector(
        //   onTap: () => _selectDate(_lastPeriodController, 'Last Period Date'),
        //   child: Container(
        //     width: double.infinity,
        //     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        //     decoration: BoxDecoration(
        //       color: Theme.of(context).scaffoldBackgroundColor,
        //       border: Border(
        //         bottom: BorderSide(
        //           color: Theme.of(context).dividerColor,
        //           width: 1,
        //         ),
        //       ),
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Text(
        //           _lastPeriodController.text.isEmpty
        //               ? 'Enter date'
        //               : _lastPeriodController.text,
        //           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        //             color: _lastPeriodController.text.isEmpty
        //                 ? Theme.of(context).textTheme.bodySmall?.color
        //                 : Theme.of(context).textTheme.bodyLarge?.color,
        //             fontWeight: FontWeight.w400,
        //           ),
        //         ),
        //         Icon(
        //           Icons.calendar_today,
        //           color: Theme.of(context).textTheme.bodySmall?.color,
        //           size: 20,
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        UnderlinedTextField(
          controller: _lastPeriodController,
          hint: 'Enter date',

          readOnly: true,
          onTap: () => _selectDate(_lastPeriodController, 'Date of Birth'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your date of birth';
            }
            return null;
          },
        ),

        const SizedBox(height: 30),

        // Common Symptoms
        Text(
          'Common Symptoms',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        _buildMenopauseSymptoms(),

        const SizedBox(height: 32),

        // HRT Question
        Text(
          'Are you using HRT supplements?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SelectionButton(
                text: 'Yes',
                isSelected: _usesHRT == true,
                onPressed: () => _toggleHRT(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectionButton(
                text: 'No',
                isSelected: _usesHRT == false,
                onPressed: () => _toggleHRT(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenopauseSymptoms() {
  final symptoms = ['Hot flushes', 'Mood swings', 'Dry Skin'];

  return Wrap(
    spacing: 10,
    runSpacing: 12,
    children: symptoms.map((symptom) {
      final isSelected = _menopauseSymptoms.contains(symptom);
      return Padding(  // ✅ Return Padding directly
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min, // ✅ Add this to prevent Row from taking full width
          children: [
            GestureDetector(
              onTap: () => _toggleMenopauseSymptom(symptom),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4.5),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSecondary,
                        weight: 990.0,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              symptom,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

  Widget _getCurrentStepContent() {
    switch (_currentSubStep) {
      case 0:
        return _buildMenstruationQuestion();
      case 1:
        return _buildCycleDetailsForm();
      case 2:
        return _buildCycleDataForm();
      case 3:
        return _buildMenopauseForm();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionPage(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      buttonText: _getButtonText(),
      title: _getStepTitle(),
      subtitle: _getStepSubtitle(),
      showBackButton: true,
      onBack: _handleBack,
      isFormValid: _isFormValid,
      onNext: _handleNext, // This is still used for optional tracking
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_getCurrentStepContent()],
          ),
        ),
      ),
    );
  }
}
            // Fixed bottom button
            // Padding(
            //   padding: const EdgeInsets.all(24.0),
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: CustomButton(
            //       text: _getButtonText(),
            //       onPressed: _isFormValid ? _handleNext : null,
            //       isDisabled: !_isFormValid,
            //     ),
            //   ),
            // ),
          