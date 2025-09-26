import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

class OnboardingSkeleton extends StatelessWidget {
  const OnboardingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          InputSkeleton(),
          OptionTileSkeleton(),
          QuestionSkeleton(numOptions: 4),
        ],
      ),
    );
  }
}

class InputSkeleton extends StatelessWidget {
  const InputSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
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
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            // Input field skeleton
            Container(
              width: MediaQuery.of(context).size.width,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge
                    ?.secondary(context)
                    .color
                    ?.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionTileSkeleton extends StatelessWidget {
  const OptionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
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
                borderRadius: const BorderRadius.all(Radius.circular(10)),
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
        padding: const EdgeInsets.only(bottom: 32),
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
                borderRadius: const BorderRadius.all(Radius.circular(4)),
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
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
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