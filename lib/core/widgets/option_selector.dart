import 'package:flutter/material.dart';
import 'selection_button.dart';

class OptionItem {
  final String label;
  final String id;
  final dynamic value;

  const OptionItem({
    required this.label,
    required this.id,
    this.value,
  });
}

class OptionSelector extends StatelessWidget {
  final String title;
  final List<OptionItem> options;
  final dynamic selectedValue;
  final Function(OptionItem) onOptionSelected;
  final bool multiSelect;

  const OptionSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onOptionSelected,
    this.multiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
        ),
        const SizedBox(height: 10),
        _buildOptionsWrap(),
      ],
    );
  }

  Widget _buildOptionsWrap() {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 12,
        children: options.map((option) {
        final isSelected = _isOptionSelected(option);
        
        return SelectionButton(
          text: option.label,
          isSelected: isSelected,
          onPressed: () => onOptionSelected(option),
        );
              }).toList(),
      ),
    );
  }

  bool _isOptionSelected(OptionItem option) {
    if (multiSelect && selectedValue is Set) {
      final Set selectedSet = selectedValue as Set;
      return selectedSet.contains(option.value ?? option.id);
    } else {
      return selectedValue == (option.value ?? option.id);
    }
  }
}

class MultiOptionSelector extends StatelessWidget {
  final String title;
  final List<OptionItem> options;
  final Set<dynamic> selectedValues;
  final Function(OptionItem, bool) onOptionToggled;

  const MultiOptionSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onOptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 12,
            runSpacing: 16,
            children: options.map((option) {
            final isSelected = selectedValues.contains(option.value ?? option.id);
            
            return SelectionButton(
              text: option.label,
              isSelected: isSelected,
              onPressed: () => onOptionToggled(option, !isSelected),
            );
                      }).toList(),
          ),
        ),
      ],
    );
  }
}