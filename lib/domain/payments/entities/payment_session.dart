import 'package:equatable/equatable.dart';

class PaymentSession extends Equatable {
  final String clientSecret;
  final String paymentIntentId;
  final String planId;
  final double amount;
  final String currency;

  const PaymentSession({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.planId,
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [
        clientSecret,
        paymentIntentId,
        planId,
        amount,
        currency,
      ];
}