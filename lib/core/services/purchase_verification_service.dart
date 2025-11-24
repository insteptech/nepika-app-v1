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
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    try {
      debugPrint('Verifying purchase: ${purchase.productID}');
      
      final Map<String, dynamic> verificationData = {
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'verification_data': purchase.verificationData.serverVerificationData,
        'source': purchase.verificationData.source,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'transaction_date': purchase.transactionDate,
        'status': purchase.status.toString(),
      };

      // Add platform-specific verification data
      if (Platform.isIOS) {
        verificationData['receipt_data'] = purchase.verificationData.serverVerificationData;
      } else {
        verificationData['purchase_token'] = purchase.verificationData.serverVerificationData;
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

  /// Restore purchases and sync with server
  Future<bool> restorePurchases(List<PurchaseDetails> purchases) async {
    try {
      debugPrint('Restoring ${purchases.length} purchases');
      
      final List<Map<String, dynamic>> purchaseData = purchases.map((purchase) => {
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'verification_data': purchase.verificationData.serverVerificationData,
        'source': purchase.verificationData.source,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'transaction_date': purchase.transactionDate,
        'status': purchase.status.toString(),
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
  Future<bool> updateSubscription(PurchaseDetails purchase) async {
    try {
      debugPrint('Updating subscription for: ${purchase.productID}');
      
      final Map<String, dynamic> subscriptionData = {
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'verification_data': purchase.verificationData.serverVerificationData,
        'transaction_date': purchase.transactionDate,
      };

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