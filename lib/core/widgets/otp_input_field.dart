import 'dart:io';
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
  final OtpController? controller;
  final List<String>? autofillHints; // ✅ use List<String> for TextFormField

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
  }

  @override
  void dispose() {
    widget.controller?._detach();
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  void _onTextChanged(String value, int index) {
    if (_isProcessingPaste) return;

    if (value.length > 1) {
      _handlePastedText(value, index);
      return;
    }

    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.length == 1 && index == widget.length - 1) {
      _focusNodes[index].unfocus();
    }

    _updateOtp();
  }

  void _handlePastedText(String pastedText, int startIndex) {
    if (!mounted) return;
    _isProcessingPaste = true;

    String digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    for (var controller in _controllers) controller.clear();

    for (int i = 0; i < digits.length && i < widget.length; i++) {
      _controllers[i].text = digits[i];
    }

    int nextFocus = digits.length >= widget.length ? widget.length - 1 : digits.length;
    _focusNodes[nextFocus].requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isProcessingPaste = false;
      _updateOtp();
    });
  }

  void _updateOtp() {
    _otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(_otp);
    if (_otp.length == widget.length) widget.onCompleted(_otp);
  }

  void clearOtp() {
    for (var c in _controllers) c.clear();
    _otp = '';
    widget.onChanged?.call(_otp);
    if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
  }

  void setOtp(String otp) {
    for (var c in _controllers) c.clear();
    String digits = otp.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < digits.length && i < widget.length; i++) {
      _controllers[i].text = digits[i];
    }
    _updateOtp();
    for (var node in _focusNodes) node.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            autofillHints: widget.autofillHints ??
                (Platform.isIOS ? [AutofillHints.oneTimeCode] : null),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
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
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
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
