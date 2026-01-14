import '../../../core/api_base.dart';
import '../models/reminder_model.dart';
import '../models/paginated_reminders_model.dart';

abstract class ReminderRemoteDataSource {
  Future<ReminderModel> addReminder({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  });

  Future<PaginatedRemindersModel> getAllReminders({int page = 1, int pageSize = 20});

  Future<ReminderModel> getReminderById(String reminderId);

  Future<ReminderModel> toggleReminderStatus(String reminderId);

  Future<ReminderModel> updateReminder({
    required String reminderId,
    String? reminderName,
    String? reminderTime,
    String? reminderDays,
    String? reminderType,
    bool? reminderEnabled,
  });

  Future<void> deleteReminder(String reminderId);
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
  Future<PaginatedRemindersModel> getAllReminders({int page = 1, int pageSize = 20}) async {
    final response = await apiBase.request(
      path: '/reminders/',
      method: 'GET',
      query: {
        'page': page,
        'page_size': pageSize,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      
      if (data is List) {
        // API returned a simple list, manual pagination handling
        final reminders = data.map((json) => ReminderModel.fromJson(json)).toList();
        final hasMore = reminders.length >= pageSize;
        
        return PaginatedRemindersModel(
          reminders: reminders,
          total: 0, // Unknown
          page: page,
          pageSize: pageSize,
          hasMore: hasMore,
        );
      } else {
        // API returned pagination object
        return PaginatedRemindersModel.fromJson(data);
      }
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
    print('=== Toggle Reminder API Request ===');
    print('Reminder ID: $reminderId');
    print('Endpoint: PUT /reminders/$reminderId/toggle');

    final response = await apiBase.request(
      path: '/reminders/$reminderId/toggle',
      method: 'PUT',
    );

    print('=== Toggle Reminder API Response ===');
    print('Status Code: ${response.statusCode}');
    print('Raw Response Data: ${response.data}');
    print('reminder_enabled value: ${response.data['data']?['reminder_enabled']}');
    print('===================================');

    if (response.statusCode == 200) {
      final model = ReminderModel.fromJson(response.data['data']);
      print('Parsed ReminderModel.reminderEnabled: ${model.reminderEnabled}');
      return model;
    } else {
      throw Exception('Failed to toggle reminder status');
    }
  }

  @override
  Future<ReminderModel> updateReminder({
    required String reminderId,
    String? reminderName,
    String? reminderTime,
    String? reminderDays,
    String? reminderType,
    bool? reminderEnabled,
  }) async {
    final requestBody = {
      if (reminderName != null) 'reminder_name': reminderName,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (reminderDays != null) 'reminder_days': reminderDays,
      if (reminderType != null) 'reminder_type': reminderType,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
    };

    print('=== Update Reminder ===');
    print('URL: /reminders/$reminderId');
    print('Method: PUT');
    print('Body: $requestBody');

    final response = await apiBase.request(
      path: '/reminders/$reminderId',
      method: 'PUT',
      body: requestBody,
    );

    if (response.statusCode == 200) {
      return ReminderModel.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to update reminder');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    print('=== Delete Reminder ===');
    print('URL: /reminders/$reminderId');
    print('Method: DELETE');

    final response = await apiBase.request(
      path: '/reminders/$reminderId',
      method: 'DELETE',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reminder');
    }
  }
}