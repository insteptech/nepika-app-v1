import 'package:dio/dio.dart';
import '../../../core/api_base.dart';
import '../../../core/utils/logger.dart';
import '../datasources/routine_remote_data_source.dart';
import '../models/routine_model.dart';

class RoutineRemoteDataSourceImpl implements RoutineRemoteDataSource {
  final ApiBase apiBase;

  RoutineRemoteDataSourceImpl({required this.apiBase});

  @override
  Future<List<RoutineModel>> getTodaysRoutine(String token, String type) async {
    try {
      String endpoint;
      switch (type) {
        case 'all':
          endpoint = '/routines/all';
          break;
        case 'get-user-routines':
          endpoint = '/routines/get-user-routine';
          break;
        default:
          endpoint = '/routines/get-user-routine';
      }

      final response = await apiBase.request(
        path: endpoint,
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Logger.network('API Response for $type: ${response.data}');
        Logger.network('Response data type: ${response.data.runtimeType}');
        
        // Handle both direct array and object with routines property
        List<dynamic> routinesData;
        try {
          if (response.data is List) {
            Logger.network('Response is direct List with ${(response.data as List).length} items');
            routinesData = response.data;
          } else if (response.data is Map<String, dynamic> && response.data['routines'] != null) {
            Logger.network('Response has routines key with ${(response.data['routines'] as List).length} items');
            routinesData = response.data['routines'];
          } else if (response.data is Map<String, dynamic>) {
            // If it's a map but no 'routines' key, try to find any list value
            final mapData = response.data as Map<String, dynamic>;
            Logger.network('Response is Map with keys: ${mapData.keys.toList()}');
            final listValue = mapData.values.firstWhere(
              (value) => value is List,
              orElse: () => <dynamic>[],
            );
            routinesData = listValue is List ? listValue : <dynamic>[];
            Logger.network('Found list value with ${routinesData.length} items');
          } else {
            Logger.network('Response is not List or Map, defaulting to empty');
            routinesData = <dynamic>[];
          }
        } catch (parseError) {
          Logger.network('Error parsing response structure', error: parseError);
          routinesData = <dynamic>[];
        }
        
        Logger.network('Final routinesData count: ${routinesData.length}');
        
        final parsedRoutines = <RoutineModel>[];
        int skippedCount = 0;
        
        for (int i = 0; i < routinesData.length; i++) {
          try {
            final routine = RoutineModel.fromJson(routinesData[i]);
            parsedRoutines.add(routine);
            Logger.network('Successfully parsed routine ${i + 1}: ${routine.name}');
          } catch (jsonError) {
            skippedCount++;
            Logger.network('Error parsing routine item $i', error: jsonError);
            Logger.network('Problematic data: ${routinesData[i]}');
          }
        }
        
        Logger.network('Parsed ${parsedRoutines.length} routines successfully, skipped $skippedCount items');
        return parsedRoutines;
      } else {
        throw Exception('Failed to fetch routines: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Routine endpoint not found.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      }
      throw Exception('Network error: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateRoutineStep(
      String token, String routineId, bool isCompleted) async {
    try {
      final response = await apiBase.request(
        path: '/routines/$routineId',
        method: 'PUT',
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {'is_completed': isCompleted},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update routine: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to update routine: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating routine: $e');
    }
  }

  @override
  Future<void> deleteRoutineStep(String token, String routineId) async {
    try {
      final response = await apiBase.request(
        path: '/routines/delete',
        method: 'DELETE',
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {'routine_id': routineId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete routine: ${response.statusCode}');
      }

    } on DioException catch (e) {
      throw Exception('Failed to delete routine: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting routine: $e');
    }
  }

  @override
  Future<void> addRoutineStep(String token, String masterRoutineId) async {
    try {
      final response = await apiBase.request(
        path: '/routines/add',
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {'master_routine_id': masterRoutineId},
      );
      Logger.network('Add routine response: ${response.statusCode}');
      if (response.statusCode != 201) {
        throw Exception('Failed to add routine: ${response.statusCode}');
      }

    } on DioException catch (e) {
      throw Exception('Failed to add routine: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error adding routine: $e');
    }
  }
}