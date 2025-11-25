import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepika/core/widgets/custom_text_field.dart';
import 'package:nepika/core/widgets/selection_button.dart';
import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';

class OptionItem {
  final String label;
  final String id;
  final dynamic value;
  final bool isSelected;
  final String? description;

  const OptionItem({
    required this.label,
    required this.id,
    this.value,
    this.isSelected = false,
    this.description,
  });
}

class QuestionInput extends StatefulWidget {
  final OnboardingQuestionEntity question;
  final dynamic currentValue;
  final Map<String, dynamic> allAnswers;
  final Function(String slug, dynamic value) onValueChanged;
  final int? optionsPerRow;

  const QuestionInput({
    super.key,
    required this.question,
    required this.currentValue,
    required this.allAnswers,
    required this.onValueChanged,
    this.optionsPerRow,
  });

  @override
  State<QuestionInput> createState() => _QuestionInputState();
}

class _QuestionInputState extends State<QuestionInput> {
  late TextEditingController _textController;
  DateTime? _selectedDate;
  RangeValues _rangeValues = const RangeValues(0, 10);
  bool _userModified = false;
  bool _sliderCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(QuestionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_userModified && oldWidget.currentValue != widget.currentValue) {
      _updateControllerValue();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _initializeController() {
    final initialValue = widget.currentValue ?? widget.question.prefillValue;
    
    if (widget.question.inputType == "date" && initialValue != null && initialValue is String && initialValue.isNotEmpty) {
      _initializeDateController(initialValue);
    } else if (widget.question.inputType == "range" && initialValue != null) {
      _initializeRangeController(initialValue);
    } else if (widget.question.inputType == "slider") {
      // Initialize slider state based on existing value
      _sliderCompleted = initialValue != null && initialValue.toString().isNotEmpty;
      _textController = TextEditingController();
    } else {
      _textController = TextEditingController(text: initialValue?.toString() ?? '');
    }

    _textController.addListener(_onTextChanged);
  }

  void _initializeDateController(String value) {
    try {
      final parsed = DateFormat("yyyy-MM-dd").parse(value);
      final displayFormat = DateFormat('dd MMM yyyy');
      _textController = TextEditingController(text: displayFormat.format(parsed));
      _selectedDate = parsed;
    } catch (e) {
      _textController = TextEditingController(text: value);
    }
  }

  void _initializeRangeController(dynamic value) {
    if (value is List && value.length == 2) {
      _rangeValues = RangeValues(
        (value[0] is num) ? value[0].toDouble() : 0,
        (value[1] is num) ? value[1].toDouble() : 10,
      );
    }
    _textController = TextEditingController();
  }

  void _updateControllerValue() {
    final value = widget.currentValue;
    
    if (widget.question.inputType == "date" && value != null && value is String && value.isNotEmpty) {
      _initializeDateController(value);
    } else if (widget.question.inputType == "range" && value != null) {
      _initializeRangeController(value);
    } else if (widget.question.inputType != "single_choice" && 
               widget.question.inputType != "dropdown" &&
               widget.question.inputType != "checkbox" &&
               widget.question.inputType != "multi_choice") {
      _textController.text = value?.toString() ?? '';
    }
  }

  void _onTextChanged() {
    if (widget.question.inputType == "text" && 
        _textController.text != (widget.currentValue?.toString() ?? '')) {
      _userModified = true;
      widget.onValueChanged(widget.question.slug, _textController.text);
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
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
        _selectedDate = picked;
        final displayFormat = DateFormat('dd MMM yyyy');
        _textController.text = displayFormat.format(picked);
        final isoFormatForDb = DateFormat('yyyy-MM-dd');
        final payloadValue = isoFormatForDb.format(picked);
        _userModified = true;
        widget.onValueChanged(widget.question.slug, payloadValue);
      });
    }
  }

  TextInputType _getKeyboardType() {
    switch (widget.question.keyboardType?.toLowerCase()) {
      case 'numeric':
        return TextInputType.number;
      case 'slider':
        return TextInputType.none;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'multiline':
        return TextInputType.multiline;
      case 'date':
        return TextInputType.datetime;
      case 'text':
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
      key: ValueKey('${widget.question.slug}-${widget.question.inputType}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.questionText,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        _buildInputWidget(),
      ],
    ),
    );
  }

  Widget _buildInputWidget() {
    switch (widget.question.inputType) {
      case "text":
        return UnderlinedTextField(
          hint: widget.question.inputPlaceholder,
          controller: _textController,
          keyboardType: _getKeyboardType(),
          onChanged: (val) {
            _userModified = true;
            widget.onValueChanged(widget.question.slug, val);
          },
        );

      case "date":
        return UnderlinedTextField(
          controller: _textController,
          readOnly: true,
          hint: widget.question.inputPlaceholder,
          onTap: _selectDate,
          keyboardType: _getKeyboardType(),
          validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
        );

      case "range":
        return Column(
          children: [
            RangeSlider(
              values: _rangeValues,
              min: 0,
              max: 100,
              divisions: 20,
              labels: RangeLabels(
                _rangeValues.start.round().toString(),
                _rangeValues.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _rangeValues = values;
                });
                widget.onValueChanged(widget.question.slug, [values.start, values.end]);
              },
            ),
          ],
        );
      case "slider":
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Are you exposed to high pollution levels?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch(
              value: _sliderCompleted,
              onChanged: (bool value) {
                setState(() {
                  _sliderCompleted = value;
                });
                
                if (value) {
                  // Yes - exposed to high pollution
                  final toggleValue = widget.question.options.isNotEmpty 
                      ? widget.question.options.first.value 
                      : "yes";
                  widget.onValueChanged(widget.question.slug, toggleValue);
                } else {
                  // No - not exposed to high pollution
                  widget.onValueChanged(widget.question.slug, "no");
                }
              },
            ),
          ],
        );

      case "single_choice":
        return SingleChoiceInput(
          question: widget.question,
          currentValue: widget.currentValue,
          optionsPerRow: widget.optionsPerRow,
          onValueChanged: widget.onValueChanged,
        );

      case "multi_choice":
        return MultiChoiceInput(
          question: widget.question,
          currentValue: widget.currentValue,
          optionsPerRow: widget.optionsPerRow,
          onValueChanged: widget.onValueChanged,
        );

      case "checkbox":
        return CheckboxInput(
          question: widget.question,
          currentValue: widget.currentValue,
          onValueChanged: widget.onValueChanged,
        );

      case "dropdown":
        return DropdownInput(
          question: widget.question,
          currentValue: widget.currentValue,
          onValueChanged: widget.onValueChanged,
        );

      default:
        return const Text("Unsupported input type");
    }
  }
}

class SingleChoiceInput extends StatelessWidget {
  final OnboardingQuestionEntity question;
  final dynamic currentValue;
  final int? optionsPerRow;
  final Function(String slug, dynamic value) onValueChanged;

  const SingleChoiceInput({
    super.key,
    required this.question,
    required this.currentValue,
    this.optionsPerRow,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('SingleChoiceInput: Building for question "${question.questionText}"');
    debugPrint('SingleChoiceInput: Current value: $currentValue');
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final options = question.options;
        final descriptionOptions = options.where((opt) => _hasValidDescription(opt.description)).toList();
        final nonDescriptionOptions = options.where((opt) => !_hasValidDescription(opt.description)).toList();

        debugPrint('SingleChoiceInput: Non-description options: ${nonDescriptionOptions.map((o) => '${o.text}(${o.id})').toList()}');
        debugPrint('SingleChoiceInput: Selected values set: {$currentValue}');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (descriptionOptions.isNotEmpty)
              ...descriptionOptions.map((option) => Container(
                width: constraints.maxWidth,
                margin: const EdgeInsets.only(bottom: 16),
                child: SkinTypeCard(
                  option: option,
                  isSelected: _getSelectedOptionIds().contains(option.id),
                  onTap: () {
                    debugPrint('SingleChoiceInput: SkinTypeCard tapped for "${option.text}" (${option.id})');
                    onValueChanged(question.slug, option.id);
                  },
                ),
              )),

            if (nonDescriptionOptions.isNotEmpty)
              OptionButtons(
                options: nonDescriptionOptions,
                selectedValues: _getSelectedOptionIds(),
                isMultiSelect: false,
                optionsPerRow: optionsPerRow,
                onOptionSelected: (optionId) {
                  debugPrint('SingleChoiceInput: Option selected: $optionId');
                  onValueChanged(question.slug, optionId);
                },
              ),
          ],
        );
      },
    );
  }

  bool _hasValidDescription(String? description) {
    return description != null && description.trim().isNotEmpty;
  }

  Set<dynamic> _getSelectedOptionIds() {
    if (currentValue == null) return {};
    
    // Find the option that matches the current value
    final selectedOption = question.options.firstWhere(
      (option) => option.id == currentValue || option.value == currentValue || option.text == currentValue,
      orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
    );
    
    if (selectedOption.id.isNotEmpty) {
      debugPrint('SingleChoiceInput: Found selected option ID: ${selectedOption.id} for value: $currentValue');
      return {selectedOption.id};
    }
    
    debugPrint('SingleChoiceInput: No matching option found for value: $currentValue');
    return {};
  }
}

class MultiChoiceInput extends StatelessWidget {
  final OnboardingQuestionEntity question;
  final dynamic currentValue;
  final int? optionsPerRow;
  final Function(String slug, dynamic value) onValueChanged;

  const MultiChoiceInput({
    super.key,
    required this.question,
    required this.currentValue,
    this.optionsPerRow,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSet = _getSelectedSet();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final options = question.options;
        final descriptionOptions = options.where((opt) => _hasValidDescription(opt.description)).toList();
        final nonDescriptionOptions = options.where((opt) => !_hasValidDescription(opt.description)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (descriptionOptions.isNotEmpty)
              ...descriptionOptions.map((option) => Container(
                width: constraints.maxWidth,
                margin: const EdgeInsets.only(bottom: 16),
                child: SkinTypeCard(
                  option: option,
                  isSelected: selectedSet.contains(option.id),
                  onTap: () => _toggleOption(option.id),
                ),
              )),

            if (nonDescriptionOptions.isNotEmpty)
              OptionButtons(
                options: nonDescriptionOptions,
                selectedValues: selectedSet,
                isMultiSelect: true,
                optionsPerRow: optionsPerRow,
                onOptionSelected: _toggleOption,
              ),
          ],
        );
      },
    );
  }

  Set<dynamic> _getSelectedSet() {
    final value = currentValue;
    if (value is List<dynamic>) {
      return Set<dynamic>.from(value);
    } else if (value != null) {
      return {value};
    }
    return {};
  }

  void _toggleOption(String optionId) {
    final selectedSet = _getSelectedSet();
    if (selectedSet.contains(optionId)) {
      selectedSet.remove(optionId);
    } else {
      selectedSet.add(optionId);
    }
    onValueChanged(question.slug, selectedSet.toList());
  }

  bool _hasValidDescription(String? description) {
    return description != null && description.trim().isNotEmpty;
  }
}

class CheckboxInput extends StatelessWidget {
  final OnboardingQuestionEntity question;
  final dynamic currentValue;
  final Function(String slug, dynamic value) onValueChanged;

  const CheckboxInput({
    super.key,
    required this.question,
    required this.currentValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSet = _getSelectedSet();
    
    return SizedBox(
      width: double.infinity,
      child: Wrap(
      spacing: 12.0, // Horizontal spacing between items
      runSpacing: 12.0, // Vertical spacing between rows
      children: question.options.map((option) {
        final isSelected = selectedSet.contains(option.id);
        
        return IntrinsicWidth(
          child: GestureDetector(
              onTap: () => _toggleOption(option.id),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
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
                    const SizedBox(width: 8),
                    Text(
                        option.text,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                        // maxLines: 1,
                        // overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
        );
      }).toList(),
    ),
    );
  }

  Set<dynamic> _getSelectedSet() {
    final value = currentValue;
    if (value is List<dynamic>) {
      // Convert values to option IDs if necessary
      final optionIds = <dynamic>{};
      for (final val in value) {
        // First try to find by ID
        final byId = question.options.firstWhere(
          (option) => option.id == val,
          orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
        );
        if (byId.id.isNotEmpty) {
          optionIds.add(byId.id);
        } else {
          // Then try to find by value or text
          final byValue = question.options.firstWhere(
            (option) => option.value == val || option.text == val,
            orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
          );
          if (byValue.id.isNotEmpty) {
            optionIds.add(byValue.id);
          }
        }
      }
      return optionIds;
    } else if (value != null) {
      // Handle single value case
      final option = question.options.firstWhere(
        (option) => option.id == value || option.value == value || option.text == value,
        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
      );
      return option.id.isNotEmpty ? {option.id} : {};
    }
    return {};
  }

  void _toggleOption(String optionId) {
    final selectedSet = _getSelectedSet();
    if (selectedSet.contains(optionId)) {
      selectedSet.remove(optionId);
    } else {
      selectedSet.add(optionId);
    }
    onValueChanged(question.slug, selectedSet.toList());
  }
}

class DropdownInput extends StatelessWidget {
  final OnboardingQuestionEntity question;
  final dynamic currentValue;
  final Function(String slug, dynamic value) onValueChanged;

  const DropdownInput({
    super.key,
    required this.question,
    required this.currentValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue is String ? currentValue : null,
        decoration: InputDecoration(
          hintText: question.inputPlaceholder,
          hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0x663898ED), width: 1),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
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
        items: question.options
            .map((option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(
                    option.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w400),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onValueChanged(question.slug, value);
          }
        },
      ),
    );
  }
}

class SkinTypeCard extends StatelessWidget {
  final OnboardingOptionEntity option;
  final bool isSelected;
  final VoidCallback onTap;

  const SkinTypeCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.onSecondary.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.onSecondary.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                _getIconForSkinType(option.value),
                color: isSelected
                    ? theme.colorScheme.onSecondary
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.text,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onSecondary
                          : theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onSecondary.withValues(alpha: 0.8)
                          : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                      fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 14) - 1,
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

  IconData _getIconForSkinType(String type) {
    switch (type.toLowerCase()) {
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
}

class OptionButtons extends StatelessWidget {
  final List<OnboardingOptionEntity> options;
  final Set<dynamic> selectedValues;
  final bool isMultiSelect;
  final int? optionsPerRow;
  final Function(String) onOptionSelected;

  const OptionButtons({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.isMultiSelect,
    this.optionsPerRow,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
        const spacing = 10.0;
        final hasExplicitOptionsPerRow = optionsPerRow != null;
        
        if (hasExplicitOptionsPerRow) {
          return _buildGridLayout(constraints, spacing);
        } else {
          // Use simple wrap layout for better stability
          return Wrap(
            spacing: spacing,
            runSpacing: 12.0,
            children: options.map((option) => _buildOptionButton(option)).toList(),
          );
        }
        },
      ),
    );
  }

  Widget _buildGridLayout(BoxConstraints constraints, double spacing) {
    List<Widget> rows = [];
    final perRow = optionsPerRow!;
    
    for (int i = 0; i < options.length; i += perRow) {
      List<Widget> rowChildren = [];
      
      for (int j = 0; j < perRow && (i + j) < options.length; j++) {
        final option = options[i + j];
        rowChildren.add(_buildOptionButton(option));
        
        // Add spacing between buttons (except for the last one)
        if (j < perRow - 1 && (i + j + 1) < options.length) {
          rowChildren.add(const SizedBox(width: 10));
        }
      }
      
      // Use left alignment for all rows
      const alignment = MainAxisAlignment.start;
      
      rows.add(
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: alignment,
            children: rowChildren,
          ),
        ),
      );
    }
    
    return Column(
      children: rows.map((row) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: row,
      )).toList(),
    );
  }


  Widget _buildOptionButton(OnboardingOptionEntity option) {
    final isSelected = selectedValues.contains(option.id);
    
    debugPrint('OptionButtons: Building button for "${option.text}" (${option.id})');
    debugPrint('OptionButtons: Selected values: $selectedValues');
    debugPrint('OptionButtons: Is selected: $isSelected');

    return SelectionButton(
      text: option.text,
      isSelected: isSelected,
      onPressed: () {
        debugPrint('OptionButtons: Button pressed for "${option.text}" (${option.id})');
        onOptionSelected(option.id);
      },
    );
  }
}