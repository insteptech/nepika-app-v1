import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';

class SectionHeader extends StatelessWidget {
  final String heading;
  final bool showButton;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final bool buttonLoading;

  const SectionHeader({
    Key? key,
    required this.heading,
    this.showButton = false,
    this.buttonText = 'View all',
    this.onButtonPressed,
    this.buttonLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              heading,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (showButton)
              GestureDetector(
                onTap: buttonLoading ? null : onButtonPressed,
                child: Opacity(
                  opacity: buttonLoading ? 0.7 : 1.0,
                  child: Text(
                    buttonText,
                    style: Theme.of(context).textTheme.bodyLarge!.hint(context)
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
