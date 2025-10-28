import 'package:equatable/equatable.dart';

class SubscriptionStatus extends Equatable {
  final bool hasPremium;
  final String plan;
  final String status;
  final String interval;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  const SubscriptionStatus({
    required this.hasPremium,
    required this.plan,
    required this.status,
    required this.interval,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  @override
  List<Object?> get props => [
        hasPremium,
        plan,
        status,
        interval,
        currentPeriodEnd,
        cancelAtPeriodEnd,
      ];
}