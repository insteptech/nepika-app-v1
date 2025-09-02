import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';

class FeatureSuggestionDialog extends StatefulWidget {
  const FeatureSuggestionDialog({super.key});

  @override
  State<FeatureSuggestionDialog> createState() => _FeatureSuggestionDialogState();
}

class _FeatureSuggestionDialogState extends State<FeatureSuggestionDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isNotEmpty = _controller.text.trim().isNotEmpty;
      if (isNotEmpty != _isButtonEnabled) {
        setState(() {
          _isButtonEnabled = isNotEmpty;
        });
      }
    });
  }

  void _handleSubmit() {
    Navigator.of(context).pop();
    print('Suggested feature: ${_controller.text}');
    showDialog(
      context: context,
      builder: (context) => const ThankYouDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Suggest a Feature',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Type your feature suggestion...",
                  hintStyle: Theme.of(context).textTheme.bodyLarge!.secondary(context),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isButtonEnabled ? _handleSubmit : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Submit", style: TextStyle(color: Colors.blue)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThankYouDialog extends StatelessWidget {
  const ThankYouDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/thumbs_up_icon.png',
              width: 70,
              height: 70,
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for your suggestion',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for your suggestion we will review it',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.secondary(context),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dashboardHome,
                  (route) => false,
                );
              },
              child: Text(
                'Go to homepage',
                style: Theme.of(context).textTheme.bodyLarge!.hint(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
