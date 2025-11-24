import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:equatable/equatable.dart';
// Import IAPStatus from service - single source of truth
import 'package:nepika/features/payments/components/in_app_purchase_service.dart';

// ==================== Payment Events (Stripe) ====================

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


// ==================== IAP Events ====================

abstract class IAPEvent {}

class InitializeIAP extends IAPEvent {}

class LoadProducts extends IAPEvent {}

class PurchaseProduct extends IAPEvent {
  final ProductDetails product;
  PurchaseProduct(this.product);
}

class PurchaseByInterval extends IAPEvent {
  final String interval; // 'monthly' or 'yearly'
  PurchaseByInterval(this.interval);
}

class RestorePurchases extends IAPEvent {}

// Use IAPStatus from in_app_purchase_service.dart
class IAPStatusChanged extends IAPEvent {
  final IAPStatus status;
  IAPStatusChanged(this.status);
}

class IAPPurchaseCompleted extends IAPEvent {
  final PurchaseDetails purchaseDetails;
  IAPPurchaseCompleted(this.purchaseDetails);
}

class IAPErrorOccurred extends IAPEvent {
  final String message;
  IAPErrorOccurred(this.message);
}

// REMOVED: enum IAPStatus - now imported from in_app_purchase_service.dart