import 'package:flutter/material.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/features/payments/bloc/payment_bloc.dart';
import 'package:nepika/features/payments/bloc/payment_state.dart';
import 'package:nepika/features/payments/bloc/payment_event.dart';
import 'package:nepika/features/payments/widgets/trial_expired_bottom_sheet.dart';

import 'package:nepika/domain/payments/entities/subscription_status.dart';

/// Centralized helper to gate scan access behind trial/subscription checks.
///
/// Uses [ServiceLocator] to access [PaymentBloc] so it works regardless
/// of where the widget sits in the tree.
///
/// Usage:
/// ```dart
/// if (TrialGateHelper.shouldBlockScan()) {
///   TrialGateHelper.showTrialExpiredSheet(context);
///   return;
/// }
/// // proceed to scan
/// ```
class TrialGateHelper {
  static SubscriptionStatus? _cachedStatus;
  static bool _isListening = false;

  TrialGateHelper._(); // prevent instantiation

  /// Initialize the listener to watch for subscription status updates
  static void initialize() {
    if (_isListening) return;
    
    try {
      final paymentBloc = ServiceLocator.get<PaymentBloc>();
      paymentBloc.stream.listen((state) {
        if (state is SubscriptionStatusLoaded) {
          _cachedStatus = state.status;
          debugPrint('🛡️ TrialGateHelper: Cached new subscription status.');
        }
      });
      
      // If the bloc already has the state loaded, grasp it immediately
      if (paymentBloc.state is SubscriptionStatusLoaded) {
        _cachedStatus = (paymentBloc.state as SubscriptionStatusLoaded).status;
      }
      
      _isListening = true;
    } catch (e) {
      debugPrint('⚠️ TrialGateHelper: Could not initialize listener ($e)');
    }
  }

  /// Returns `true` if the user's trial is exhausted (scans used up OR time expired)
  /// and they do NOT have a premium subscription.
  ///
  /// Returns `false` (allow scan) if:
  /// - PaymentBloc state is not [SubscriptionStatusLoaded] (fail-open)
  /// - User has premium or should-grant-access subscription
  /// - User still has remaining trial scans and time
  static Future<bool> shouldBlockScan([BuildContext? context]) async {
    // Ensure we are listening (failsafe if not called during boot)
    initialize();

    try {
      debugPrint('🛡️ TrialGateHelper: Checking trial status...');

      if (_cachedStatus == null) {
        debugPrint('🛡️ TrialGateHelper: State is NOT cached yet. Waiting for load...');
        
        final paymentBloc = ServiceLocator.get<PaymentBloc>();
        if (paymentBloc.state is! SubscriptionStatusLoaded) {
          debugPrint('🛡️ TrialGateHelper: PaymentBloc is currently: ${paymentBloc.state}. Triggering forceful load.');
          paymentBloc.add(LoadSubscriptionStatus());
          
          try {
            final state = await paymentBloc.stream.firstWhere(
              (state) => state is SubscriptionStatusLoaded || state is PaymentError,
            ).timeout(const Duration(seconds: 4));

            if (state is SubscriptionStatusLoaded) {
              _cachedStatus = state.status;
            } else {
               debugPrint('🛡️ TrialGateHelper: Payment Error or Timeout — fail open.');
               return false;
            }
          } catch (e) {
             debugPrint('🛡️ TrialGateHelper: Timeout waiting for state. Allowing scan (fail-open).');
             return false;
          }
        } else {
           _cachedStatus = (paymentBloc.state as SubscriptionStatusLoaded).status;
        }
      }

      final status = _cachedStatus!;
      
      final int usedScans = status.trialScansUsed ?? 0;
      final int maxScans = status.trialMaxScans ?? 5;
      final bool scansExceeded = usedScans >= maxScans;
      final bool timeExpired = status.isTrialExpired ?? false;

      debugPrint('🛡️ TrialGateHelper: usedScans: $usedScans / $maxScans (Exceeded: $scansExceeded)');
      debugPrint('🛡️ TrialGateHelper: isTrialExpired: $timeExpired');

      // If user has a fully paid premium subscription, never block
      if (status.hasPremium) {
        debugPrint('🛡️ TrialGateHelper: User has premium paid plan. Allowing scan.');
        return false;
      }

      // User is on a free plan, so enforce the trial restrictions.
      final shouldBlock = scansExceeded || timeExpired;
      debugPrint('🛡️ TrialGateHelper: Final Verdict - Block: $shouldBlock');
      
      return shouldBlock;
    } catch (e) {
      debugPrint('⚠️ TrialGateHelper: Error checking status ($e) — allowing scan');
      return false;
    }
  }

  /// Shows the trial-expired bottom sheet explaining why the user can't scan.
  static void showTrialExpiredSheet(BuildContext context) {
    if (!context.mounted) return;
    
    final String reason = _getBlockReason();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrialExpiredBottomSheet(reason: reason),
    );
  }

  static String _getBlockReason() {
    if (_cachedStatus != null) {
      final status = _cachedStatus!;
      final bool scansExceeded =
          (status.trialScansUsed ?? 0) >= (status.trialMaxScans ?? 5);
      final bool timeExpired = status.isTrialExpired ?? false;

      if (scansExceeded && timeExpired) {
        return 'You\'ve used all ${status.trialMaxScans ?? 5} free scans and your 6-month trial period has ended.';
      } else if (scansExceeded) {
        return 'You\'ve used all ${status.trialMaxScans ?? 5} free scans included in your trial.';
      } else if (timeExpired) {
        return 'Your 6-month free trial period has ended.';
      }
    }
    return 'Your free trial has ended.';
  }
}

