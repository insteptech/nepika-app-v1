import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentPlans extends PaymentEvent {}

class LoadStripeConfig extends PaymentEvent {}

class CreateCheckoutSessionEvent extends PaymentEvent {
  final String priceId;
  final String interval;

  const CreateCheckoutSessionEvent({
    required this.priceId,
    required this.interval,
  });

  @override
  List<Object?> get props => [priceId, interval];
}

class LoadSubscriptionStatus extends PaymentEvent {}

class LoadSubscriptionDetails extends PaymentEvent {}

class CancelSubscriptionEvent extends PaymentEvent {
  final bool cancelImmediately;

  const CancelSubscriptionEvent({this.cancelImmediately = false});

  @override
  List<Object?> get props => [cancelImmediately];
}

class ReactivateSubscriptionEvent extends PaymentEvent {}