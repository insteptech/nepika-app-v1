import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

class SectionHeader extends StatelessWidget {
  final String heading;
  final bool showButton;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final bool buttonLoading;

  const SectionHeader({
    super.key,
    required this.heading,
    this.showButton = false,
    this.buttonText = 'View all',
    this.onButtonPressed,
    this.buttonLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  heading,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (showButton)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: GestureDetector(
                    onTap: buttonLoading ? null : onButtonPressed,
                    child: Opacity(
                      opacity: buttonLoading ? 0.7 : 1.0,
                      child: Text(
                        buttonText,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.hint(context)
                            .copyWith(
                              decoration: TextDecoration.combine([
                                TextDecoration.underline,
                              ]),
                              decorationColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
