import 'package:flutter/material.dart';
import '../../../core/widgets/otp_input_field.dart';

class AuthOtpInput extends StatelessWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final OtpController? controller;
  final int length;

  const AuthOtpInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OtpInputField(
          length: length,
          controller: controller,
          onCompleted: onCompleted,
          onChanged: onChanged,
        ),
      ],
    );
  }
}