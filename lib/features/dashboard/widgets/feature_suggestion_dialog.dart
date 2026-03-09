import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/api_endpoints.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/utils/app_logger.dart';

class FeatureSuggestionDialog extends StatefulWidget {
  const FeatureSuggestionDialog({super.key});

  @override
  State<FeatureSuggestionDialog> createState() => _FeatureSuggestionDialogState();
}

class _FeatureSuggestionDialogState extends State<FeatureSuggestionDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isValid = _controller.text.trim().length >= 10;
      if (isValid != _isButtonEnabled) {
        setState(() {
          _isButtonEnabled = isValid;
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final suggestionText = _controller.text.trim();
    if (suggestionText.length < 10) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiBase = ServiceLocator.get<ApiBase>();
      final response = await apiBase.request(
        path: ApiEndpoints.suggestions,
        method: 'POST',
        body: {
          'suggestion_text': suggestionText,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => const ThankYouDialog(),
        );
      } else {
        final message = response.data['message'] ?? 'Failed to submit suggestion';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      AppLogger.error('Suggestion Submission Error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit suggestion. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: "Type your feature suggestion (min 10 characters)...",
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
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_isButtonEnabled && !_isSubmitting) ? _handleSubmit : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: (_isButtonEnabled && !_isSubmitting)
                            ? Colors.blue
                            : Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            "Submit",
                            style: TextStyle(
                              color: (_isButtonEnabled && !_isSubmitting)
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                            ),
                          ),
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
