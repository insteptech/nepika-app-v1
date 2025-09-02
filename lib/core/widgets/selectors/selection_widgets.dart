import 'package:flutter/material.dart';
import '../base/base_widgets.dart';
import '../mixins/widget_behaviors.dart';

/// Dropdown Selector following SOLID principles
class DropdownSelector<T> extends BaseSelector<T> {
  final String Function(T) itemBuilder;
  final Widget? icon;
  final double? width;

  const DropdownSelector({
    super.key,
    required super.options,
    required this.itemBuilder,
    super.initialValue,
    super.label,
    super.onSelectionChanged,
    this.icon,
    this.width,
  });

  @override
  DropdownSelectorState<T> createState() => DropdownSelectorState<T>();
}

class DropdownSelectorState<T> extends BaseSelectorState<T, DropdownSelector<T>>
    with ThemeAwareBehavior {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: getTextTheme(context).titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: widget.width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selectedValue,
              icon: widget.icon ?? const Icon(Icons.keyboard_arrow_down),
              isExpanded: true,
              onChanged: (T? newValue) {
                if (newValue != null) {
                  select(newValue);
                }
              },
              items: options.map<DropdownMenuItem<T>>((T value) {
                return DropdownMenuItem<T>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(widget.itemBuilder(value)),
                  ),
                );
              }).toList(),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select an option...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Multi-Select Chip Selector
class ChipSelector<T> extends BaseSelector<T> {
  final String Function(T) itemBuilder;
  final bool multiSelect;
  final List<T> selectedValues;
  final void Function(List<T>)? onMultiSelectionChanged;

  const ChipSelector({
    super.key,
    required super.options,
    required this.itemBuilder,
    super.label,
    this.multiSelect = false,
    this.selectedValues = const [],
    this.onMultiSelectionChanged,
    super.onSelectionChanged,
  }) : super(initialValue: null);

  @override
  ChipSelectorState<T> createState() => ChipSelectorState<T>();
}

class ChipSelectorState<T> extends BaseSelectorState<T, ChipSelector<T>>
    with ThemeAwareBehavior {
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.selectedValues);
  }

  bool _isSelected(T value) {
    return widget.multiSelect 
        ? _selectedValues.contains(value)
        : selectedValue == value;
  }

  void _toggleSelection(T value) {
    setState(() {
      if (widget.multiSelect) {
        if (_selectedValues.contains(value)) {
          _selectedValues.remove(value);
        } else {
          _selectedValues.add(value);
        }
        widget.onMultiSelectionChanged?.call(_selectedValues);
      } else {
        if (selectedValue == value) {
          deselect();
        } else {
          select(value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: getTextTheme(context).titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((T value) {
            final isSelected = _isSelected(value);
            return FilterChip(
              label: Text(widget.itemBuilder(value)),
              selected: isSelected,
              onSelected: (_) => _toggleSelection(value),
              backgroundColor: Colors.grey.shade100,
              selectedColor: getPrimaryColor(context).withValues(alpha: 0.2),
              checkmarkColor: getPrimaryColor(context),
              side: BorderSide(
                color: isSelected 
                    ? getPrimaryColor(context) 
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Radio Button Group Selector
class RadioGroupSelector<T> extends BaseSelector<T> {
  final String Function(T) itemBuilder;
  final Axis direction;

  const RadioGroupSelector({
    super.key,
    required super.options,
    required this.itemBuilder,
    super.initialValue,
    super.label,
    super.onSelectionChanged,
    this.direction = Axis.vertical,
  });

  @override
  RadioGroupSelectorState<T> createState() => RadioGroupSelectorState<T>();
}

class RadioGroupSelectorState<T> extends BaseSelectorState<T, RadioGroupSelector<T>>
    with ThemeAwareBehavior {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: getTextTheme(context).titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        widget.direction == Axis.vertical
            ? Column(
                children: _buildRadioOptions(),
              )
            : Row(
                children: _buildRadioOptions(),
              ),
      ],
    );
  }

  List<Widget> _buildRadioOptions() {
    return options.map((T value) {
      return InkWell(
        onTap: () => select(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: widget.direction == Axis.horizontal 
                ? MainAxisSize.min 
                : MainAxisSize.max,
            children: [
              Radio<T>(
                value: value,
                groupValue: selectedValue,
                onChanged: (T? newValue) {
                  if (newValue != null) {
                    select(newValue);
                  }
                },
                activeColor: getPrimaryColor(context),
              ),
              Expanded(
                flex: widget.direction == Axis.horizontal ? 0 : 1,
                child: Text(
                  widget.itemBuilder(value),
                  style: getTextTheme(context).bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
