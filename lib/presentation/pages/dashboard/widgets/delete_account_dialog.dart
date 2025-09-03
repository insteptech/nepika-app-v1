import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';

class DeleteAccountDialog extends StatefulWidget {
  final List<String> reasons;
  const DeleteAccountDialog({super.key, required this.reasons});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: theme.colorScheme.onTertiary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose a reason',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280, // Adjust height based on your design
              child: SingleChildScrollView(
                child: Column(
                  children: widget.reasons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reason = entry.value;
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reason,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            // color: isSelected
                            //     ? theme.colorScheme.primary
                            //     : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _selectedIndex != null
                        ? () => _handleDelete(
                            context, widget.reasons[_selectedIndex!])
                        : null,
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, String selectedReason) {
    debugPrint('Account deleted for reason: $selectedReason');
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
