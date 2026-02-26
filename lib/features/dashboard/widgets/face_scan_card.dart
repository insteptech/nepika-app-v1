import 'package:flutter/material.dart';

class FaceScanCard extends StatelessWidget {
  final Map<String, dynamic> faceScan;
  final VoidCallback? onTap;

  const FaceScanCard({super.key, required this.faceScan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final imageSize = isSmallScreen ? 90.0 : 110.0;

    return Container(
      width: double.infinity,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Text content — this drives the card height
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
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
                      const SizedBox(height: 10),
                      Text(
                        faceScan['title'] ?? 'Face Scan',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        faceScan['description'] ??
                            'See the condition of your skin.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondary
                                  .withValues(alpha: 0.8),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          child: Text(
                            'Scan Now',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Invisible spacer so text doesn't go behind the image
                SizedBox(width: imageSize + 16),
              ],
            ),
          ),
          // Image — positioned independently, doesn't affect card height
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/camera_guide_3.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
