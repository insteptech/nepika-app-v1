// ==================== FILE 1: in_app_purchase_service.dart ====================
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../../core/services/purchase_verification_service.dart';
import '../../../core/utils/iap_diagnostics.dart';

// Keep IAPStatus here as the single source of truth
enum IAPStatus { idle, loading, purchased, failed, restored, pending, canceled }

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  final _statusController = StreamController<IAPStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();
  
  Stream<IAPStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;
  
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // MOCK MODE FLAG
  bool _isMockMode = false;

  static const Set<String> _productIds = {
    'com.assisted.nepika.weekly',
    'com.assisted.nepika.yearly',
  };

  static const Map<String, String> planToProductId = {
    'weekly': 'com.assisted.nepika.weekly',
    'yearly': 'com.assisted.nepika.yearly',
    'week': 'com.assisted.nepika.weekly',
    'year': 'com.assisted.nepika.yearly',
  };

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _statusController.add(IAPStatus.loading);

    try {
      // Add timeout to isAvailable check
      _isAvailable = await _iap.isAvailable().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('IAP: isAvailable timeout');
          return false;
        },
      );
      
      if (!_isAvailable) {
        debugPrint('IAP: Store not available');
        _errorController.add('In-app purchases are not available on this device');
        _statusController.add(IAPStatus.failed);
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => _errorController.add(error.toString()),
      );

      if (Platform.isIOS) {
        final iosPlatformAddition = _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
      }

      await loadProducts();
      _isInitialized = true;
    } catch (e) {
      debugPrint('IAP: Initialization failed: $e');
      _errorController.add('Failed to initialize IAP: $e');
      _statusController.add(IAPStatus.failed);
    }
  }

  // Removed _enableMockMode and _loadMockProducts as user requested real data only.

  Future<void> loadProducts({int retryCount = 0}) async {
    if (!_isAvailable) return;

    try {
      debugPrint('IAP: Loading products $_productIds (attempt ${retryCount + 1})');

      // Add a small delay before retry to let StoreKit settle
      if (retryCount > 0) {
        await Future.delayed(Duration(seconds: retryCount * 2));
      }

      final response = await _iap.queryProductDetails(_productIds).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Product loading timed out after 15 seconds');
        },
      );

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: Products not found: ${response.notFoundIDs}');
        debugPrint('IAP: Make sure these product IDs exist in App Store Connect and are approved');
      }

      if (response.error != null) {
        debugPrint('IAP: Product query error: ${response.error!.message}');
        debugPrint('IAP: Error code: ${response.error!.code}');

        // Retry on StoreKit errors
        if (retryCount < 3 && _shouldRetry(response.error!)) {
          debugPrint('IAP: Retrying product load...');
          return await loadProducts(retryCount: retryCount + 1);
        }

        _errorController.add('Error loading products: ${response.error!.message}');
        _statusController.add(IAPStatus.failed);
        return;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('IAP: No products found. Running diagnostics...');
        await IAPDiagnostics.runAndPrintDiagnostics();

        // Retry if no products found
        if (retryCount < 3) {
          debugPrint('IAP: Retrying product load...');
          return await loadProducts(retryCount: retryCount + 1);
        }
      }

      _products = response.productDetails;
      debugPrint('IAP: Successfully loaded ${_products.length} products');
      for (final product in _products) {
        debugPrint('IAP: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}');
      }
      _statusController.add(IAPStatus.idle);
    } catch (e) {
      debugPrint('IAP: Failed to load products: $e');

      // Retry on exception
      if (retryCount < 3) {
        debugPrint('IAP: Retrying product load after error...');
        return await loadProducts(retryCount: retryCount + 1);
      }

      _errorController.add('Failed to load products: $e');
      _statusController.add(IAPStatus.failed);
    }
  }

  bool _shouldRetry(IAPError error) {
    // Retry on StoreKit communication errors
    final retryableCodes = [
      'storekit_no_response',
      'storekit_duplicate_product_object',
      'unknown',
    ];

    return retryableCodes.any((code) =>
      error.code.toLowerCase().contains(code) ||
      error.message.toLowerCase().contains('storekit') ||
      error.message.toLowerCase().contains('response')
    );
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      _errorController.add('Store not available');
      return false;
    }

    _statusController.add(IAPStatus.loading);

    try {
      late PurchaseParam purchaseParam;
      
      if (Platform.isAndroid) {
        purchaseParam = GooglePlayPurchaseParam(productDetails: product);
      } else {
        purchaseParam = PurchaseParam(productDetails: product);
      }
      
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        _statusController.add(IAPStatus.failed);
        _errorController.add('Purchase initiation failed');
      }
      
      return success;
    } catch (e) {
      _errorController.add('Purchase failed: $e');
      _statusController.add(IAPStatus.failed);
      return false;
    }
  }

  Future<bool> purchaseByPlanInterval(String interval) async {
    final normalizedInterval = interval.toLowerCase();
    final productId = planToProductId[normalizedInterval];
    
    if (productId == null) {
      _errorController.add('Unknown plan interval: $interval');
      return false;
    }
    
    final product = getProductById(productId);
    if (product == null) {
      debugPrint('IAP: Product not found: $productId');
      debugPrint('IAP: Available products: ${_products.map((p) => p.id).toList()}');
      _errorController.add('Product not found: $productId');
      return false;
    }
    
    return purchaseProduct(product);
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _statusController.add(IAPStatus.pending);
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final valid = await _verifyPurchase(purchase);
          
          if (valid) {
            await _deliverProduct(purchase);
            _statusController.add(
              purchase.status == PurchaseStatus.restored 
                ? IAPStatus.restored 
                : IAPStatus.purchased
            );
            _purchaseController.add(purchase);
          } else {
            _errorController.add('Purchase verification failed');
            _statusController.add(IAPStatus.failed);
          }
          
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
          
        case PurchaseStatus.error:
          _handlePurchaseError(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
          
        case PurchaseStatus.canceled:
          _statusController.add(IAPStatus.canceled);
          break;
      }
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    final error = purchase.error;
    String errorMessage = 'Purchase failed';
    
    if (error != null) {
      if (Platform.isAndroid) {
        errorMessage = _getAndroidErrorMessage(error);
      } else if (Platform.isIOS) {
        errorMessage = _getIOSErrorMessage(error);
      } else {
        errorMessage = error.message;
      }
    }
    
    _errorController.add(errorMessage);
    _statusController.add(IAPStatus.failed);
  }

  String _getAndroidErrorMessage(IAPError error) {
    switch (error.code) {
      case 'USER_CANCELED': return 'Purchase was canceled';
      case 'ITEM_ALREADY_OWNED': return 'You already own this subscription';
      case 'BILLING_UNAVAILABLE': return 'Billing is not available';
      default: return error.message;
    }
  }

  String _getIOSErrorMessage(IAPError error) {
    switch (error.code) {
      case 'SKErrorPaymentCancelled': return 'Purchase was canceled';
      case 'SKErrorPaymentNotAllowed': return 'Purchases not allowed';
      default: return error.message;
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (_isMockMode) return true;
    
    final verificationService = PurchaseVerificationService();
    return await verificationService.verifyPurchase(purchase);
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    debugPrint('IAP: Delivering product ${purchase.productID}');
    
    final verificationService = PurchaseVerificationService();
    final success = await verificationService.updateSubscription(purchase);
    
    if (success) {
      debugPrint('IAP: Product delivered and subscription activated');
    } else {
      debugPrint('IAP: Failed to activate subscription on server');
    }
  }

  Future<void> restorePurchases() async {
    if (_isMockMode) {
      _statusController.add(IAPStatus.loading);
      await Future.delayed(const Duration(seconds: 1));
      _statusController.add(IAPStatus.restored);
      return;
    }

    if (!_isAvailable) {
      _errorController.add('Store not available');
      return;
    }
    _statusController.add(IAPStatus.loading);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorController.add('Failed to restore purchases: $e');
      _statusController.add(IAPStatus.failed);
    }
  }

  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  ProductDetails? getProductByInterval(String interval) {
    final productId = planToProductId[interval.toLowerCase()];
    if (productId == null) return null;
    return getProductById(productId);
  }

  /// Merge StoreKit/Google Play products with server data
  /// Returns list of maps for backward compatibility
  List<Map<String, dynamic>> mergeWithServerData(List<dynamic> serverPlans) {
    if (_products.isEmpty) {
      // Fallback: Return server data if StoreKit products not loaded
      debugPrint('IAP: No StoreKit products loaded, falling back to server data');
      return serverPlans.map((plan) => plan as Map<String, dynamic>).toList();
    }

    final enrichedProducts = <Map<String, dynamic>>[];

    for (final storeProduct in _products) {
      // Find matching server plan by product ID
      final serverPlan = serverPlans.firstWhere(
        (plan) => plan['id'] == storeProduct.id,
        orElse: () => null,
      );

      enrichedProducts.add({
        'id': storeProduct.id,
        'name': serverPlan?['name'] ?? storeProduct.title,
        'price': storeProduct.rawPrice, // Numeric value
        'priceDisplay': storeProduct.price, // ✅ Localized price from StoreKit
        'billingPeriod': _extractBillingPeriod(serverPlan),
        'stripe_price_id': serverPlan?['stripe_price_id'] ?? '',
        'description': serverPlan?['description'] ?? '',
        'features': serverPlan?['features'] ?? [],
        'currencyCode': storeProduct.currencyCode,
        'currencySymbol': storeProduct.currencySymbol,
      });
    }

    debugPrint('IAP: Merged ${enrichedProducts.length} products with StoreKit data');
    return enrichedProducts;
  }

  String _extractBillingPeriod(dynamic serverPlan) {
    if (serverPlan == null) return '';

    final interval = serverPlan['interval']?.toString() ?? '';
    if (interval.isNotEmpty) return interval;

    final duration = serverPlan['duration']?.toString() ?? '';
    return duration;
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _errorController.close();
    _purchaseController.close();
    _isInitialized = false;
  }
}

class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) => true;
  @override
  bool shouldShowPriceConsent() => true;
}