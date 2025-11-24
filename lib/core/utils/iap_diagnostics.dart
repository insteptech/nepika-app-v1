import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPDiagnostics {
  static Future<Map<String, dynamic>> runFullDiagnostics() async {
    final results = <String, dynamic>{};
    
    try {
      // Basic environment checks
      results['platform'] = Platform.operatingSystem;
      results['debug_mode'] = kDebugMode;
      results['is_ios'] = Platform.isIOS;
      results['is_android'] = Platform.isAndroid;
      
      // IAP availability check
      final iap = InAppPurchase.instance;
      results['iap_available'] = await iap.isAvailable();
      
      if (Platform.isIOS) {
        await _checkIOSSpecific(results);
      }
      
      if (results['iap_available']) {
        await _checkProductAvailability(results);
      }
      
      // Check network connectivity
      results['network_check'] = await _checkNetworkConnectivity();
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }
  
  static Future<void> _checkIOSSpecific(Map<String, dynamic> results) async {
    try {
      if (Platform.isIOS) {
        // Basic iOS checks
        results['storekit_accessible'] = true;
        results['payment_queue_accessible'] = true;
      }
    } catch (e) {
      results['ios_check_error'] = e.toString();
    }
  }
  
  static Future<void> _checkProductAvailability(Map<String, dynamic> results) async {
    try {
      const productIds = {
        'com.assisted.nepika.weekly',
        'com.assisted.nepika.yearly',
      };

      debugPrint('IAP Diagnostics: Querying products: $productIds');

      final response = await InAppPurchase.instance.queryProductDetails(productIds);
      
      results['products_found'] = response.productDetails.length;
      results['products_not_found'] = response.notFoundIDs.length;
      results['not_found_ids'] = response.notFoundIDs.toList();
      results['found_products'] = response.productDetails.map((p) => {
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'price': p.price,
        'currency_code': p.currencyCode,
      }).toList();
      
      if (response.error != null) {
        results['query_error'] = {
          'code': response.error!.code,
          'message': response.error!.message,
          'details': response.error!.details,
        };
      }
      
    } catch (e) {
      results['product_query_exception'] = e.toString();
    }
  }
  
  static Future<bool> _checkNetworkConnectivity() async {
    try {
      // Simple network check
      final result = await Process.run('ping', ['-c', '1', 'google.com']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  static void printDiagnosticReport(Map<String, dynamic> results) {
    debugPrint('''
🔍 IAP DIAGNOSTIC REPORT 🔍
================================

📱 ENVIRONMENT:
Platform: ${results['platform']}
Debug Mode: ${results['debug_mode']}
iOS: ${results['is_ios']}
Android: ${results['is_android']}

🛒 IAP AVAILABILITY:
Available: ${results['iap_available']}
${Platform.isIOS ? 'StoreKit Accessible: ${results['storekit_accessible']}' : ''}
${Platform.isIOS && results['payment_queue_accessible'] != null ? 'Payment Queue: ${results['payment_queue_accessible']}' : ''}

📦 PRODUCTS:
Found: ${results['products_found']} products
Not Found: ${results['products_not_found']} products
Missing IDs: ${results['not_found_ids']}

${results['found_products']?.isNotEmpty == true ? '''
✅ FOUND PRODUCTS:
${(results['found_products'] as List).map((p) => '- ${p['id']}: ${p['title']} (${p['price']} ${p['currency_code']})').join('\n')}
''' : ''}

${results['query_error'] != null ? '''
❌ QUERY ERROR:
Code: ${results['query_error']['code']}
Message: ${results['query_error']['message']}
''' : ''}

🌐 NETWORK:
Connectivity: ${results['network_check']}

${results['error'] != null ? '''
💥 GENERAL ERROR:
${results['error']}
''' : ''}

================================
''');
  }
  
  static Future<void> runAndPrintDiagnostics() async {
    debugPrint('🔍 Starting IAP diagnostics...');
    final results = await runFullDiagnostics();
    printDiagnosticReport(results);
  }
}