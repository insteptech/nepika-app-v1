import '../../../domain/payments/entities/payment_plans_response.dart';
import 'payment_plan_model.dart';

class PaymentPlansResponseModel extends PaymentPlansResponse {
  const PaymentPlansResponseModel({
    required super.plans,
    required super.total,
  });

  factory PaymentPlansResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final plansData = data['plans'] as List<dynamic>? ?? [];
    
    return PaymentPlansResponseModel(
      plans: plansData
          .map((plan) => PaymentPlanModel.fromJson(plan as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'plans': plans.map((plan) => (plan as PaymentPlanModel).toJson()).toList(),
        'total': total,
      },
    };
  }
}