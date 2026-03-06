import '../../../domain/payments/entities/subscription_status.dart';

class SubscriptionStatusModel extends SubscriptionStatus {
  const SubscriptionStatusModel({
    required super.hasPremium,
    required super.plan,
    required super.status,
    required super.interval,
    required super.currentPeriodEnd,
    required super.cancelAtPeriodEnd,
    super.gracePeriodEnd,
    super.isInGracePeriod,
    super.isInBillingRetry,
    super.trialScansUsed,
    super.trialMaxScans,
    super.trialExpiresAt,
    super.isTrialExpired,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    // Parse grace period end if present
    DateTime? gracePeriodEnd;
    if (json['grace_period_end'] != null) {
      gracePeriodEnd = DateTime.tryParse(json['grace_period_end'] as String);
    }

    // Determine grace period status from various possible API responses
    final status = (json['status'] as String?)?.toLowerCase() ?? '';
    final isInGracePeriod = json['is_in_grace_period'] == true ||
        json['in_grace_period'] == true ||
        status == 'in_grace_period' ||
        status == 'grace_period';

    final isInBillingRetry = json['is_in_billing_retry'] == true ||
        json['billing_retry'] == true ||
        status == 'billing_retry' ||
        status == 'past_due';

    return SubscriptionStatusModel(
      hasPremium: json['has_premium'] as bool? ?? false,
      plan: json['plan'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      interval: json['interval'] as String? ?? '',
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : DateTime.now(),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      gracePeriodEnd: gracePeriodEnd,
      isInGracePeriod: isInGracePeriod,
      isInBillingRetry: isInBillingRetry,
      trialScansUsed: json['trial_scans_used'] as int?,
      trialMaxScans: json['trial_max_scans'] as int?,
      trialExpiresAt: json['trial_expires_at'] != null 
          ? DateTime.tryParse(json['trial_expires_at'] as String)
          : null,
      isTrialExpired: json['is_trial_expired'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_premium': hasPremium,
      'plan': plan,
      'status': status,
      'interval': interval,
      'current_period_end': currentPeriodEnd.toIso8601String(),
      'cancel_at_period_end': cancelAtPeriodEnd,
      'grace_period_end': gracePeriodEnd?.toIso8601String(),
      'is_in_grace_period': isInGracePeriod,
      'is_in_billing_retry': isInBillingRetry,
      if (trialScansUsed != null) 'trial_scans_used': trialScansUsed,
      if (trialMaxScans != null) 'trial_max_scans': trialMaxScans,
      if (trialExpiresAt != null) 'trial_expires_at': trialExpiresAt?.toIso8601String(),
      if (isTrialExpired != null) 'is_trial_expired': isTrialExpired,
    };
  }
}