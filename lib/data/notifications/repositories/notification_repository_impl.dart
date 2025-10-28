import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_base.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/api_endpoints.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiBase _apiBase;

  NotificationRepositoryImpl({
    ApiBase? apiBase,
  }) : _apiBase = apiBase ?? ApiBase();

  @override
  Future<NotificationResponse> getAllNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      
      final response = await _apiBase.request(
        path: '/community/notifications',
        method: 'GET',
        query: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  @override
  Future<NotificationResponse> getNotificationsByType({
    required String type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      
      final response = await _apiBase.request(
        path: '/community/notifications',
        method: 'GET',
        query: {
          'type': type,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch notifications by type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications by type: $e');
    }
  }

  @override
  Future<bool> markAllNotificationsAsSeen() async {
    try {
      final token = await _getToken();
      
      final response = await _apiBase.request(
        path: ApiEndpoints.markSeen,
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking notifications as seen: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }
    return token;
  }
}