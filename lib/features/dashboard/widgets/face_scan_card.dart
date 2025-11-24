import 'package:flutter/material.dart';

class FaceScanCard extends StatelessWidget {
  final Map<String, dynamic> faceScan;
  final VoidCallback? onTap;

  const FaceScanCard({super.key, required this.faceScan, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 180,
        maxHeight: 200
      ),
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
      padding: const EdgeInsets.all(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Spacer(),
              Text(
                faceScan['title'] ?? 'Face Scan',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 150,
                child: Text(
                  faceScan['description'] ?? 'See the condition of your skin.',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondary.withOpacity(0.8),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  width: 170,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      'Scan Now',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Container(
            height: 121,
            width: 121,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            clipBehavior:
                Clip.antiAlias,
            child: Image.asset(
              'assets/images/camera_guide_3_image.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
