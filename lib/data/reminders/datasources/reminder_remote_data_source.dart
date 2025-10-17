import '../../../core/api_base.dart';
import '../models/reminder_model.dart';

abstract class ReminderRemoteDataSource {
  Future<ReminderModel> addReminder({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  });

  Future<List<ReminderModel>> getAllReminders();

  Future<ReminderModel> getReminderById(String reminderId);

  Future<ReminderModel> toggleReminderStatus(String reminderId);
}

class ReminderRemoteDataSourceImpl implements ReminderRemoteDataSource {
  final ApiBase apiBase;

  ReminderRemoteDataSourceImpl(this.apiBase);

  @override
  Future<ReminderModel> addReminder({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  }) async {
    final requestBody = {
      'reminder_name': reminderName,
      'reminder_time': reminderTime,
      if (reminderDays != null) 'reminder_days': reminderDays,
      if (reminderType != null) 'reminder_type': reminderType,
      'reminder_enabled': reminderEnabled,
    };

    print('=== API Request Debug ===');
    print('URL: /reminders/add');
    print('Method: POST');
    print('Body: $requestBody');
    print('========================');

    try {
      final response = await apiBase.request(
        path: '/reminders/add',
        method: 'POST',
        body: requestBody,
      );

      print('=== API Response Debug ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('=========================');

      if (response.statusCode == 201) {
        return ReminderModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to add reminder. Status: ${response.statusCode}, Data: ${response.data}');
      }
    } catch (e) {
      print('=== API Error Debug ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('=====================');
      rethrow;
    }
  }

  @override
  Future<List<ReminderModel>> getAllReminders() async {
    final response = await apiBase.request(
      path: '/reminders/',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> remindersJson = response.data['data'];
      return remindersJson
          .map((json) => ReminderModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to get reminders');
    }
  }

  @override
  Future<ReminderModel> getReminderById(String reminderId) async {
    final response = await apiBase.request(
      path: '/reminders/$reminderId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return ReminderModel.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to get reminder');
    }
  }

  @override
  Future<ReminderModel> toggleReminderStatus(String reminderId) async {
    final response = await apiBase.request(
      path: '/reminders/$reminderId/toggle',
      method: 'PUT',
    );

    if (response.statusCode == 200) {
      return ReminderModel.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to toggle reminder status');
    }
  }
}