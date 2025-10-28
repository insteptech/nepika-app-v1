import '../entities/payment_plans_response.dart';
import '../entities/checkout_session.dart';
import '../entities/subscription_status.dart';
import '../entities/subscription_details.dart';
import '../entities/stripe_config.dart';

abstract class PaymentsRepository {
  Future<PaymentPlansResponse> getPaymentPlans();
  Future<StripeConfig> getStripeConfig();
  Future<CheckoutSession> createCheckoutSession({
    required String priceId,
    required String interval,
  });
  Future<SubscriptionStatus> getSubscriptionStatus();
  Future<SubscriptionDetails> getSubscriptionDetails();
  Future<SubscriptionDetails> cancelSubscription({bool cancelImmediately = false});
  Future<SubscriptionDetails> reactivateSubscription();
}