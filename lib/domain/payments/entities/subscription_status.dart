import 'package:equatable/equatable.dart';

/// Subscription status values aligned with Apple/Google billing states
enum SubscriptionState {
  /// Active and in good standing
  active,

  /// Payment failed, but user still has access (Apple's billing grace period)
  inGracePeriod,

  /// Billing retry in progress after grace period
  billingRetry,

  /// User cancelled, still has access until period end
  canceled,

  /// Subscription fully expired, no access
  expired,

  /// Refunded or revoked by store
  revoked,

  /// Free trial period
  trialing,

  /// Payment incomplete/pending
  incomplete,

  /// Past due payment
  pastDue,

  /// Unknown state
  unknown,
}

class SubscriptionStatus extends Equatable {
  final bool hasPremium;
  final String plan;
  final String status;
  final String interval;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? gracePeriodEnd;
  final bool isInGracePeriod;
  final bool isInBillingRetry;

  const SubscriptionStatus({
    required this.hasPremium,
    required this.plan,
    required this.status,
    required this.interval,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.gracePeriodEnd,
    this.isInGracePeriod = false,
    this.isInBillingRetry = false,
  });

  /// Parse status string to SubscriptionState enum
  SubscriptionState get state {
    final normalizedStatus = status.toLowerCase();

    if (isInGracePeriod) return SubscriptionState.inGracePeriod;
    if (isInBillingRetry) return SubscriptionState.billingRetry;

    switch (normalizedStatus) {
      case 'active':
        return SubscriptionState.active;
      case 'in_grace_period':
      case 'grace_period':
        return SubscriptionState.inGracePeriod;
      case 'billing_retry':
      case 'past_due':
        return SubscriptionState.billingRetry;
      case 'canceled':
      case 'cancelled':
        return SubscriptionState.canceled;
      case 'expired':
        return SubscriptionState.expired;
      case 'revoked':
        return SubscriptionState.revoked;
      case 'trialing':
      case 'trial':
        return SubscriptionState.trialing;
      case 'incomplete':
        return SubscriptionState.incomplete;
      case 'unpaid':
        return SubscriptionState.pastDue;
      default:
        return SubscriptionState.unknown;
    }
  }

  /// Whether user should have access to premium features
  /// Access is granted during: active, trialing, canceled (until period end),
  /// grace period, and billing retry
  bool get shouldGrantAccess {
    final currentState = state;
    return currentState == SubscriptionState.active ||
        currentState == SubscriptionState.trialing ||
        currentState == SubscriptionState.canceled ||
        currentState == SubscriptionState.inGracePeriod ||
        currentState == SubscriptionState.billingRetry;
  }

  /// Whether to show billing issue warning to user
  bool get hasBillingIssue {
    final currentState = state;
    return currentState == SubscriptionState.inGracePeriod ||
        currentState == SubscriptionState.billingRetry ||
        currentState == SubscriptionState.pastDue;
  }

  @override
  List<Object?> get props => [
        hasPremium,
        plan,
        status,
        interval,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        gracePeriodEnd,
        isInGracePeriod,
        isInBillingRetry,
      ];
}