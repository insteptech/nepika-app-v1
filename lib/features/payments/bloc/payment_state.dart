import 'package:equatable/equatable.dart';
import '../../../domain/payments/entities/payment_plan.dart';
import '../../../domain/payments/entities/checkout_session.dart';
import '../../../domain/payments/entities/subscription_status.dart';
import '../../../domain/payments/entities/subscription_details.dart';
import '../../../domain/payments/entities/stripe_config.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentPlansLoaded extends PaymentState {
  final List<PaymentPlan> plans;

  const PaymentPlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

class StripeConfigLoaded extends PaymentState {
  final StripeConfig config;

  const StripeConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

class CheckoutSessionCreated extends PaymentState {
  final CheckoutSession session;

  const CheckoutSessionCreated(this.session);

  @override
  List<Object?> get props => [session];
}

class SubscriptionStatusLoaded extends PaymentState {
  final SubscriptionStatus status;

  const SubscriptionStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class SubscriptionDetailsLoaded extends PaymentState {
  final SubscriptionDetails details;

  const SubscriptionDetailsLoaded(this.details);

  @override
  List<Object?> get props => [details];
}

class SubscriptionCanceled extends PaymentState {
  final SubscriptionDetails details;

  const SubscriptionCanceled(this.details);

  @override
  List<Object?> get props => [details];
}

class SubscriptionReactivated extends PaymentState {
  final SubscriptionDetails details;

  const SubscriptionReactivated(this.details);

  @override
  List<Object?> get props => [details];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}