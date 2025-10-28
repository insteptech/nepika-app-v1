import 'package:equatable/equatable.dart';

class SubscriptionDetails extends Equatable {
  final String id;
  final String userId;
  final String plan;
  final String interval;
  final String status;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionDetails({
    required this.id,
    required this.userId,
    required this.plan,
    required this.interval,
    required this.status,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.canceledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        plan,
        interval,
        status,
        stripeCustomerId,
        stripeSubscriptionId,
        currentPeriodStart,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        canceledAt,
        createdAt,
        updatedAt,
      ];
}