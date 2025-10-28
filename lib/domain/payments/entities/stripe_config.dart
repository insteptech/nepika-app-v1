import 'package:equatable/equatable.dart';

class StripeConfig extends Equatable {
  final String publishableKey;
  final String monthlyPriceId;
  final String yearlyPriceId;
  final String monthlyPrice;
  final String yearlyPrice;

  const StripeConfig({
    required this.publishableKey,
    required this.monthlyPriceId,
    required this.yearlyPriceId,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  @override
  List<Object?> get props => [
        publishableKey,
        monthlyPriceId,
        yearlyPriceId,
        monthlyPrice,
        yearlyPrice,
      ];
}