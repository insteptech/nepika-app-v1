import '../../../domain/payments/entities/subscription_status.dart';

class SubscriptionStatusModel extends SubscriptionStatus {
  const SubscriptionStatusModel({
    required super.hasPremium,
    required super.plan,
    required super.status,
    required super.interval,
    required super.currentPeriodEnd,
    required super.cancelAtPeriodEnd,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      hasPremium: json['has_premium'] as bool,
      plan: json['plan'] as String,
      status: json['status'] as String,
      interval: json['interval'] as String,
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool,
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
    };
  }
}