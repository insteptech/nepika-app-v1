import '../../../core/api_base.dart';
import '../../../core/config/env.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../models/payment_plans_response_model.dart';
import '../models/checkout_session_model.dart';
import '../models/subscription_status_model.dart';
import '../models/subscription_details_model.dart';
import '../models/stripe_config_model.dart';

abstract class PaymentsRemoteDataSource {
  Future<PaymentPlansResponseModel> getPaymentPlans();
  Future<StripeConfigModel> getStripeConfig();
  Future<CheckoutSessionModel> createCheckoutSession({
    required String priceId,
    required String interval,
  });
  Future<SubscriptionStatusModel> getSubscriptionStatus();
  Future<SubscriptionDetailsModel> getSubscriptionDetails();
  Future<SubscriptionDetailsModel> cancelSubscription({bool cancelImmediately = false});
  Future<SubscriptionDetailsModel> reactivateSubscription();
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final ApiBase apiBase;

  PaymentsRemoteDataSourceImpl(this.apiBase);

  @override
  Future<PaymentPlansResponseModel> getPaymentPlans() async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.paymentPlans}',
      method: 'GET',
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return PaymentPlansResponseModel.fromJson(response.data);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch payment plans');
    }
  }

  @override
  Future<StripeConfigModel> getStripeConfig() async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.stripeConfig}',
      method: 'GET',
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return StripeConfigModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch Stripe config');
    }
  }

  @override
  Future<CheckoutSessionModel> createCheckoutSession({
    required String priceId,
    required String interval,
  }) async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.createCheckoutSession}',
      method: 'POST',
      body: {
        'price_id': priceId,
        'interval': interval,
      },
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return CheckoutSessionModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to create checkout session');
    }
  }

  @override
  Future<SubscriptionStatusModel> getSubscriptionStatus() async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.subscriptionStatus}',
      method: 'GET',
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return SubscriptionStatusModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch subscription status');
    }
  }

  @override
  Future<SubscriptionDetailsModel> getSubscriptionDetails() async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.subscriptionDetails}',
      method: 'GET',
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return SubscriptionDetailsModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch subscription details');
    }
  }

  @override
  Future<SubscriptionDetailsModel> cancelSubscription({bool cancelImmediately = false}) async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.cancelSubscription}',
      method: 'POST',
      body: {'cancel_immediately': cancelImmediately},
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return SubscriptionDetailsModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to cancel subscription');
    }
  }

  @override
  Future<SubscriptionDetailsModel> reactivateSubscription() async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.reactivateSubscription}',
      method: 'POST',
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return SubscriptionDetailsModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to reactivate subscription');
    }
  }
}