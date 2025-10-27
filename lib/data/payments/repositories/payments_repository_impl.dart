import '../../../domain/payments/entities/payment_plans_response.dart';
import '../../../domain/payments/entities/checkout_session.dart';
import '../../../domain/payments/entities/subscription_status.dart';
import '../../../domain/payments/entities/subscription_details.dart';
import '../../../domain/payments/entities/stripe_config.dart';
import '../../../domain/payments/repositories/payments_repository.dart';
import '../datasources/payments_remote_datasource.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource remoteDataSource;

  PaymentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaymentPlansResponse> getPaymentPlans() async {
    return await remoteDataSource.getPaymentPlans();
  }

  @override
  Future<StripeConfig> getStripeConfig() async {
    return await remoteDataSource.getStripeConfig();
  }

  @override
  Future<CheckoutSession> createCheckoutSession({
    required String priceId,
    required String interval,
  }) async {
    return await remoteDataSource.createCheckoutSession(
      priceId: priceId,
      interval: interval,
    );
  }

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return await remoteDataSource.getSubscriptionStatus();
  }

  @override
  Future<SubscriptionDetails> getSubscriptionDetails() async {
    return await remoteDataSource.getSubscriptionDetails();
  }

  @override
  Future<SubscriptionDetails> cancelSubscription({bool cancelImmediately = false}) async {
    return await remoteDataSource.cancelSubscription(cancelImmediately: cancelImmediately);
  }

  @override
  Future<SubscriptionDetails> reactivateSubscription() async {
    return await remoteDataSource.reactivateSubscription();
  }
}