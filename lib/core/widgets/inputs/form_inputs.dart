import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../base/base_widgets.dart';
import '../mixins/widget_behaviors.dart';

/// Text Input Field following SOLID principles
class CustomTextInput extends BaseFormField<String> with ThemeAwareBehavior {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;

  const CustomTextInput({
    super.key,
    super.initialValue,
    super.label,
    super.hint,
    super.isRequired = false,
    super.validator,
    super.onChanged,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
  });

  @override
  CustomTextInputState createState() => CustomTextInputState();
}

class CustomTextInputState extends BaseFormFieldState<String, CustomTextInput> 
    with ThemeAwareBehavior {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  String? get value => _controller.text.isEmpty ? null : _controller.text;

  @override
  void setValue(String? newValue) {
    _controller.text = newValue ?? '';
    super.setValue(newValue);
  }

  @override
  void clear() {
    _controller.clear();
    super.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: getTextTheme(context).titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          onChanged: (value) {
            setState(() {
              // Clear error when user starts typing
              if (errorMessage != null) {
                // Reset validation state
                validate();
              }
            });
            widget.onChanged?.call(value.isEmpty ? null : value);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            errorText: errorMessage,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: getPrimaryColor(context),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Email Input Field with built-in validation
class EmailInput extends CustomTextInput {
  const EmailInput({
    super.key,
    super.controller,
    super.label = 'Email',
    super.hint = 'Enter your email address',
    super.isRequired = true,
    super.onChanged,
  }) : super(
    keyboardType: TextInputType.emailAddress,
    validator: validateEmail,
  );

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
}

/// Password Input Field with built-in validation
class PasswordInput extends CustomTextInput {
  final bool showToggle;

  const PasswordInput({
    super.key,
    super.controller,
    super.label = 'Password',
    super.hint = 'Enter your password',
    super.isRequired = true,
    super.onChanged,
    this.showToggle = true,
  }) : super(
    obscureText: true,
    validator: validatePassword,
  );

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }

  @override
  CustomTextInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends CustomTextInputState {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: getTextTheme(context).titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          obscureText: _isObscured,
          onChanged: (value) {
            setState(() {
              if (errorMessage != null) {
                // Reset validation state
                validate();
              }
            });
            widget.onChanged?.call(value.isEmpty ? null : value);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: (widget as PasswordInput).showToggle
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
            errorText: errorMessage,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: getPrimaryColor(context),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
