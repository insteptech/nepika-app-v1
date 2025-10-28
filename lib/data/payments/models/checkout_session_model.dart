import '../../../domain/payments/entities/checkout_session.dart';

class CheckoutSessionModel extends CheckoutSession {
  const CheckoutSessionModel({
    required super.sessionId,
    required super.url,
    required super.publishableKey,
  });

  factory CheckoutSessionModel.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionModel(
      sessionId: json['session_id'] as String,
      url: json['url'] as String,
      publishableKey: json['publishable_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'url': url,
      'publishable_key': publishableKey,
    };
  }
}