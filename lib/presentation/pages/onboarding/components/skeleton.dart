import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

class InputSkeleton extends StatefulWidget {
  const InputSkeleton({super.key});

  @override
  State<InputSkeleton> createState() => _InputSkeletonState();
}

class _InputSkeletonState extends State<InputSkeleton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, left: 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge
                    ?.secondary(context)
                    .color
                    ?.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Options skeleton
            Container(
              width: MediaQuery.of(context).size.width,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge
                    ?.secondary(context)
                    .color
                    ?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionTileSkeleton extends StatefulWidget {
  const OptionTileSkeleton({super.key});

  @override
  State<OptionTileSkeleton> createState() => _OptionTileSkeletonState();
}

class _OptionTileSkeletonState extends State<OptionTileSkeleton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, left: 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge
                    ?.secondary(context)
                    .color
                    ?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionSkeleton extends StatelessWidget {
  final int numOptions;

  const QuestionSkeleton({super.key, this.numOptions = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, left: 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge
                    ?.secondary(context)
                    .color
                    ?.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Options skeleton
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                numOptions,
                (_) => Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.bodyLarge
                        ?.secondary(context)
                        .color
                        ?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}