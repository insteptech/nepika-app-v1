import '../../../domain/payments/entities/subscription_details.dart';

class SubscriptionDetailsModel extends SubscriptionDetails {
  const SubscriptionDetailsModel({
    required super.id,
    required super.userId,
    required super.plan,
    required super.interval,
    required super.status,
    super.stripeCustomerId,
    super.stripeSubscriptionId,
    required super.currentPeriodStart,
    required super.currentPeriodEnd,
    required super.cancelAtPeriodEnd,
    super.canceledAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SubscriptionDetailsModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetailsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plan: json['plan'] as String,
      interval: json['interval'] as String,
      status: json['status'] as String,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      currentPeriodStart: DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool,
      canceledAt: json['canceled_at'] != null 
        ? DateTime.parse(json['canceled_at'] as String) 
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan': plan,
      'interval': interval,
      'status': status,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'current_period_start': currentPeriodStart.toIso8601String(),
      'current_period_end': currentPeriodEnd.toIso8601String(),
      'cancel_at_period_end': cancelAtPeriodEnd,
      'canceled_at': canceledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}