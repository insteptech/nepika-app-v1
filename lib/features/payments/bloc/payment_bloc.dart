import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/payments/usecases/get_payment_plans.dart';
import '../../../domain/payments/usecases/get_stripe_config.dart';
import '../../../domain/payments/usecases/create_checkout_session.dart';
import '../../../domain/payments/usecases/get_subscription_status.dart';
import '../../../domain/payments/usecases/get_subscription_details.dart';
import '../../../domain/payments/usecases/cancel_subscription.dart';
import '../../../domain/payments/usecases/reactivate_subscription.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetPaymentPlans getPaymentPlans;
  final GetStripeConfig getStripeConfig;
  final CreateCheckoutSession createCheckoutSession;
  final GetSubscriptionStatus getSubscriptionStatus;
  final GetSubscriptionDetails getSubscriptionDetails;
  final CancelSubscription cancelSubscription;
  final ReactivateSubscription reactivateSubscription;

  PaymentBloc({
    required this.getPaymentPlans,
    required this.getStripeConfig,
    required this.createCheckoutSession,
    required this.getSubscriptionStatus,
    required this.getSubscriptionDetails,
    required this.cancelSubscription,
    required this.reactivateSubscription,
  }) : super(PaymentInitial()) {
    on<LoadPaymentPlans>(_onLoadPaymentPlans);
    on<LoadStripeConfig>(_onLoadStripeConfig);
    on<CreateCheckoutSessionEvent>(_onCreateCheckoutSession);
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<LoadSubscriptionDetails>(_onLoadSubscriptionDetails);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<ReactivateSubscriptionEvent>(_onReactivateSubscription);
  }

  Future<void> _onLoadPaymentPlans(
    LoadPaymentPlans event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final plansResponse = await getPaymentPlans();
      emit(PaymentPlansLoaded(plansResponse.plans));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadStripeConfig(
    LoadStripeConfig event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final config = await getStripeConfig();
      emit(StripeConfigLoaded(config));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onCreateCheckoutSession(
    CreateCheckoutSessionEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final session = await createCheckoutSession(
        priceId: event.priceId,
        interval: event.interval,
      );
      emit(CheckoutSessionCreated(session));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionStatus(
    LoadSubscriptionStatus event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final status = await getSubscriptionStatus();
      emit(SubscriptionStatusLoaded(status));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionDetails(
    LoadSubscriptionDetails event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final details = await getSubscriptionDetails();
      emit(SubscriptionDetailsLoaded(details));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final details = await cancelSubscription(
        cancelImmediately: event.cancelImmediately,
      );
      emit(SubscriptionCanceled(details));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onReactivateSubscription(
    ReactivateSubscriptionEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final details = await reactivateSubscription();
      emit(SubscriptionReactivated(details));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}