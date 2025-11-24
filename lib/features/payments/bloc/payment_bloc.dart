import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/payments/usecases/get_payment_plans.dart';
import '../../../domain/payments/usecases/get_stripe_config.dart';
import '../../../domain/payments/usecases/create_checkout_session.dart';
import '../../../domain/payments/usecases/get_subscription_status.dart';
import '../../../domain/payments/usecases/get_subscription_details.dart';
import '../../../domain/payments/usecases/cancel_subscription.dart';
import '../../../domain/payments/usecases/reactivate_subscription.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart'  hide IAPError;
import 'package:nepika/features/payments/components/in_app_purchase_service.dart' ;
import 'payment_event.dart';
import 'payment_state.dart' ;
import 'dart:async';
 

class IAPBloc extends Bloc<IAPEvent, IAPState> {
  final IAPService _iapService;
  
  StreamSubscription<IAPStatus>? _statusSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  
  IAPBloc({IAPService? iapService}) 
      : _iapService = iapService ?? IAPService(),
        super(IAPInitial()) {
    
    on<InitializeIAP>(_onInitialize);
    on<LoadProducts>(_onLoadProducts);
    on<PurchaseProduct>(_onPurchaseProduct);
    on<PurchaseByInterval>(_onPurchaseByInterval);
    on<RestorePurchases>(_onRestorePurchases);
    on<IAPStatusChanged>(_onStatusChanged);
    on<IAPPurchaseCompleted>(_onPurchaseCompleted);
    on<IAPErrorOccurred>(_onErrorOccurred);
  }

  Future<void> _onInitialize(InitializeIAP event, Emitter<IAPState> emit) async {
    emit(IAPLoading(message: 'Initializing...'));
    
    // Subscribe to service streams
    _statusSubscription = _iapService.statusStream.listen((status) {
      add(IAPStatusChanged(status));
    });
    
    _errorSubscription = _iapService.errorStream.listen((error) {
      add(IAPErrorOccurred(error));
    });
    
    _purchaseSubscription = _iapService.purchaseStream.listen((purchase) {
      add(IAPPurchaseCompleted(purchase));
    });
    
    await _iapService.initialize();
    
    if (!_iapService.isAvailable) {
      emit(IAPNotAvailable());
      return;
    }
    
    emit(IAPProductsLoaded(
      products: _iapService.products,
      isAvailable: _iapService.isAvailable,
    ));
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<IAPState> emit) async {
    emit(IAPLoading(message: 'Loading products...'));
    await _iapService.loadProducts();
    
    emit(IAPProductsLoaded(
      products: _iapService.products,
      isAvailable: _iapService.isAvailable,
    ));
  }

  Future<void> _onPurchaseProduct(PurchaseProduct event, Emitter<IAPState> emit) async {
    emit(IAPLoading(message: 'Processing purchase...'));
    await _iapService.purchaseProduct(event.product);
  }

  Future<void> _onPurchaseByInterval(PurchaseByInterval event, Emitter<IAPState> emit) async {
    emit(IAPLoading(message: 'Processing purchase...'));
    final success = await _iapService.purchaseByPlanInterval(event.interval);
    
    if (!success) {
      emit(IAPProductsLoaded(
        products: _iapService.products,
        isAvailable: _iapService.isAvailable,
      ));
    }
  }

  Future<void> _onRestorePurchases(RestorePurchases event, Emitter<IAPState> emit) async {
    emit(IAPLoading(message: 'Restoring purchases...'));
    await _iapService.restorePurchases();
  }

  void _onStatusChanged(IAPStatusChanged event, Emitter<IAPState> emit) {
    switch (event.status) {
      case IAPStatus.idle:
        emit(IAPProductsLoaded(
          products: _iapService.products,
          isAvailable: _iapService.isAvailable,
        ));
        break;
      case IAPStatus.loading:
        emit(IAPLoading());
        break;
      case IAPStatus.pending:
        emit(IAPPurchasePending());
        break;
      case IAPStatus.purchased:
        // Handled by _onPurchaseCompleted
        break;
      case IAPStatus.restored:
        emit(IAPRestoreSuccess());
        break;
      case IAPStatus.failed:
        // Error message comes through error stream
        break;
      case IAPStatus.canceled:
        emit(IAPPurchaseCanceled());
        break;
    }
  }

  void _onPurchaseCompleted(IAPPurchaseCompleted event, Emitter<IAPState> emit) {
    emit(IAPPurchaseSuccess(event.purchaseDetails));
  }

  void _onErrorOccurred(IAPErrorOccurred event, Emitter<IAPState> emit) {
    emit(IAPError(event.message));
  }

  // Helper methods
  List<ProductDetails> get products => _iapService.products;
  bool get isAvailable => _iapService.isAvailable;

  ProductDetails? getProductByInterval(String interval) {
    return _iapService.getProductByInterval(interval);
  }

  /// Merge StoreKit products with server data
  /// Returns list of enriched products with real prices from Apple/Google
  List<Map<String, dynamic>> mergeWithServerData(List<dynamic> serverPlans) {
    return _iapService.mergeWithServerData(serverPlans);
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    _purchaseSubscription?.cancel();
    return super.close();
  }
}


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