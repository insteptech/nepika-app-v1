import '../../../domain/payments/entities/payment_session.dart';

class PaymentSessionModel extends PaymentSession {
  const PaymentSessionModel({
    required super.clientSecret,
    required super.paymentIntentId,
    required super.planId,
    required super.amount,
    required super.currency,
  });

  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    return PaymentSessionModel(
      clientSecret: json['client_secret'] ?? '',
      paymentIntentId: json['payment_intent_id'] ?? '',
      planId: json['plan_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_secret': clientSecret,
      'payment_intent_id': paymentIntentId,
      'plan_id': planId,
      'amount': amount,
      'currency': currency,
    };
  }
}