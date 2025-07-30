import 'package:flutter/material.dart';
import '../mixins/widget_behaviors.dart';

// Open/Closed Principle (O) - Open for extension, closed for modification
abstract class BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const BaseButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  bool get isEnabled => !isDisabled && onPressed != null;

  // Template method pattern - subclasses can override specific parts
  Widget buildButtonContent(BuildContext context);
  ButtonStyle getButtonStyle(BuildContext context);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: getButtonStyle(context),
        child: buildButtonContent(context),
      ),
    );
  }
}

abstract class BaseFormField<T> extends StatefulWidget {
  final T? initialValue;
  final String? label;
  final String? hint;
  final bool isRequired;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;

  const BaseFormField({
    super.key,
    this.initialValue,
    this.label,
    this.hint,
    this.isRequired = false,
    this.validator,
    this.onChanged,
  });
}

abstract class BaseFormFieldState<T, W extends BaseFormField<T>> extends State<W> 
    with FormFieldBehavior<T>, ValidatableBehavior {
  T? _value;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  T? get value => _value;
  
  @override
  void setValue(T? newValue) {
    setState(() {
      _value = newValue;
      _errorMessage = null;
    });
    widget.onChanged?.call(newValue);
  }
  
  @override
  void clear() {
    setValue(null);
  }
  
  @override
  bool validate() {
    _errorMessage = widget.validator?.call(_value);
    if (_errorMessage != null) {
      setState(() {});
      return false;
    }
    return true;
  }
  
  @override
  String? get errorMessage => _errorMessage;
}

abstract class BaseSelector<T> extends StatefulWidget {
  final List<T> options;
  final T? initialValue;
  final String? label;
  final void Function(T)? onSelectionChanged;

  const BaseSelector({
    super.key,
    required this.options,
    this.initialValue,
    this.label,
    this.onSelectionChanged,
  });
}

abstract class BaseSelectorState<T, W extends BaseSelector<T>> extends State<W> 
    with SelectableBehavior<T> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  T? get selectedValue => _selectedValue;
  
  @override
  void select(T value) {
    setState(() {
      _selectedValue = value;
    });
    widget.onSelectionChanged?.call(value);
  }
  
  @override
  void deselect() {
    setState(() {
      _selectedValue = null;
    });
  }

  @override
  List<T> get options => widget.options;
}
