import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../domain/payments/entities/payment_plan.dart';
import '../../../domain/payments/entities/checkout_session.dart';
import '../../../domain/payments/entities/subscription_status.dart';
import '../../../domain/payments/entities/subscription_details.dart';
import '../../../domain/payments/entities/stripe_config.dart';

// ==================== IAP States ====================

abstract class IAPState {}

class IAPInitial extends IAPState {}

class IAPLoading extends IAPState {
  final String? message;
  IAPLoading({this.message});
}

class IAPProductsLoaded extends IAPState {
  final List<ProductDetails> products;
  final bool isAvailable;
  IAPProductsLoaded({required this.products, required this.isAvailable});
}

class IAPPurchasePending extends IAPState {
  final String? productId;
  IAPPurchasePending({this.productId});
}

class IAPPurchaseSuccess extends IAPState {
  final PurchaseDetails purchaseDetails;
  IAPPurchaseSuccess(this.purchaseDetails);
}

class IAPRestoreSuccess extends IAPState {
  final PurchaseDetails? purchaseDetails;
  IAPRestoreSuccess({this.purchaseDetails});
}

class IAPPurchaseCanceled extends IAPState {}

class IAPError extends IAPState {
  final String message;
  IAPError(this.message);
}

class IAPNotAvailable extends IAPState {
  final String message;
  IAPNotAvailable({this.message = 'In-app purchases are not available'});
}


// ==================== Payment States (Stripe) ====================

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