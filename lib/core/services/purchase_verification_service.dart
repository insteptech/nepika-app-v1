import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../api_base.dart';

class PurchaseVerificationService {
  static final PurchaseVerificationService _instance = PurchaseVerificationService._internal();
  factory PurchaseVerificationService() => _instance;
  PurchaseVerificationService._internal();

  final ApiBase _apiBase = ApiBase();

  /// Verify purchase with backend server
  /// Supports both StoreKit 1 (legacy receipt) and StoreKit 2 (JWS transaction)
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    try {
      debugPrint('Verifying purchase: ${purchase.productID}');
      debugPrint('Verification source: ${purchase.verificationData.source}');

      final Map<String, dynamic> verificationData = {
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'transaction_date': purchase.transactionDate,
        'status': purchase.status.toString(),
      };

      // Handle platform-specific verification data
      if (Platform.isIOS) {
        // StoreKit 2 uses 'app_store' source and provides JWS transaction data
        // StoreKit 1 uses 'app_store' source but provides base64 receipt
        final isStoreKit2 = _isStoreKit2Transaction(purchase);

        if (isStoreKit2) {
          // StoreKit 2: serverVerificationData contains JWS signed transaction
          verificationData['storekit_version'] = 2;
          verificationData['signed_transaction'] = purchase.verificationData.serverVerificationData;
          // localVerificationData may contain additional transaction info for debugging
          verificationData['local_verification_data'] = purchase.verificationData.localVerificationData;
          debugPrint('IAP: Using StoreKit 2 JWS verification');
        } else {
          // StoreKit 1: serverVerificationData contains base64 receipt
          verificationData['storekit_version'] = 1;
          verificationData['receipt_data'] = purchase.verificationData.serverVerificationData;
          debugPrint('IAP: Using StoreKit 1 receipt verification');
        }
      } else {
        // Android: Google Play purchase token
        verificationData['purchase_token'] = purchase.verificationData.serverVerificationData;
        verificationData['local_verification_data'] = purchase.verificationData.localVerificationData;
      }

      final response = await _apiBase.request(
        path: '/payments/verify-purchase',
        method: 'POST',
        body: verificationData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          debugPrint('Purchase verification successful');
          return true;
        } else {
          debugPrint('Purchase verification failed: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('Purchase verification failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Purchase verification error: $e');
      return false;
    }
  }

  /// Detect if this is a StoreKit 2 transaction
  /// StoreKit 2 JWS tokens start with 'eyJ' (base64 encoded JSON header)
  bool _isStoreKit2Transaction(PurchaseDetails purchase) {
    final serverData = purchase.verificationData.serverVerificationData;
    // JWS format: header.payload.signature (three base64url parts separated by dots)
    // StoreKit 2 JWS always starts with eyJ (base64 of '{"')
    if (serverData.startsWith('eyJ') && serverData.contains('.')) {
      final parts = serverData.split('.');
      return parts.length == 3; // Valid JWS has exactly 3 parts
    }
    return false;
  }

  /// Restore purchases and sync with server
  /// Supports both StoreKit 1 and StoreKit 2 transactions
  Future<bool> restorePurchases(List<PurchaseDetails> purchases) async {
    try {
      debugPrint('Restoring ${purchases.length} purchases');

      final List<Map<String, dynamic>> purchaseData = purchases.map((purchase) {
        final isStoreKit2 = Platform.isIOS && _isStoreKit2Transaction(purchase);

        final data = <String, dynamic>{
          'product_id': purchase.productID,
          'purchase_id': purchase.purchaseID,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'transaction_date': purchase.transactionDate,
          'status': purchase.status.toString(),
        };

        if (Platform.isIOS) {
          data['storekit_version'] = isStoreKit2 ? 2 : 1;
          if (isStoreKit2) {
            data['signed_transaction'] = purchase.verificationData.serverVerificationData;
          } else {
            data['receipt_data'] = purchase.verificationData.serverVerificationData;
          }
        } else {
          data['purchase_token'] = purchase.verificationData.serverVerificationData;
        }

        return data;
      }).toList();

      final response = await _apiBase.request(
        path: '/payments/restore-purchases',
        method: 'POST',
        body: {'purchases': purchaseData},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          debugPrint('Purchase restoration successful');
          return true;
        } else {
          debugPrint('Purchase restoration failed: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('Purchase restoration failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Purchase restoration error: $e');
      return false;
    }
  }

  /// Check current subscription status from server
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final response = await _apiBase.request(
        path: '/payments/subscription/status',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get subscription status: $e');
      return null;
    }
  }

  /// Update subscription on server after successful purchase
  /// Supports both StoreKit 1 and StoreKit 2 transactions
  Future<bool> updateSubscription(PurchaseDetails purchase) async {
    try {
      debugPrint('Updating subscription for: ${purchase.productID}');

      final isStoreKit2 = Platform.isIOS && _isStoreKit2Transaction(purchase);

      final Map<String, dynamic> subscriptionData = {
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'transaction_date': purchase.transactionDate,
      };

      if (Platform.isIOS) {
        subscriptionData['storekit_version'] = isStoreKit2 ? 2 : 1;
        if (isStoreKit2) {
          subscriptionData['signed_transaction'] = purchase.verificationData.serverVerificationData;
          subscriptionData['local_verification_data'] = purchase.verificationData.localVerificationData;
        } else {
          subscriptionData['receipt_data'] = purchase.verificationData.serverVerificationData;
        }
      } else {
        subscriptionData['purchase_token'] = purchase.verificationData.serverVerificationData;
      }

      final response = await _apiBase.request(
        path: '/payments/subscription/activate',
        method: 'POST',
        body: subscriptionData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          debugPrint('Subscription update successful');
          return true;
        } else {
          debugPrint('Subscription update failed: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('Subscription update failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Subscription update error: $e');
      return false;
    }
  }
}