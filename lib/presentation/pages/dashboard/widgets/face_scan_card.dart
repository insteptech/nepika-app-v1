import 'package:flutter/material.dart';

class FaceScanCard extends StatelessWidget {
  final Map<String, dynamic> faceScan;
  final VoidCallback? onTap;

  const FaceScanCard({required this.faceScan, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
            child: Image.asset(
              'assets/icons/scan_icon.png',
              width: 20,
              height: 20,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            ),
            const Spacer(),
            Text(
              faceScan['title'] ?? 'Face Scan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
              ),
                
            ),
            const SizedBox(height: 6),
            Text(
              faceScan['description'] ?? 'See the condition of your skin.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
