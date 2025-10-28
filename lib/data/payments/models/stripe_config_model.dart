import '../../../domain/payments/entities/stripe_config.dart';

class StripeConfigModel extends StripeConfig {
  const StripeConfigModel({
    required super.publishableKey,
    required super.monthlyPriceId,
    required super.yearlyPriceId,
    required super.monthlyPrice,
    required super.yearlyPrice,
  });

  factory StripeConfigModel.fromJson(Map<String, dynamic> json) {
    return StripeConfigModel(
      publishableKey: json['publishable_key'] as String,
      monthlyPriceId: json['monthly_price_id'] as String,
      yearlyPriceId: json['yearly_price_id'] as String,
      monthlyPrice: json['monthly_price'] as String,
      yearlyPrice: json['yearly_price'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publishable_key': publishableKey,
      'monthly_price_id': monthlyPriceId,
      'yearly_price_id': yearlyPriceId,
      'monthly_price': monthlyPrice,
      'yearly_price': yearlyPrice,
    };
  }
}