import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nepika/core/config/constants/theme.dart';

class _OtpInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only single digit or let the widget handle multi-digit paste
    if (newValue.text.length <= 1) {
      return newValue;
    }
    // For multi-digit input, return the new value to let _onTextChanged handle it
    return newValue;
  }
}

class OtpInputField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  
  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _otp = '';
  bool _isProcessingPaste = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value, int index) {
    // Skip processing if we're handling a paste operation
    if (_isProcessingPaste) return;

    if (value.length > 1) {
      // Handle paste - extract only digits and distribute
      _handlePastedText(value, index);
      return;
    }

    if (value.length == 1) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    _updateOtp();
  }

  void _handlePastedText(String pastedText, int startIndex) {
    if (!mounted) return;
    _isProcessingPaste = true;
    
    // Extract only digits from pasted text
    String digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Clear all fields first
    for (var controller in _controllers) {
      controller.clear();
    }
    
    // Fill fields with the digits from the beginning
    for (int i = 0; i < digits.length && i < widget.length; i++) {
      _controllers[i].text = digits[i];
    }
    
    // Focus the appropriate field
    int nextFocusIndex = digits.length;
    if (nextFocusIndex >= widget.length) {
      // All fields filled, unfocus to trigger completion
      _focusNodes[widget.length - 1].unfocus();
    } else {
      // Focus the next empty field
      _focusNodes[nextFocusIndex].requestFocus();
    }
    
    // Use a post-frame callback to update OTP after the paste operation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isProcessingPaste = false;
      _updateOtp();
    });
  }

  void _updateOtp() {
    // Update OTP string
    _otp = '';
    for (var controller in _controllers) {
      _otp += controller.text;
    }

    widget.onChanged?.call(_otp);

    // Check if OTP is complete
    if (_otp.length == widget.length) {
      widget.onCompleted(_otp);
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        // Handle backspace navigation
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field and clear it
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          _updateOtp();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 48,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(event, index),
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                // Custom formatter to handle paste and single character input
                _OtpInputFormatter(),
              ],
              style: Theme.of(context).textTheme.displaySmall,
              decoration: InputDecoration(
                counterText: '',
                filled: false,
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0x663898ED), width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  , width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
                ),
                errorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.errorColor),
                ),
                focusedErrorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) => _onTextChanged(value, index),
              onTap: () {
                _controllers[index].selection = TextSelection.fromPosition(
                  TextPosition(offset: _controllers[index].text.length),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}