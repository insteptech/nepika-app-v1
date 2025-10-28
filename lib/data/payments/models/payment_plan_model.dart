import '../../../domain/payments/entities/payment_plan.dart';

class PaymentPlanModel extends PaymentPlan {
  const PaymentPlanModel({
    required super.id,
    required super.name,
    required super.planCode,
    required super.duration,
    required super.price,
    required super.currency,
    required super.stripePriceId,
    required super.planDetails,
    required super.description,
    required super.isActive,
    required super.displayOrder,
  });

  factory PaymentPlanModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      planCode: json['plan_code'] ?? '',
      duration: json['duration'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? '',
      stripePriceId: json['stripe_price_id'] ?? '',
      planDetails: List<String>.from(json['plan_details'] ?? []),
      description: json['description'] ?? '',
      isActive: json['is_active'] == 'true' || json['is_active'] == true,
      displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plan_code': planCode,
      'duration': duration,
      'price': price,
      'currency': currency,
      'stripe_price_id': stripePriceId,
      'plan_details': planDetails,
      'description': description,
      'is_active': isActive.toString(),
      'display_order': displayOrder.toString(),
    };
  }
}