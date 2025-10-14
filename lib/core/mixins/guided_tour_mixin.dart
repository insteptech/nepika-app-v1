import 'package:flutter/material.dart';
import '../widgets/guided_tour_overlay.dart';

/// Mixin to easily add guided tour functionality to any screen
mixin GuidedTourMixin<T extends StatefulWidget> on State<T> {
  
  /// Start the guided tour if it hasn't been seen before
  Future<void> startTourIfNeeded({
    required List<TourStep> steps,
    required Future<bool> Function() hasSeenTour,
    required Future<void> Function() markTourAsSeen,
    VoidCallback? onComplete,
  }) async {
    // Wait for the screen to be fully built
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final hasSeenTourBefore = await hasSeenTour();
    if (!hasSeenTourBefore && mounted) {
      await GuidedTourOverlay.startTour(
        context: context,
        steps: steps,
        onComplete: () async {
          await markTourAsSeen();
          onComplete?.call();
        },
      );
    }
  }

  /// Create a tour step with common defaults
  TourStep createTourStep({
    required String title,
    required String description,
    required GlobalKey targetKey,
    Alignment tooltipAlignment = Alignment.bottomCenter,
    EdgeInsets tooltipOffset = const EdgeInsets.only(top: 20),
  }) {
    return TourStep(
      title: title,
      description: description,
      targetKey: targetKey,
      tooltipAlignment: tooltipAlignment,
      tooltipOffset: tooltipOffset,
    );
  }
}