import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/config/constants/api_endpoints.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppRepository {
  final ApiBase apiBase;
  AppRepository(this.apiBase);

  Future<Map<String, dynamic>> fetchSubscriptionPlan({required String token});
  Future<Map<String, dynamic>?> getCachedSubscriptionPlan();
}

class AppRepositoryImpl extends AppRepository {
  AppRepositoryImpl(ApiBase apiBase) : super(apiBase);

  @override
  Future<Map<String, dynamic>?> getCachedSubscriptionPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_subscription_plan');
      if (cachedData != null) {
        return Map<String, dynamic>.from(jsonDecode(cachedData));
      }
    } catch (e) {
      debugPrint('Error reading cached subscription plan: $e');
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> fetchSubscriptionPlan({required String token}) async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.paymentPlans}',
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      logJson(response.data['data']);
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data['data']);
      
      // Cache the response
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_subscription_plan', jsonEncode(data));
      } catch (e) {
        debugPrint('Error caching subscription plan: $e');
      }
      
      return data;
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch dashboard data');
    }
  }
}