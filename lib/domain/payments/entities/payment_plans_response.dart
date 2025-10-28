import 'package:equatable/equatable.dart';
import 'payment_plan.dart';

class PaymentPlansResponse extends Equatable {
  final List<PaymentPlan> plans;
  final int total;

  const PaymentPlansResponse({
    required this.plans,
    required this.total,
  });

  @override
  List<Object?> get props => [plans, total];
}