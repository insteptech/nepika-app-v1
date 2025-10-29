import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


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
  final OtpController? controller;
  final List<String>? autofillHints;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autofillHints,
    this.controller,
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
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    widget.controller?._attach(this);

    // Add listeners to rebuild on focus change
    for (var node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value, int index) {
    if (_isProcessingPaste) return;

    // Handle multi-digit paste
    if (value.length > 1) {
      _handlePastedText(value, index);
      return;
    }

    // Handle single digit input - move to next field
    if (value.length == 1) {
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
    
    setState(() {
      _isProcessingPaste = true;
    });

    // Extract only digits from pasted text
    String digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Clear all existing values
    for (var controller in _controllers) {
      controller.clear();
    }

    // Fill the fields with the extracted digits
    for (int i = 0; i < digits.length && i < widget.length; i++) {
      _controllers[i].text = digits[i];
    }

    // Set focus appropriately
    if (digits.length >= widget.length) {
      // If we have enough digits, unfocus all to show completion
      for (var node in _focusNodes) {
        node.unfocus();
      }
    } else {
      // Focus on the next empty field
      int nextFocus = digits.length < widget.length ? digits.length : widget.length - 1;
      _focusNodes[nextFocus].requestFocus();
    }

    // Update OTP after a brief delay to ensure UI is updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isProcessingPaste = false;
        });
        _updateOtp();
      }
    });
  }

  void _updateOtp() {
    _otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(_otp);
    if (_otp.length == widget.length) widget.onCompleted(_otp);
  }

  void clearOtp() {
    for (var c in _controllers) {
      c.clear();
    }
    _otp = '';
    widget.onChanged?.call(_otp);
    if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
  }

  void setOtp(String otp) {
    for (var c in _controllers) {
      c.clear();
    }
    String digits = otp.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < digits.length && i < widget.length; i++) {
      _controllers[i].text = digits[i];
    }
    _updateOtp();
    for (var node in _focusNodes) {
      node.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final bool hasFocus = _focusNodes[index].hasFocus;

        return Container(
          margin: EdgeInsets.only(right: index < widget.length - 1 ? 8 : 0),
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: hasFocus
                    ? Theme.of(context).colorScheme.primary // Active - full opacity
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), // Inactive - 40% opacity
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: 26,
            height: 38,
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_controllers[index].text.isEmpty && index > 0) {
                    _controllers[index - 1].clear();
                    _focusNodes[index - 1].requestFocus();
                    _updateOtp();
                  }
                }
              },
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                autofillHints: widget.autofillHints ?? const [
                  AutofillHints.oneTimeCode,
                ],
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _OtpInputFormatter(),
                ],
                style: TextStyle(
                  fontFamily: 'HelveticaNowDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.47,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
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
        );
      }),
    );
  }
}


class OtpController {
  _OtpInputFieldState? _state;

  void _attach(_OtpInputFieldState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void clear() {
    _state?.clearOtp();
  }

  void setText(String text) {
    _state?.setOtp(text);
  }
}
